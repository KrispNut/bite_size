// ping-push — a ping wakes a closed phone.
//
// Fired by migration 012: an AFTER INSERT trigger on public.pings posts the
// standard database-webhook payload here over pg_net. This looks up the
// recipient's FCM token and sends one high-priority push through the FCM
// HTTP v1 API.
//
// On the phone the message does two different things by design:
//   - app closed or backgrounded: Android/iOS show it in the notification
//     centre (the `notification` block), on the `ping_channel` channel;
//   - app on screen: nothing is shown by the OS, the app receives the `data`
//     block through FirebaseMessaging.onMessage and says it in-app.
//
// Secrets (set with `supabase secrets set`):
//   FCM_SERVICE_ACCOUNT_JSON  the Firebase service-account key file, verbatim
//   PING_WEBHOOK_SECRET       shared with the trigger in migration 012
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are injected automatically.
//
// Deploy with JWT verification OFF (supabase/config.toml does this): the
// caller is Postgres, not a signed-in user, and the shared secret is the
// gate instead.

import { SignJWT, importPKCS8 } from "npm:jose@5.9.6";
import { createClient } from "npm:@supabase/supabase-js@2";

const SECRET = Deno.env.get("PING_WEBHOOK_SECRET") ?? "";
const SA = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT_JSON") ?? "{}");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

// One OAuth token per warm isolate; FCM tokens last an hour.
let cached: { token: string; exp: number } | null = null;

async function accessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cached && cached.exp - 60 > now) return cached.token;

  const key = await importPKCS8(SA.private_key, "RS256");
  const assertion = await new SignJWT({
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(SA.client_email)
    .setAudience(SA.token_uri)
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(key);

  const res = await fetch(SA.token_uri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!res.ok) throw new Error(`oauth ${res.status}: ${await res.text()}`);
  const data = await res.json();
  cached = { token: data.access_token, exp: now + (data.expires_in ?? 3600) };
  return cached.token;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "POST only" }, 405);
  if (!SECRET || req.headers.get("x-ping-secret") !== SECRET) {
    return json({ error: "forbidden" }, 403);
  }
  if (!SA.private_key || !SA.client_email || !SA.project_id) {
    return json({ error: "FCM_SERVICE_ACCOUNT_JSON is not set" }, 500);
  }

  const payload = await req.json();
  if (payload.type !== "INSERT" || payload.table !== "pings") {
    return json({ skipped: "not a pings insert" });
  }
  const ping = payload.record;

  const supabase = createClient(SUPABASE_URL, SERVICE_KEY);
  const { data: user, error } = await supabase
    .from("users")
    .select("fcm_token")
    .eq("id", ping.to_id)
    .maybeSingle();
  if (error) return json({ error: error.message }, 500);

  const token = user?.fcm_token;
  if (!token) return json({ skipped: "recipient has no fcm_token" });

  const fromName = (ping.from_name || "Someone").trim();
  const body = (ping.message || "").trim() || "Open the app.";

  const message = {
    message: {
      token,
      notification: { title: `🔔 ${fromName} pinged you`, body },
      data: {
        type: "ping",
        ping_id: String(ping.id),
        from_name: fromName,
        message: body,
      },
      android: {
        priority: "HIGH",
        notification: {
          channel_id: "ping_channel",
          // One entry per ping in the tray; a re-delivery replaces, not stacks.
          tag: String(ping.id),
          sound: "default",
          default_vibrate_timings: true,
        },
      },
      apns: {
        headers: { "apns-priority": "10" },
        payload: {
          aps: { sound: "default", "interruption-level": "time-sensitive" },
        },
      },
    },
  };

  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${SA.project_id}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${await accessToken()}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(message),
    },
  );
  const text = await res.text();

  // The app was uninstalled or its token rotated: forget it so the next
  // ping doesn't keep failing against a dead token.
  if (res.status === 404 && text.includes("UNREGISTERED")) {
    await supabase.from("users").update({ fcm_token: null }).eq("id", ping.to_id);
    return json({ skipped: "token unregistered — cleared" });
  }
  if (!res.ok) return json({ error: text }, 502);
  return json({ sent: true });
});
