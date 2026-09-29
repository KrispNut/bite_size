-- ============================================================================
-- 007 — One session per pack per day
--
-- sessions.id used to be the bare date, which meant every activity pack on a
-- device shared the same row: a cricket order landed on the lunch roster, and
-- resetting the day under one pack wiped the other. The client now keys a
-- session as `<pack_id>:<yyyy-mm-dd>` for every pack except the original
-- lunch pack, whose rows stay bare dates so nothing already stored moves.
--
-- Nothing about the schema changes. The only server-side code that ever
-- assumed the id *was* a date is ensure_session(), which cast it; it now reads
-- the date off the end of the id instead. Everything else keys by the string.
--
-- Safe to re-run.
-- ============================================================================

BEGIN;

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

  -- `ground_booking:2026-09-14` → 2026-09-14; `2026-09-14` → itself.
  v_date := regexp_replace(p_session_id, '^.*:', '')::DATE;

  INSERT INTO public.sessions (id, date, cutoff_at, status)
  VALUES (p_session_id, v_date,
          (v_date + TIME '12:30') AT TIME ZONE 'Asia/Karachi', 'open')
  ON CONFLICT (id) DO NOTHING;
END;
$$;

GRANT EXECUTE ON FUNCTION public.ensure_session(TEXT) TO authenticated;

COMMIT;
