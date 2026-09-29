-- ============================================================================
-- 010 — Pings have no cooldown
--
-- The point of the Ping button is to be annoying. The thirty-second
-- "ping_too_soon" guard from 006 stopped exactly the behaviour the button
-- exists for: tapping it again, and again, until the target turns up.
--
-- send_ping() is redefined without the rate limit. Everything else — the
-- flag-based recipient (009), self-ping refusal, ensure_session() (008) —
-- is unchanged. Duplicate notifications on the receiving device are already
-- collapsed by ping id, so a double tap is two rows and two rings, which is
-- the intent.
--
-- Requires 009. Safe to re-run.
-- ============================================================================

BEGIN;

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

  -- No rate limit, on purpose. See the header.

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
