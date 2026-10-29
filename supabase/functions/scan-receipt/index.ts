// scan-receipt: turns on-device OCR text of a receipt into ledger fields
// with Claude. Only text arrives here; no image, nothing is stored.
//
// Auth: the caller's Firebase ID token (the same bearer token the app sends
// to PostgREST), verified against Google's public keys. The gateway's own
// JWT check is off for this function (config.toml) because it does not
// know Firebase tokens.
//
// Secrets: ANTHROPIC_API_KEY (`npx supabase secrets set ...`).
// Optional: FIREBASE_PROJECT_ID (defaults to the app's project).

import Anthropic from "npm:@anthropic-ai/sdk@1.3.0";
import { createRemoteJWKSet, jwtVerify } from "npm:jose@6.2.13";
import {
  cleanResult,
  OUTPUT_SCHEMA,
  parseRequest,
  SYSTEM_PROMPT,
  userPrompt,
} from "./receipt.ts";

const MODEL = "claude-haiku-5-5";
const FIREBASE_PROJECT = Deno.env.get("FIREBASE_PROJECT_ID") ??
  "busineedger-ab7a1";
const GOOGLE_KEYS = createRemoteJWKSet(
  new URL(
    "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com",
  ),
);

// Reads ANTHROPIC_API_KEY. One retry, and a deadline the phone can wait
// for: past it the app falls back to its on-device reading.
const anthropic = new Anthropic({ maxRetries: 1, timeout: 15_000 });

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

async function authorised(request: Request): Promise<boolean> {
  const token = request.headers.get("Authorization")?.replace(
    /^Bearer\s+/i,
    "",
  );
  if (!token) return false;
  try {
    await jwtVerify(token, GOOGLE_KEYS, {
      issuer: `https://securetoken.google.com/${FIREBASE_PROJECT}`,
      audience: FIREBASE_PROJECT,
    });
    return true;
  } catch {
    return false;
  }
}

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return json(405, { error: "method-not-allowed" });
  }
  if (!(await authorised(request))) {
    return json(401, { error: "unauthenticated" });
  }

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return json(400, { error: "invalid-argument", message: "body must be JSON" });
  }
  const scan = parseRequest(body);
  if (typeof scan === "string") {
    return json(400, { error: "invalid-argument", message: scan });
  }

  try {
    const response = await anthropic.messages.create({
      model: MODEL,
      max_tokens: 4096,
      // Extraction, not reasoning: low effort keeps it to a second or two.
      output_config: {
        effort: "low",
        format: { type: "json_schema", schema: OUTPUT_SCHEMA },
      },
      system: SYSTEM_PROMPT,
      messages: [{ role: "user", content: userPrompt(scan) }],
    });

    if (response.stop_reason === "refusal") {
      return json(422, { error: "unreadable", message: "refused" });
    }
    if (response.stop_reason === "max_tokens") {
      return json(422, { error: "unreadable", message: "answer too long" });
    }
    const text = response.content.find((block) => block.type === "text");
    if (!text || text.type !== "text") {
      return json(422, { error: "unreadable", message: "no answer" });
    }
    return json(200, cleanResult(JSON.parse(text.text), scan));
  } catch (error) {
    if (error instanceof Anthropic.RateLimitError) {
      return json(503, { error: "busy" });
    }
    if (error instanceof Anthropic.APIConnectionTimeoutError) {
      return json(504, { error: "timeout" });
    }
    if (error instanceof Anthropic.APIError) {
      console.error("Claude API error", error.status, error.message);
      return json(502, { error: "upstream" });
    }
    if (error instanceof SyntaxError) {
      return json(422, { error: "unreadable", message: "malformed answer" });
    }
    console.error("scan-receipt failed", error);
    return json(500, { error: "internal" });
  }
});
