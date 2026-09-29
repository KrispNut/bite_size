-- ============================================================================
-- 005 — A shared meal is an invitation, not an assignment
--
-- Every share now starts `pending` and carries zero. Accepting opts you into
-- the split; declining drops you out and the cost re-allocates across whoever
-- is left. The order itself is `pending` while anyone still owes an answer.
--
-- That pending state is the gate on the tandoor run: depart_for_tandoor()
-- refuses while any order is unresolved, and once the runner has left the
-- day's orders are frozen.
--
-- Safe to re-run. Existing rows are grandfathered in as already-accepted.
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. ORDER LIFECYCLE
--
-- `updated_at` is not decoration: watchExtraOrders streams this table and
-- fetches the child shares on every event. A response only changes a share
-- row, which would not wake that stream — so allocation always touches this
-- column, and every accept/decline reaches every device.
-- ---------------------------------------------------------------------------
ALTER TABLE public.extra_orders
  ADD COLUMN IF NOT EXISTS status       TEXT NOT NULL DEFAULT 'confirmed',
  ADD COLUMN IF NOT EXISTS confirmed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW();

DO $$ BEGIN
  ALTER TABLE public.extra_orders
    ADD CONSTRAINT extra_orders_status_check
    CHECK (status IN ('pending', 'confirmed', 'cancelled'));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

UPDATE public.extra_orders
   SET confirmed_at = created_at
 WHERE status = 'confirmed' AND confirmed_at IS NULL;

CREATE INDEX IF NOT EXISTS extra_orders_pending_idx
  ON public.extra_orders (session_id) WHERE status = 'pending';

-- ---------------------------------------------------------------------------
-- 2. PER-PERSON INVITATION STATE
--
-- Defaulting to 'accepted' grandfathers existing rows: everything written
-- before this migration was already an unconditional charge.
-- ---------------------------------------------------------------------------
ALTER TABLE public.extra_order_shares
  ADD COLUMN IF NOT EXISTS status       TEXT NOT NULL DEFAULT 'accepted',
  ADD COLUMN IF NOT EXISTS responded_at TIMESTAMPTZ;

DO $$ BEGIN
  ALTER TABLE public.extra_order_shares
    ADD CONSTRAINT extra_order_shares_status_check
    CHECK (status IN ('pending', 'accepted', 'declined'));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS extra_order_shares_pending_idx
  ON public.extra_order_shares (user_id) WHERE status = 'pending';

-- ---------------------------------------------------------------------------
-- 3. RUNNER DEPARTURE
--
-- Assigning a runner and the runner actually walking out are two different
-- moments; only the second one closes the list.
-- ---------------------------------------------------------------------------
ALTER TABLE public.sessions
  ADD COLUMN IF NOT EXISTS runner_departed_at TIMESTAMPTZ;

-- ---------------------------------------------------------------------------
-- 4. allocate_extra_order_shares() — re-run the split over the accepted set
--
-- Same largest-remainder allocation as migration 003, but driven by the share
-- rows rather than a participant array, because membership now changes after
-- the order is created. Anyone not accepted is zeroed rather than deleted:
-- the order still needs to show that they were asked.
--
-- Leftover-paisa ties break on user_id, which is stable, so re-running this
-- over an unchanged set is idempotent.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.allocate_extra_order_shares(p_order_id UUID)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_cost     BIGINT;
  v_accepted INT;
  v_pending  INT;
  v_status   TEXT;
BEGIN
  SELECT cost_minor INTO v_cost FROM public.extra_orders WHERE id = p_order_id;
  IF v_cost IS NULL THEN
    RETURN;
  END IF;

  SELECT COUNT(*) FILTER (WHERE status = 'accepted'),
         COUNT(*) FILTER (WHERE status = 'pending')
    INTO v_accepted, v_pending
    FROM public.extra_order_shares
   WHERE order_id = p_order_id;

  -- Not accepted yet, or declined outright: you carry nothing.
  UPDATE public.extra_order_shares
     SET amount_minor = 0
   WHERE order_id = p_order_id AND status <> 'accepted';

  IF v_accepted > 0 THEN
    WITH parts AS (
      SELECT s.user_id, s.weight,
             ROW_NUMBER() OVER (ORDER BY s.user_id) AS ord
        FROM public.extra_order_shares s
       WHERE s.order_id = p_order_id AND s.status = 'accepted'
    ),
    tot AS (SELECT SUM(weight)::BIGINT AS total FROM parts),
    base AS (
      SELECT p.user_id, p.ord,
             (v_cost * p.weight) / t.total AS base_minor,
             (v_cost * p.weight) % t.total AS rem
        FROM parts p, tot t
    ),
    ranked AS (
      SELECT b.*,
             ROW_NUMBER() OVER (ORDER BY b.rem DESC, b.ord) AS rn,
             v_cost - SUM(b.base_minor) OVER () AS leftover
        FROM base b
    )
    UPDATE public.extra_order_shares s
       SET amount_minor = r.base_minor
                        + CASE WHEN r.rn <= r.leftover THEN 1 ELSE 0 END
      FROM ranked r
     WHERE s.order_id = p_order_id AND s.user_id = r.user_id;
  END IF;

  v_status := CASE
                WHEN v_pending > 0  THEN 'pending'
                WHEN v_accepted = 0 THEN 'cancelled'
                ELSE 'confirmed'
              END;

  UPDATE public.extra_orders
     SET status       = v_status,
         confirmed_at = CASE WHEN v_status = 'confirmed'
                             THEN COALESCE(confirmed_at, NOW())
                             ELSE NULL END,
         -- Always touched, even when nothing else moved — see note above.
         updated_at   = NOW()
   WHERE id = p_order_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.allocate_extra_order_shares(UUID) TO authenticated;

-- ---------------------------------------------------------------------------
-- 5. create_extra_order() — supersedes migration 004
--
-- Difference from 004: shares are written `pending` at zero and allocation is
-- delegated to allocate_extra_order_shares(), so creation and every later
-- response go through exactly one implementation of the split.
--
-- The payer and the creator are auto-accepted. The payer's money is already
-- spent, and someone has to be in the order for it to mean anything.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_extra_order(
  p_session_id   TEXT,
  p_description  TEXT,
  p_cost_minor   BIGINT,
  p_paid_by      UUID,
  p_participants UUID[],
  p_weights      INT[] DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_caller   UUID := public.current_app_user();
  v_order_id UUID;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;
  IF p_cost_minor IS NULL OR p_cost_minor <= 0 THEN
    RAISE EXCEPTION 'cost must be greater than zero';
  END IF;
  IF p_participants IS NULL OR array_length(p_participants, 1) IS NULL THEN
    RAISE EXCEPTION 'an order needs at least one person sharing it';
  END IF;
  IF p_weights IS NOT NULL
     AND array_length(p_weights, 1) IS DISTINCT FROM array_length(p_participants, 1) THEN
    RAISE EXCEPTION 'weights must line up with participants';
  END IF;
  IF EXISTS (SELECT 1 FROM unnest(COALESCE(p_weights, ARRAY[1])) w WHERE w <= 0) THEN
    RAISE EXCEPTION 'every share must be at least 1';
  END IF;

  PERFORM public.ensure_session(p_session_id);

  -- Nothing joins the list the runner is already out buying.
  IF EXISTS (SELECT 1 FROM public.sessions
              WHERE id = p_session_id AND runner_departed_at IS NOT NULL) THEN
    RAISE EXCEPTION 'runner_already_left';
  END IF;

  INSERT INTO public.extra_orders (
    session_id, description, cost, cost_minor,
    paid_by_id, paid_by_name, shared_by_ids, split_mode, created_by, status
  )
  VALUES (
    p_session_id, p_description, p_cost_minor / 100.0, p_cost_minor, p_paid_by,
    COALESCE((SELECT name FROM public.users WHERE id = p_paid_by), 'Someone'),
    p_participants,
    CASE WHEN p_weights IS NULL THEN 'equal' ELSE 'shares' END,
    v_caller,
    'pending'
  )
  RETURNING id INTO v_order_id;

  -- ON CONFLICT covers a participant list that names the same person twice.
  INSERT INTO public.extra_order_shares (
    order_id, user_id, user_name, weight, amount_minor, status, responded_at
  )
  SELECT v_order_id,
         p.uid,
         COALESCE((SELECT name FROM public.users u WHERE u.id = p.uid), 'Coworker'),
         COALESCE(w.weight, 1),
         0,
         CASE WHEN p.uid IN (v_caller, p_paid_by) THEN 'accepted' ELSE 'pending' END,
         CASE WHEN p.uid IN (v_caller, p_paid_by) THEN NOW() ELSE NULL END
    FROM unnest(p_participants) WITH ORDINALITY AS p(uid, ord)
    LEFT JOIN unnest(COALESCE(p_weights, ARRAY[]::INT[])) WITH ORDINALITY AS w(weight, ord)
      ON w.ord = p.ord
  ON CONFLICT (order_id, user_id) DO NOTHING;

  PERFORM public.allocate_extra_order_shares(v_order_id);

  RETURN v_order_id;
END;
$$;

GRANT EXECUTE ON FUNCTION
  public.create_extra_order(TEXT, TEXT, BIGINT, UUID, UUID[], INT[]) TO authenticated;

-- ---------------------------------------------------------------------------
-- 6. respond_to_extra_order() — the only way a share's status ever moves
--
-- SECURITY DEFINER, but it answers strictly on behalf of current_app_user():
-- passing an order id you were not invited to does nothing but raise.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.respond_to_extra_order(
  p_order_id UUID,
  p_accept   BOOLEAN
)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_caller  UUID := public.current_app_user();
  v_order   public.extra_orders;
  v_session public.sessions;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  SELECT * INTO v_order FROM public.extra_orders WHERE id = p_order_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'order_not_found';
  END IF;

  -- The payer bought the thing. They do not get to walk away from the bill.
  IF v_order.paid_by_id = v_caller AND NOT p_accept THEN
    RAISE EXCEPTION 'payer_cannot_decline';
  END IF;

  SELECT * INTO v_session FROM public.sessions WHERE id = v_order.session_id;
  IF FOUND THEN
    IF v_session.runner_departed_at IS NOT NULL THEN
      RAISE EXCEPTION 'runner_already_left';
    END IF;
    IF v_session.status = 'settled' THEN
      RAISE EXCEPTION 'session_already_settled';
    END IF;
  END IF;

  UPDATE public.extra_order_shares
     SET status       = CASE WHEN p_accept THEN 'accepted' ELSE 'declined' END,
         responded_at = NOW()
   WHERE order_id = p_order_id AND user_id = v_caller;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_invited';
  END IF;

  PERFORM public.allocate_extra_order_shares(p_order_id);
END;
$$;

GRANT EXECUTE ON FUNCTION public.respond_to_extra_order(UUID, BOOLEAN) TO authenticated;

-- ---------------------------------------------------------------------------
-- 7. depart_for_tandoor() — the gate
--
-- The runner is carrying everybody's order. Leaving on a list half the office
-- has not confirmed is how you come back with the wrong food and an argument
-- about who pays for it, so this refuses rather than warns.
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- 8. Freeze the list once the runner is gone
--
-- RLS still lets the payer delete their own order. That has to stop the moment
-- someone is standing at the tandoor buying it. Admins keep the override for
-- the inevitable "he actually came back without it" correction.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.guard_extra_order_lock()
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

DROP TRIGGER IF EXISTS trg_guard_extra_order_lock ON public.extra_orders;
CREATE TRIGGER trg_guard_extra_order_lock
BEFORE UPDATE OR DELETE ON public.extra_orders
FOR EACH ROW EXECUTE FUNCTION public.guard_extra_order_lock();

COMMIT;
