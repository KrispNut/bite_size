-- ============================================================================
-- 003 — Shared side orders
--
-- Two people ordering a karahi between themselves is a different thing from
-- the whole office splitting the rotis. `extra_orders.shared_by_ids` could
-- almost express it, but nothing stored what each person actually owed — the
-- amount was recomputed at settle time with per-person rounding, so the shares
-- never summed back to the bill.
--
-- This adds a child table holding the RESOLVED amount per person in paisa,
-- allocated by largest-remainder inside Postgres so the split is exact and
-- correct no matter which client wrote it.
--
-- Safe to re-run.
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. EXTRA ORDERS — money in paisa, plus who created it and how it splits
-- ---------------------------------------------------------------------------
ALTER TABLE public.extra_orders
  ADD COLUMN IF NOT EXISTS cost_minor  BIGINT,
  ADD COLUMN IF NOT EXISTS split_mode  TEXT NOT NULL DEFAULT 'equal',
  ADD COLUMN IF NOT EXISTS created_by  UUID REFERENCES public.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS created_at_tz TIMESTAMPTZ NOT NULL DEFAULT NOW();

DO $$ BEGIN
  ALTER TABLE public.extra_orders
    ADD CONSTRAINT extra_orders_split_mode_check
    CHECK (split_mode IN ('equal', 'shares'));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

UPDATE public.extra_orders
   SET cost_minor = ROUND(cost * 100)::BIGINT
 WHERE cost_minor IS NULL;

-- Superseded by extra_order_shares, which stores amounts as well as members.
-- Kept (nullable) so nothing that still reads it breaks mid-migration.
ALTER TABLE public.extra_orders ALTER COLUMN shared_by_ids DROP NOT NULL;

-- ---------------------------------------------------------------------------
-- 2. THE SHARES
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.extra_order_shares (
  order_id     UUID NOT NULL REFERENCES public.extra_orders(id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  user_name    TEXT NOT NULL DEFAULT '',
  weight       INT  NOT NULL DEFAULT 1 CHECK (weight > 0),
  amount_minor BIGINT NOT NULL CHECK (amount_minor >= 0),
  PRIMARY KEY (order_id, user_id)
);

CREATE INDEX IF NOT EXISTS extra_order_shares_user_idx
  ON public.extra_order_shares (user_id);

-- ---------------------------------------------------------------------------
-- 3. create_extra_order() — allocation lives here, not in the client
--
-- Largest-remainder: give everyone the integer part of their weighted share,
-- then hand the leftover paisa one at a time to whoever was rounded down
-- hardest. Guarantees SUM(amount_minor) = cost_minor exactly.
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

  INSERT INTO public.extra_orders (
    session_id, description, cost, cost_minor,
    paid_by_id, paid_by_name, shared_by_ids, split_mode, created_by
  )
  VALUES (
    p_session_id,
    p_description,
    p_cost_minor / 100.0,
    p_cost_minor,
    p_paid_by,
    COALESCE((SELECT name FROM public.users WHERE id = p_paid_by), 'Someone'),
    p_participants,
    CASE WHEN p_weights IS NULL THEN 'equal' ELSE 'shares' END,
    v_caller
  )
  RETURNING id INTO v_order_id;

  WITH parts AS (
    SELECT p.uid, p.ord, COALESCE(w.weight, 1) AS weight
      FROM unnest(p_participants) WITH ORDINALITY AS p(uid, ord)
      LEFT JOIN unnest(COALESCE(p_weights, ARRAY[]::INT[])) WITH ORDINALITY AS w(weight, ord)
        ON w.ord = p.ord
  ),
  tot AS (SELECT SUM(weight)::BIGINT AS total FROM parts),
  base AS (
    SELECT parts.uid, parts.ord, parts.weight,
           (p_cost_minor * parts.weight) / tot.total AS base_minor,
           (p_cost_minor * parts.weight) % tot.total AS rem
      FROM parts, tot
  ),
  ranked AS (
    SELECT b.*,
           ROW_NUMBER() OVER (ORDER BY b.rem DESC, b.ord) AS rn,
           p_cost_minor - SUM(b.base_minor) OVER () AS leftover
      FROM base b
  )
  INSERT INTO public.extra_order_shares (order_id, user_id, user_name, weight, amount_minor)
  SELECT v_order_id,
         r.uid,
         COALESCE((SELECT name FROM public.users u WHERE u.id = r.uid), 'Coworker'),
         r.weight,
         r.base_minor + CASE WHEN r.rn <= r.leftover THEN 1 ELSE 0 END
    FROM ranked r;

  RETURN v_order_id;
END;
$$;

GRANT EXECUTE ON FUNCTION
  public.create_extra_order(TEXT, TEXT, BIGINT, UUID, UUID[], INT[]) TO authenticated;

-- ---------------------------------------------------------------------------
-- 4. RLS
-- ---------------------------------------------------------------------------
ALTER TABLE public.extra_order_shares ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS extra_order_shares_select ON public.extra_order_shares;
CREATE POLICY extra_order_shares_select ON public.extra_order_shares
  FOR SELECT TO authenticated USING (TRUE);

-- Shares are only ever written through create_extra_order(); direct inserts
-- would let a client invent an allocation that doesn't sum to the bill.
DROP POLICY IF EXISTS extra_order_shares_admin_write ON public.extra_order_shares;
CREATE POLICY extra_order_shares_admin_write ON public.extra_order_shares
  FOR ALL TO authenticated
  USING (public.is_admin()) WITH CHECK (public.is_admin());

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.extra_orders;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

COMMIT;
