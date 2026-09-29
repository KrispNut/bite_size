-- ============================================================================
-- 002 — Restrict who may assign the runner and settle the bill
--
-- `sessions` UPDATE has to stay open to all members: anyone may announce that
-- food has arrived. But assigning the tandoor runner and settling the bill are
-- admin actions, and RLS cannot express "this column but not that one".
-- A BEFORE UPDATE trigger can.
--
-- Safe to re-run.
-- ============================================================================

BEGIN;

CREATE OR REPLACE FUNCTION public.guard_session_writes()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  -- Service role / migrations / anon: same reasoning as guard_user_identity().
  -- Anon is already stopped by RLS; service role is trusted by definition.
  IF auth.uid() IS NULL THEN
    RETURN NEW;
  END IF;

  IF (NEW.tandoor_runner_id   IS DISTINCT FROM OLD.tandoor_runner_id
   OR NEW.tandoor_runner_name IS DISTINCT FROM OLD.tandoor_runner_name)
     AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'only an admin can assign the tandoor runner';
  END IF;

  IF (NEW.status          IS DISTINCT FROM OLD.status
   OR NEW.total_roti_cost IS DISTINCT FROM OLD.total_roti_cost)
     AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'only an admin can settle the bill';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_guard_session_writes ON public.sessions;
CREATE TRIGGER trg_guard_session_writes
BEFORE UPDATE ON public.sessions
FOR EACH ROW EXECUTE FUNCTION public.guard_session_writes();

COMMIT;
