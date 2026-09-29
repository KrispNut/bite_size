BEGIN;

-- Create the day's session on demand. Cutoff is 12:30 office time; pinning
-- the timezone here also fixes it having previously depended on whichever
-- device happened to open the app first.
CREATE OR REPLACE FUNCTION public.ensure_session(p_session_id TEXT)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_date DATE;
BEGIN
  IF EXISTS (SELECT 1 FROM public.sessions WHERE id = p_session_id) THEN
    RETURN;
  END IF;
  v_date := p_session_id::DATE;
  INSERT INTO public.sessions (id, date, cutoff_at, status)
  VALUES (p_session_id, v_date,
          (v_date + TIME '12:30') AT TIME ZONE 'Asia/Karachi', 'open')
  ON CONFLICT (id) DO NOTHING;
END;
$$;

GRANT EXECUTE ON FUNCTION public.ensure_session(TEXT) TO authenticated;

-- Same function as migration 003, with the session guard added.
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

  -- THE FIX: a shared meal can be the first thing logged today.
  PERFORM public.ensure_session(p_session_id);

  INSERT INTO public.extra_orders (
    session_id, description, cost, cost_minor,
    paid_by_id, paid_by_name, shared_by_ids, split_mode, created_by
  )
  VALUES (
    p_session_id, p_description, p_cost_minor / 100.0, p_cost_minor, p_paid_by,
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
  SELECT v_order_id, r.uid,
         COALESCE((SELECT name FROM public.users u WHERE u.id = r.uid), 'Coworker'),
         r.weight,
         r.base_minor + CASE WHEN r.rn <= r.leftover THEN 1 ELSE 0 END
    FROM ranked r;

  RETURN v_order_id;
END;
$$;

GRANT EXECUTE ON FUNCTION
  public.create_extra_order(TEXT, TEXT, BIGINT, UUID, UUID[], INT[]) TO authenticated;

COMMIT;
