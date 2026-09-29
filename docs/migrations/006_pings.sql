-- ============================================================================
-- 006 — Ping one person
--
-- The dashboard carries a button that reaches exactly one member: whoever the
-- deployment names by email in PING_TARGET_EMAIL. Tapping it writes a row
-- here; that person's device sees the realtime insert and raises a local
-- notification, the same path invites already use.
--
-- The client never picks the recipient — send_ping() resolves the email to a
-- users row server-side, so a client can't address anyone the config didn't
-- name, can't ping itself, and can't hammer the same person twice in thirty
-- seconds. Direct inserts are blocked; the RPC is the only door.
--
-- Safe to re-run.
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. THE TABLE
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.pings (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id TEXT REFERENCES public.sessions(id) ON DELETE SET NULL,
  from_id    UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  from_name  TEXT NOT NULL DEFAULT '',
  to_id      UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  message    TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS pings_to_idx
  ON public.pings (to_id, created_at DESC);

-- ---------------------------------------------------------------------------
-- 2. RLS — you see pings you sent or received; nobody inserts directly
-- ---------------------------------------------------------------------------
ALTER TABLE public.pings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS pings_read_own ON public.pings;
CREATE POLICY pings_read_own ON public.pings
  FOR SELECT TO authenticated
  USING (
    to_id = public.current_app_user()
    OR from_id = public.current_app_user()
  );

-- No INSERT/UPDATE/DELETE policies on purpose: writes go through send_ping().

-- ---------------------------------------------------------------------------
-- 3. send_ping() — resolves the target by email, on behalf of the caller
-- ---------------------------------------------------------------------------
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

  -- One ping per sender per target per thirty seconds. A tap that lands twice
  -- should not become two notifications.
  IF EXISTS (
    SELECT 1 FROM public.pings
     WHERE from_id = v_caller
       AND to_id = v_to
       AND created_at > NOW() - INTERVAL '30 seconds'
  ) THEN
    RAISE EXCEPTION 'ping_too_soon';
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

-- ---------------------------------------------------------------------------
-- 4. REALTIME — the recipient's device is listening for its own rows
-- ---------------------------------------------------------------------------
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.pings;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

COMMIT;
