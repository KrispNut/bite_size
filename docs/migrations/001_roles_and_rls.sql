-- ============================================================================
-- 001 — Role-based identity + Row Level Security
--
-- Turns Bite Size from "anyone who logs in gets an account" into a closed
-- allowlist: you seed people by email, they prove ownership of that email via
-- Google Sign-In, and Postgres — not the Flutter client — decides what each
-- role may write.
--
-- Safe to re-run.
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. ROLES
-- ---------------------------------------------------------------------------
DO $$ BEGIN
  CREATE TYPE public.user_role AS ENUM ('admin', 'member');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ---------------------------------------------------------------------------
-- 2. USERS — decouple the app-side id from the Auth UID
--
-- Seeded people exist before they have ever logged in, so they need a stable
-- id of their own. `auth_uid` is filled on first successful sign-in. Existing
-- rows were keyed BY the Auth UID, so backfilling auth_uid := id preserves
-- every foreign key already pointing at users.id.
-- ---------------------------------------------------------------------------
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS auth_uid UUID,
  ADD COLUMN IF NOT EXISTS role public.user_role NOT NULL DEFAULT 'member';

ALTER TABLE public.users ALTER COLUMN id SET DEFAULT gen_random_uuid();
ALTER TABLE public.users ALTER COLUMN email DROP NOT NULL;

UPDATE public.users SET auth_uid = id WHERE auth_uid IS NULL;

-- Allowlist lookups are case-insensitive; blank emails become NULL so they
-- never collide in the unique index below.
UPDATE public.users SET email = NULLIF(lower(trim(email)), '');

-- NOTE: if this index fails, two rows share an email — merge them by hand
-- first. It cannot be resolved automatically without guessing which is real.
CREATE UNIQUE INDEX IF NOT EXISTS users_auth_uid_key
  ON public.users (auth_uid) WHERE auth_uid IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS users_email_key
  ON public.users (lower(email)) WHERE email IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 3. IDENTITY HELPERS
--
-- SECURITY DEFINER is required: these are called from inside RLS policies on
-- public.users itself, and a plain function selecting from that table would
-- recurse into the very policy that called it.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.current_app_user()
RETURNS UUID
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT id FROM public.users WHERE auth_uid = auth.uid() LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT role = 'admin' FROM public.users WHERE auth_uid = auth.uid() LIMIT 1),
    FALSE
  );
$$;

GRANT EXECUTE ON FUNCTION public.current_app_user() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

-- ---------------------------------------------------------------------------
-- 4. claim_identity() — the allowlist gate
--
-- Called once per sign-in. Binds the verified Google account to its seeded
-- row, or refuses. The email comes from the JWT, never from the client, so a
-- caller cannot claim someone else's row by lying about who they are.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.claim_identity(
  p_name      TEXT DEFAULT NULL,
  p_photo_url TEXT DEFAULT NULL
)
RETURNS public.users
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_uid   UUID := auth.uid();
  v_email TEXT := lower(trim(COALESCE(auth.jwt() ->> 'email', '')));
  v_row   public.users;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;
  IF v_email = '' THEN
    RAISE EXCEPTION 'no_email_on_token';
  END IF;

  -- Returning user: refresh the profile bits Google gave us and hand back.
  -- Returning user: preserve existing custom photo_url & name in public.users,
  -- and only fall back to p_photo_url if photo_url is NULL or empty.
  SELECT * INTO v_row FROM public.users WHERE auth_uid = v_uid;
  IF FOUND THEN
    IF NOT v_row.is_active THEN
      RAISE EXCEPTION 'account_disabled';
    END IF;
    UPDATE public.users
       SET name      = COALESCE(NULLIF(trim(name), ''), NULLIF(trim(p_name), '')),
           photo_url = COALESCE(NULLIF(trim(photo_url), ''), NULLIF(trim(p_photo_url), ''))
     WHERE id = v_row.id
     RETURNING * INTO v_row;
    RETURN v_row;
  END IF;

  -- First sign-in: the email must already be seeded.
  SELECT * INTO v_row FROM public.users WHERE lower(email) = v_email;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_allowlisted';
  END IF;
  IF v_row.auth_uid IS NOT NULL AND v_row.auth_uid <> v_uid THEN
    RAISE EXCEPTION 'email_already_claimed';
  END IF;
  IF NOT v_row.is_active THEN
    RAISE EXCEPTION 'account_disabled';
  END IF;

  UPDATE public.users
     SET auth_uid  = v_uid,
         name      = COALESCE(NULLIF(trim(name), ''), NULLIF(trim(p_name), ''),
                              split_part(v_email, '@', 1)),
         photo_url = COALESCE(NULLIF(trim(photo_url), ''), NULLIF(trim(p_photo_url), ''))
   WHERE id = v_row.id
   RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

GRANT EXECUTE ON FUNCTION public.claim_identity(TEXT, TEXT) TO authenticated;

-- ---------------------------------------------------------------------------
-- 5. Nobody promotes themselves
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.guard_user_identity()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  -- No auth.uid() means this is not a user-initiated write: either the
  -- service role (migrations, SQL editor, server jobs — already trusted and
  -- RLS-exempt) or anon (which has no UPDATE policy on this table at all, so
  -- RLS rejects it long before this trigger runs). Either way there is no
  -- privilege here to escalate.
  IF auth.uid() IS NULL THEN
    RETURN NEW;
  END IF;

  IF NEW.role IS DISTINCT FROM OLD.role AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'only an admin can change roles';
  END IF;
  -- NULL -> value is the one-time claim. Anything else is tampering.
  IF NEW.auth_uid IS DISTINCT FROM OLD.auth_uid
     AND OLD.auth_uid IS NOT NULL
     AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'auth binding is not user-editable';
  END IF;
  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------------
-- 6. ROW LEVEL SECURITY
--
-- Until now these tables had no policies at all — the anon key shipped in the
-- APK was enough to read or delete anything.
-- ---------------------------------------------------------------------------
ALTER TABLE public.users        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.entries      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.extra_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- users: the roster is shared reading; writing is yourself or an admin.
DROP POLICY IF EXISTS users_select ON public.users;
CREATE POLICY users_select ON public.users
  FOR SELECT TO authenticated USING (TRUE);

DROP POLICY IF EXISTS users_update ON public.users;
CREATE POLICY users_update ON public.users
  FOR UPDATE TO authenticated
  USING (id = public.current_app_user() OR public.is_admin())
  WITH CHECK (id = public.current_app_user() OR public.is_admin());

DROP POLICY IF EXISTS users_insert ON public.users;
CREATE POLICY users_insert ON public.users
  FOR INSERT TO authenticated WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS users_delete ON public.users;
CREATE POLICY users_delete ON public.users
  FOR DELETE TO authenticated USING (public.is_admin());

-- sessions: everyone reads and may open/advance today; only admin deletes.
DROP POLICY IF EXISTS sessions_select ON public.sessions;
CREATE POLICY sessions_select ON public.sessions
  FOR SELECT TO authenticated USING (TRUE);

DROP POLICY IF EXISTS sessions_insert ON public.sessions;
CREATE POLICY sessions_insert ON public.sessions
  FOR INSERT TO authenticated WITH CHECK (TRUE);

DROP POLICY IF EXISTS sessions_update ON public.sessions;
CREATE POLICY sessions_update ON public.sessions
  FOR UPDATE TO authenticated USING (TRUE) WITH CHECK (TRUE);

DROP POLICY IF EXISTS sessions_delete ON public.sessions;
CREATE POLICY sessions_delete ON public.sessions
  FOR DELETE TO authenticated USING (public.is_admin());

-- entries: your own row, or an admin's correction.
DROP POLICY IF EXISTS entries_select ON public.entries;
CREATE POLICY entries_select ON public.entries
  FOR SELECT TO authenticated USING (TRUE);

DROP POLICY IF EXISTS entries_insert ON public.entries;
CREATE POLICY entries_insert ON public.entries
  FOR INSERT TO authenticated
  WITH CHECK (user_id = public.current_app_user() OR public.is_admin());

DROP POLICY IF EXISTS entries_update ON public.entries;
CREATE POLICY entries_update ON public.entries
  FOR UPDATE TO authenticated
  USING (user_id = public.current_app_user() OR public.is_admin())
  WITH CHECK (user_id = public.current_app_user() OR public.is_admin());

DROP POLICY IF EXISTS entries_delete ON public.entries;
CREATE POLICY entries_delete ON public.entries
  FOR DELETE TO authenticated
  USING (user_id = public.current_app_user() OR public.is_admin());

-- extra_orders: anyone may log one; the payer or an admin may change it.
DROP POLICY IF EXISTS extra_orders_select ON public.extra_orders;
CREATE POLICY extra_orders_select ON public.extra_orders
  FOR SELECT TO authenticated USING (TRUE);

DROP POLICY IF EXISTS extra_orders_insert ON public.extra_orders;
CREATE POLICY extra_orders_insert ON public.extra_orders
  FOR INSERT TO authenticated WITH CHECK (TRUE);

DROP POLICY IF EXISTS extra_orders_write ON public.extra_orders;
CREATE POLICY extra_orders_write ON public.extra_orders
  FOR UPDATE TO authenticated
  USING (paid_by_id = public.current_app_user() OR public.is_admin())
  WITH CHECK (paid_by_id = public.current_app_user() OR public.is_admin());

DROP POLICY IF EXISTS extra_orders_delete ON public.extra_orders;
CREATE POLICY extra_orders_delete ON public.extra_orders
  FOR DELETE TO authenticated
  USING (paid_by_id = public.current_app_user() OR public.is_admin());

-- transactions: everyone sees the money, only an admin moves it.
DROP POLICY IF EXISTS transactions_select ON public.transactions;
CREATE POLICY transactions_select ON public.transactions
  FOR SELECT TO authenticated USING (TRUE);

DROP POLICY IF EXISTS transactions_insert ON public.transactions;
CREATE POLICY transactions_insert ON public.transactions
  FOR INSERT TO authenticated WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS transactions_update ON public.transactions;
CREATE POLICY transactions_update ON public.transactions
  FOR UPDATE TO authenticated
  USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS transactions_delete ON public.transactions;
CREATE POLICY transactions_delete ON public.transactions
  FOR DELETE TO authenticated USING (public.is_admin());

-- ---------------------------------------------------------------------------
-- 7. SEED THE ALLOWLIST
--
-- The three accounts already in the database. Existing rows keep their own
-- name and photo — only role and is_active are re-asserted here, so editing
-- names in the Supabase table editor is safe across re-runs.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  seed RECORD;
BEGIN
  FOR seed IN
    SELECT * FROM (VALUES
      ('S FW',        'suitableforwork1@gmail.com', 'admin'),
      ('Sickmojas F', 'sickmojasf@gmail.com',       'member'),
      ('sick me',     'mesick174@gmail.com',        'member')
    ) AS t(name, email, role)
  LOOP
    IF EXISTS (SELECT 1 FROM public.users u WHERE lower(u.email) = lower(seed.email)) THEN
      UPDATE public.users
         SET role = seed.role::public.user_role,
             is_active = TRUE
       WHERE lower(email) = lower(seed.email);
    ELSE
      INSERT INTO public.users (name, email, role)
      VALUES (seed.name, lower(seed.email), seed.role::public.user_role);
    END IF;
  END LOOP;
END $$;

-- ---------------------------------------------------------------------------
-- 8. GUARD — attached last, so the seeding above runs against a plain table
-- ---------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_guard_user_identity ON public.users;
CREATE TRIGGER trg_guard_user_identity
BEFORE UPDATE ON public.users
FOR EACH ROW EXECUTE FUNCTION public.guard_user_identity();

COMMIT;
