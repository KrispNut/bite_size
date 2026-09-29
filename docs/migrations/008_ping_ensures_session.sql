-- ============================================================================
-- 008 — A ping can be the first thing that happens today
--
-- pings.session_id references sessions(id). The dashboard sends today's id
-- with every ping for context, but the session row is only created when the
-- first entry or order lands — so a ping before either of those hit the FK:
--
--   insert or update on table "pings" violates foreign key constraint
--   "pings_session_id_fkey" ... Key (session_id)=(2026-09-14) is not present
--
-- create_extra_order() already handles the same situation by calling
-- ensure_session() first. send_ping() now does the same. Requires 007, since
-- the id it ensures may be pack-prefixed.
--
-- Safe to re-run.
-- ============================================================================

BEGIN;

CREATE OR REPLACE FUNCTION public.send_ping(
  p_to_email   TEXT,
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
   WHERE lower(email) = lower(trim(p_to_email))
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

  -- THE FIX: the day's session row may not exist yet. Make it, as
  -- create_extra_order() does, so the FK below always has something to point
  -- at. A null session_id (no day context) is still allowed.
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
