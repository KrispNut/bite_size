-- ============================================================================
-- 009 — The ping target lives in the database, not in the build
--
-- PING_TARGET_EMAIL was read from .env, which ships as a bundled Flutter
-- asset. Moving the ping to a different person therefore meant editing .env,
-- rebuilding, and reinstalling on every phone — and until every phone was
-- updated, half the roster would be pinging the old person and the new target
-- would still see a Ping button aimed at themselves.
--
-- It is now a flag on the person: exactly one row may carry is_ping_target,
-- enforced by a partial unique index rather than by hope. send_ping() resolves
-- the recipient from that flag, so the client no longer says who to ping — it
-- cannot get it wrong, and it cannot be talked into pinging someone else.
--
-- Admin is unchanged and always was database-driven: public.users.role, read
-- through is_admin(). There can be as many admins as you like; ADMIN_EMAIL in
-- .env was only ever a bootstrap seed and nothing at runtime reads it.
--
-- Requires 006 and 008. Safe to re-run.
-- ============================================================================

BEGIN;

-- 1. The flag ------------------------------------------------------------

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS is_ping_target BOOLEAN NOT NULL DEFAULT FALSE;

-- At most one target. A partial unique index over the true values is what
-- makes "the ONE person" a rule the database keeps, instead of a comment.
-- Moving the target is therefore two statements, not one: clear, then set.
CREATE UNIQUE INDEX IF NOT EXISTS users_one_ping_target
  ON public.users ((is_ping_target))
  WHERE is_ping_target;

-- 2. Only an admin moves it ----------------------------------------------
--
-- users_update lets a person write their own row, so without this any member
-- could quietly point the ping at themselves.

CREATE OR REPLACE FUNCTION public.guard_user_identity()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  -- No auth.uid() means this is not a user-initiated write: either the
  -- service role (migrations, SQL editor, server jobs — already trusted and
  -- RLS-exempt) or anon (which has no UPDATE policy on this table at all, so
  -- RLS rejects it long before this trigger runs). Either way there is no
  -- privilege here to escalate.
  IF auth.uid() IS NULL THEN
    RETURN NEW;
  END IF;

  IF NEW.role IS DISTINCT FROM OLD.role AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'only an admin can change roles';
  END IF;

  IF NEW.is_ping_target IS DISTINCT FROM OLD.is_ping_target
     AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'only an admin can move the ping target';
  END IF;

  -- NULL -> value is the one-time claim. Anything else is tampering.
  IF NEW.auth_uid IS DISTINCT FROM OLD.auth_uid
     AND OLD.auth_uid IS NOT NULL
     AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'auth binding is not user-editable';
  END IF;
  RETURN NEW;
END;
$$;

-- 3. The server picks the recipient ---------------------------------------
--
-- p_to_email stays in the signature for older builds still in someone's
-- pocket, but it is now ignored in favour of the flag: two clients on two
-- versions must never disagree about who gets pinged.

CREATE OR REPLACE FUNCTION public.send_ping(
  p_to_email   TEXT DEFAULT NULL,
  p_message    TEXT DEFAULT '',
  p_session_id TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_caller    UUID := public.current_app_user();
  v_to        UUID;
  v_from_name TEXT;
  v_id        UUID;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  SELECT id INTO v_to
    FROM public.users
   WHERE is_ping_target
     AND is_active
   LIMIT 1;

  IF v_to IS NULL THEN
    RAISE EXCEPTION 'ping_target_unknown';
  END IF;
  IF v_to = v_caller THEN
    RAISE EXCEPTION 'cannot_ping_self';
  END IF;

  -- One ping per sender per target per thirty seconds.
  IF EXISTS (
    SELECT 1 FROM public.pings
     WHERE from_id = v_caller
       AND to_id = v_to
       AND created_at > NOW() - INTERVAL '30 seconds'
  ) THEN
    RAISE EXCEPTION 'ping_too_soon';
  END IF;

  -- The day's session row may not exist yet; a ping can be the first thing
  -- that happens today. See 008.
  IF p_session_id IS NOT NULL THEN
    PERFORM public.ensure_session(p_session_id);
  END IF;

  SELECT name INTO v_from_name FROM public.users WHERE id = v_caller;

  INSERT INTO public.pings (session_id, from_id, from_name, to_id, message)
  VALUES (
    p_session_id,
    v_caller,
    COALESCE(v_from_name, 'Someone'),
    v_to,
    COALESCE(p_message, '')
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.send_ping(TEXT, TEXT, TEXT) TO authenticated;

COMMIT;

-- ============================================================================
-- After running this, pick the target (nobody is one by default). Two
-- statements, because the unique index will reject a second true:
--
--   UPDATE public.users SET is_ping_target = FALSE WHERE is_ping_target;
--   UPDATE public.users SET is_ping_target = TRUE
--    WHERE lower(email) = 'someone@example.com';
--
-- And admins, of which there may be any number:
--
--   UPDATE public.users SET role = 'admin'
--    WHERE lower(email) IN ('one@example.com', 'two@example.com');
-- ============================================================================
