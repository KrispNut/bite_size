-- Bite Size Supabase Schema Definition
--
-- ⚠️  This file describes the ORIGINAL schema. It is no longer the whole
--     picture — apply the numbered files in docs/migrations/ on top of it,
--     in order. Migration 001 adds roles, auth_uid, claim_identity() and RLS.

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. USERS TABLE
CREATE TABLE public.users (
    id UUID PRIMARY KEY, -- Maps to Auth UID
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    photo_url TEXT,
    fcm_token TEXT,
    balance NUMERIC NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. SESSIONS TABLE
CREATE TABLE public.sessions (
    id TEXT PRIMARY KEY, -- yyyy-mm-dd
    date DATE NOT NULL,
    cutoff_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'locked', 'settled')),
    tandoor_runner_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    tandoor_runner_name TEXT,
    headcount INT NOT NULL DEFAULT 0,
    total_portions INT NOT NULL DEFAULT 0,
    total_rotis INT NOT NULL DEFAULT 0,
    total_roti_cost NUMERIC,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. ENTRIES TABLE
CREATE TABLE public.entries (
    session_id TEXT NOT NULL REFERENCES public.sessions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    user_name TEXT NOT NULL,
    dish_name TEXT NOT NULL,
    portions INT NOT NULL DEFAULT 0,
    rotis_needed INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (session_id, user_id)
);

-- 4. EXTRA ORDERS TABLE
CREATE TABLE public.extra_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id TEXT NOT NULL REFERENCES public.sessions(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    cost NUMERIC NOT NULL,
    paid_by_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    paid_by_name TEXT,
    shared_by_ids UUID[] NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. TRANSACTIONS TABLE (LEDGER)
CREATE TABLE public.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id TEXT REFERENCES public.sessions(id) ON DELETE SET NULL,
    type TEXT NOT NULL CHECK (type IN ('roti', 'extraFood', 'settlement')),
    from_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    from_name TEXT,
    to_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    to_name TEXT,
    amount NUMERIC NOT NULL,
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. AUTOMATIC SESSION AGGREGATES TRIGGER
CREATE OR REPLACE FUNCTION update_session_aggregates()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        UPDATE public.sessions
        SET headcount = headcount + 1,
            total_portions = total_portions + NEW.portions,
            total_rotis = total_rotis + NEW.rotis_needed,
            updated_at = NOW()
        WHERE id = NEW.session_id;
    ELSIF (TG_OP = 'UPDATE') THEN
        UPDATE public.sessions
        SET total_portions = total_portions + (NEW.portions - OLD.portions),
            total_rotis = total_rotis + (NEW.rotis_needed - OLD.rotis_needed),
            updated_at = NOW()
        WHERE id = NEW.session_id;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE public.sessions
        SET headcount = headcount - 1,
            total_portions = total_portions - OLD.portions,
            total_rotis = total_rotis - OLD.rotis_needed,
            updated_at = NOW()
        WHERE id = OLD.session_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_entries_aggregates
AFTER INSERT OR UPDATE OR DELETE ON public.entries
FOR EACH ROW
EXECUTE FUNCTION update_session_aggregates();

-- Enable Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.sessions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.entries;
