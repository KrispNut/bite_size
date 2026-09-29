-- ============================================================================
-- 012 — A ping wakes a closed phone
--
-- Until now every alert was a local notification fired from a realtime
-- stream, which means the app had to be running. A ping is the one alert
-- that must land on a phone whose app is closed — that is the whole point of
-- it — so it goes out as a push as well.
--
-- An AFTER INSERT trigger posts every new pings row, in the standard
-- database-webhook shape, to the ping-push Edge Function
-- (supabase/functions/ping-push). The function looks up users.fcm_token for
-- the recipient and sends one high-priority message through Firebase Cloud
-- Messaging. The app writes fcm_token on sign-in (PushService).
--
-- The call is made with pg_net directly rather than the dashboard's
-- Database Webhooks feature, so nothing has to be clicked on first. pg_net
-- is asynchronous: the trigger never blocks the insert, and the function's
-- answer lands in net._http_response a moment later — that table is where
-- to look when a ping doesn't arrive.
--
-- The function is deployed with JWT verification off (the caller is
-- Postgres, not a person) and gated by a shared secret instead. The secret
-- lives in Vault, not in this file. BEFORE running this, store it — the same
-- value that was set as the PING_WEBHOOK_SECRET secret on the Edge Function:
--
--   SELECT vault.create_secret('<the same long random string>',
--                              'ping_webhook_secret');
--
-- Requires 006. Safe to re-run.
-- ============================================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

CREATE OR REPLACE FUNCTION public.notify_ping_push()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions
AS $$
DECLARE
  v_secret TEXT;
BEGIN
  SELECT decrypted_secret INTO v_secret
    FROM vault.decrypted_secrets
   WHERE name = 'ping_webhook_secret'
   LIMIT 1;

  IF v_secret IS NULL THEN
    -- Never fail the ping itself over push. The row is in; the realtime
    -- path still reaches an open app. The missing secret shows up here.
    RAISE WARNING 'ping-push: vault secret ping_webhook_secret is not set';
    RETURN NEW;
  END IF;

  PERFORM net.http_post(
    url     := 'https://hzsokjybitalqsbkjcnl.supabase.co/functions/v1/ping-push',
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'x-ping-secret', v_secret
    ),
    body    := jsonb_build_object(
      'type',   'INSERT',
      'table',  'pings',
      'schema', 'public',
      'record', to_jsonb(NEW)
    ),
    timeout_milliseconds := 5000
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_ping_push ON public.pings;
CREATE TRIGGER trg_ping_push
AFTER INSERT ON public.pings
FOR EACH ROW EXECUTE FUNCTION public.notify_ping_push();

COMMIT;

-- ============================================================================
-- Checking it after a ping:
--
--   SELECT id, status_code, content
--     FROM net._http_response ORDER BY id DESC LIMIT 5;
--
--   403 forbidden        the Vault secret and PING_WEBHOOK_SECRET differ
--   401                  ping-push was deployed with JWT verification on
--   200 {"skipped":...}  the recipient has no fcm_token yet
--   200 {"sent":true}    FCM accepted it; if the phone stayed silent, the
--                        problem is on the phone (permission, channel)
--   no rows              the trigger never fired
-- ============================================================================
