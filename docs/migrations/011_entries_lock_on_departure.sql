-- ============================================================================
-- 011 — The roster locks when the runner leaves, and only then
--
-- The 12:30 cutoff was only ever enforced by the client, which greyed out
-- "Add my entry" on the clock. That is gone: the cutoff is now the time
-- everyone aims for, not a lock. The one moment the roster genuinely must
-- freeze is when the runner has walked out to buy — an entry added after
-- that is food nobody is fetching.
--
-- extra_orders already have exactly this guard (005, guard_extra_order_lock).
-- entries never did, so until now a member could still add or edit a roster
-- row after departure. This mirrors 005 on entries: once
-- sessions.runner_departed_at is set, member writes raise
-- runner_already_left. Admins are exempt, as they are on extra_orders, so a
-- correction is still possible.
--
-- Requires 005. Safe to re-run.
-- ============================================================================

BEGIN;

CREATE OR REPLACE FUNCTION public.guard_entry_lock()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_session TEXT;
BEGIN
  -- Service role / migrations: same reasoning as guard_session_writes().
  IF auth.uid() IS NULL THEN
    IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
  END IF;

  IF TG_OP = 'DELETE' THEN
    v_session := OLD.session_id;
  ELSE
    v_session := NEW.session_id;
  END IF;

  IF EXISTS (SELECT 1 FROM public.sessions
              WHERE id = v_session AND runner_departed_at IS NOT NULL)
     AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'runner_already_left';
  END IF;

  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
END;
$$;

DROP TRIGGER IF EXISTS trg_guard_entry_lock ON public.entries;
CREATE TRIGGER trg_guard_entry_lock
BEFORE INSERT OR UPDATE OR DELETE ON public.entries
FOR EACH ROW EXECUTE FUNCTION public.guard_entry_lock();

COMMIT;
