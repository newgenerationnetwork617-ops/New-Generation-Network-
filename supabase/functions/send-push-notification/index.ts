import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function b64url(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
}

function pemBytes(pem: string): Uint8Array {
  const body = pem.replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "").replace(/\s/g, "");
  const raw = atob(body);
  return Uint8Array.from(raw, (c) => c.charCodeAt(0));
}

async function getFcmAccessToken(account: Record<string, string>): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(new TextEncoder().encode(JSON.stringify({ alg: "RS256", typ: "JWT" })));
  const claim = b64url(new TextEncoder().encode(JSON.stringify({
    iss: account.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  })));
  const unsigned = header + "." + claim;
  const key = await crypto.subtle.importKey(
    "pkcs8", pemBytes(account.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"],
  );
  const signature = new Uint8Array(await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(unsigned),
  ));
  const assertion = unsigned + "." + b64url(signature);
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  const result = await response.json();
  if (!response.ok || !result.access_token) {
    throw new Error("Firebase OAuth token request failed: " + JSON.stringify(result));
  }
  return result.access_token as string;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405, headers: cors });

  const authHeader = req.headers.get("Authorization") ?? "";
  const jwt = authHeader.replace(/^Bearer\s+/i, "");
  if (!jwt) return new Response(JSON.stringify({ error: "Authentication required" }), {
    status: 401, headers: { ...cors, "Content-Type": "application/json" },
  });

  const url = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !serviceKey) return new Response(JSON.stringify({ error: "Server configuration missing" }), {
    status: 500, headers: { ...cors, "Content-Type": "application/json" },
  });

  const admin = createClient(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });
  const { data: authData, error: authError } = await admin.auth.getUser(jwt);
  const user = authData?.user;
  if (authError || !user || user.is_anonymous) return new Response(JSON.stringify({ error: "Invalid user session" }), {
    status: 401, headers: { ...cors, "Content-Type": "application/json" },
  });

  let input: { type?: string; record_id?: string; exclude_installation_id?: string };
  try { input = await req.json(); } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), { status: 400, headers: { ...cors, "Content-Type": "application/json" } });
  }
  const type = input.type;
  const recordId = input.record_id;
  if (!recordId || !/^[0-9a-f-]{36}$/i.test(recordId)) return new Response(JSON.stringify({ error: "A valid record_id is required" }), {
    status: 400, headers: { ...cors, "Content-Type": "application/json" },
  });

  let title = "New Generation Network";
  let body = "There is a new update in N.G.N.";
  let route = "home";

  if (type === "community_message") {
    const [{ data: message }, { data: profile }] = await Promise.all([
      admin.from("community_messages").select("id,author_id,message_type,body,file_name").eq("id", recordId).maybeSingle(),
      admin.from("profiles").select("is_muted,is_banned,display_name").eq("id", user.id).maybeSingle(),
    ]);
    if (!message || message.author_id !== user.id) return new Response(JSON.stringify({ error: "Message not found or not owned by caller" }), {
      status: 403, headers: { ...cors, "Content-Type": "application/json" },
    });
    if (profile?.is_muted || profile?.is_banned) return new Response(JSON.stringify({ error: "This account cannot send community notifications" }), {
      status: 403, headers: { ...cors, "Content-Type": "application/json" },
    });
    const sender = profile?.display_name || "A community member";
    title = "N.G.N. Community";
    body = message.message_type === "text"
      ? sender + ": " + String(message.body ?? "").slice(0, 150)
      : sender + (message.message_type === "voice" ? " sent a voice message" : " shared a file");
    route = "community";
  } else if (["announcement", "teaching", "event", "devotional"].includes(type ?? "")) {
    const { data: adminRow } = await admin.from("admin_members").select("user_id").eq("user_id", user.id).maybeSingle();
    if (!adminRow) return new Response(JSON.stringify({ error: "Administrator access required" }), {
      status: 403, headers: { ...cors, "Content-Type": "application/json" },
    });
    if (type === "announcement") {
      const { data } = await admin.from("announcements").select("title,body").eq("id", recordId).maybeSingle();
      if (!data) return new Response(JSON.stringify({ error: "Announcement not found" }), { status: 404, headers: { ...cors, "Content-Type": "application/json" } });
      title = data.title || "N.G.N. Announcement";
      body = String(data.body || "A new announcement has been published.").slice(0, 180);
      route = "home";
    } else if (type === "devotional") {
      const { data } = await admin.from("devotionals").select("title,message").eq("id", recordId).maybeSingle();
      if (!data) return new Response(JSON.stringify({ error: "Devotional not found" }), { status: 404, headers: { ...cors, "Content-Type": "application/json" } });
      title = "Daily Devotional: " + (data.title || "N.G.N.");
      body = String(data.message || "A new devotional is available.").slice(0, 180);
      route = "devotionals";
    } else if (type === "teaching") {
      const { data } = await admin.from("teachings").select("title,description").eq("id", recordId).maybeSingle();
      if (!data) return new Response(JSON.stringify({ error: "Teaching not found" }), { status: 404, headers: { ...cors, "Content-Type": "application/json" } });
      title = "New Teaching: " + (data.title || "N.G.N.");
      body = String(data.description || "A new teaching is available.").slice(0, 180);
      route = "teachings";
    } else {
      const { data } = await admin.from("events").select("title,description,published").eq("id", recordId).maybeSingle();
      if (!data || !data.published) return new Response(JSON.stringify({ error: "Published event not found" }), { status: 404, headers: { ...cors, "Content-Type": "application/json" } });
      title = "Upcoming N.G.N. Event: " + (data.title || "Event");
      body = String(data.description || "A new event has been announced.").slice(0, 180);
      route = "events";
    }
  } else {
    return new Response(JSON.stringify({ error: "Unsupported notification type" }), { status: 400, headers: { ...cors, "Content-Type": "application/json" } });
  }

  const rawAccount = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
  if (!rawAccount) return new Response(JSON.stringify({
    error: "Firebase sender is not configured. Add FCM_SERVICE_ACCOUNT_JSON to Supabase Edge Function secrets.",
    registeredDevices: 0,
  }), { status: 503, headers: { ...cors, "Content-Type": "application/json" } });

  let account: Record<string, string>;
  try { account = JSON.parse(rawAccount); } catch {
    return new Response(JSON.stringify({ error: "FCM_SERVICE_ACCOUNT_JSON is not valid JSON" }), { status: 500, headers: { ...cors, "Content-Type": "application/json" } });
  }
  const projectId = account.project_id;
  if (!projectId || !account.client_email || !account.private_key) return new Response(JSON.stringify({ error: "Firebase service account JSON is missing required fields" }), {
    status: 500, headers: { ...cors, "Content-Type": "application/json" },
  });

  try {
    const accessToken = await getFcmAccessToken(account);
    let tokenQuery = admin.from("ngn_push_tokens").select("installation_id,device_token");
    const excludeInstallationId = input.exclude_installation_id;
    if (excludeInstallationId && /^[0-9a-f-]{36}$/i.test(excludeInstallationId)) {
      tokenQuery = tokenQuery.neq("installation_id", excludeInstallationId);
    }
    const { data: tokens, error: tokenError } = await tokenQuery;
    if (tokenError) throw tokenError;
    let sent = 0, failed = 0;
    for (const row of tokens ?? []) {
      const result = await fetch("https://fcm.googleapis.com/v1/projects/" + projectId + "/messages:send", {
        method: "POST",
        headers: { Authorization: "Bearer " + accessToken, "Content-Type": "application/json" },
        body: JSON.stringify({ message: {
          token: row.device_token,
          notification: { title, body },
          data: { title, body, route, type: type ?? "" },
          android: { priority: "high", notification: { channel_id: "ngn_push_notifications", sound: "default" } },
          apns: { payload: { aps: { sound: "default" } } },
        } }),
      });
      if (result.ok) sent++;
      else {
        failed++;
        const detail = await result.text();
        if (detail.includes("UNREGISTERED") || detail.includes("registration-token-not-registered")) {
          await admin.from("ngn_push_tokens").delete().eq("installation_id", row.installation_id);
        }
      }
    }
    return new Response(JSON.stringify({ success: true, sent, failed, title }), {
      headers: { ...cors, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 502, headers: { ...cors, "Content-Type": "application/json" },
    });
  }
});
