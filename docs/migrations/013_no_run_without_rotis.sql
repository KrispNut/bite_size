-- ============================================================================
-- 013 — The runner can't leave with nothing to buy
--
-- The app now greys out "Start the run" while the day's total_rotis is 0.
-- This makes Postgres refuse it too, so a phone still running an older build
-- can't lock an empty list. The app maps the code to "Nobody has asked for
-- any rotis yet."
--
-- Same function as 005 with one new check, placed after the idempotency
-- return so a double tap after leaving is still not an error.
--
-- Note: this applies to every pack. Both shipped packs have the units module
-- on, so that's the rule they want; a pack without units would never be able
-- to depart.
--
-- Optional (the app already blocks it). Safe to re-run.
-- ============================================================================

BEGIN;

CREATE OR REPLACE FUNCTION public.depart_for_tandoor(p_session_id TEXT)
RETURNS TIMESTAMPTZ
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_caller  UUID := public.current_app_user();
  v_session public.sessions;
  v_pending INT;
  v_now     TIMESTAMPTZ := NOW();
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  SELECT * INTO v_session FROM public.sessions WHERE id = p_session_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'session_not_found';
  END IF;
  IF COALESCE(v_session.tandoor_runner_name, '') = '' THEN
    RAISE EXCEPTION 'no_runner_assigned';
  END IF;

  -- The runner themselves, or an admin — an external runner (the office boy)
  -- has no account to tap the button with, so someone has to do it for them.
  IF v_session.tandoor_runner_id IS DISTINCT FROM v_caller
     AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'not_the_runner';
  END IF;

  -- Idempotent: a double tap on a flaky connection is not an error.
  IF v_session.runner_departed_at IS NOT NULL THEN
    RETURN v_session.runner_departed_at;
  END IF;

  IF COALESCE(v_session.total_rotis, 0) = 0 THEN
    RAISE EXCEPTION 'no_units_to_buy';
  END IF;

  SELECT COUNT(*) INTO v_pending
    FROM public.extra_orders
   WHERE session_id = p_session_id AND status = 'pending';

  IF v_pending > 0 THEN
    RAISE EXCEPTION 'orders_not_finalized:%', v_pending;
  END IF;

  UPDATE public.sessions
     SET runner_departed_at = v_now,
         updated_at         = v_now
   WHERE id = p_session_id;

  RETURN v_now;
END;
$$;

GRANT EXECUTE ON FUNCTION public.depart_for_tandoor(TEXT) TO authenticated;

COMMIT;
