import {PGlite, type Transaction} from "@electric-sql/pglite";
import {randomUUID} from "node:crypto";
import {readdirSync, readFileSync} from "node:fs";
import {dirname, join} from "node:path";
import {fileURLToPath} from "node:url";
import {expect} from "vitest";

const here = dirname(fileURLToPath(import.meta.url));
export const testsDir = join(here, "..");
export const migrationsDir = join(testsDir, "..", "migrations");
export const repoRoot = join(testsDir, "..", "..");

export const FIREBASE_PROJECT = "busineedger-ab7a1";
export const ISSUER = `https://securetoken.google.com/${FIREBASE_PROJECT}`;

/** A fresh in-memory Postgres with the Supabase stand-ins and every migration applied, in order. */
export async function createDb(): Promise<PGlite> {
  const db = await PGlite.create();
  await db.exec(readFileSync(join(testsDir, "supabase_stub.sql"), "utf8"));
  const files = readdirSync(migrationsDir).filter((f) => f.endsWith(".sql")).sort();
  for (const file of files) {
    try {
      await db.exec(readFileSync(join(migrationsDir, file), "utf8"));
    } catch (error) {
      throw new Error(`${file}: ${(error as Error).message}`);
    }
  }
  return db;
}

/** Claims of a Firebase ID token, as PostgREST would expose them (no `role` claim). */
export const firebaseClaims = (uid: string, extra: Record<string, unknown> = {}) => ({
  iss: ISSUER,
  aud: FIREBASE_PROJECT,
  sub: uid,
  user_id: uid,
  email: `${uid}@example.com`,
  email_verified: true,
  name: uid,
  picture: "",
  firebase: {sign_in_provider: "google.com"},
  ...extra,
});

type Row = Record<string, any>;

/**
 * One API caller. Every call runs like a PostgREST request: its own
 * transaction, `set local role`, and the JWT claims in request.jwt.claims.
 * Firebase tokens have no role claim, so the default role is `anon`.
 */
export class Client {
  constructor(
    readonly db: PGlite,
    readonly uid: string | null,
    readonly claims: Record<string, unknown> | null,
    readonly role: "anon" | "authenticated" | "service_role" = "anon",
  ) {}

  run<T>(fn: (tx: Transaction) => Promise<T>): Promise<T> {
    return this.db.transaction(async (tx) => {
      await tx.query("select set_config('request.jwt.claims', $1, true)", [
        this.claims ? JSON.stringify(this.claims) : "",
      ]);
      await tx.query(`set local role ${this.role}`);
      return fn(tx);
    });
  }

  async query<T = Row>(sql: string, params: unknown[] = []): Promise<T[]> {
    return this.run(async (tx) => (await tx.query<T>(sql, params)).rows);
  }

  /** POST /rest/v1/rpc/<name> with named arguments. */
  async rpc<T = Row>(name: string, args: Record<string, unknown>): Promise<T> {
    const keys = Object.keys(args).filter((k) => args[k] !== undefined);
    const params = keys.map((k) => {
      const v = args[k];
      return v !== null && typeof v === "object" ? JSON.stringify(v) : v;
    });
    const sql = `select public.${name}(${keys.map((k, i) => `${k} => $${i + 1}`).join(", ")}) as result`;
    const rows = await this.query<{result: T}>(sql, params);
    return rows[0].result;
  }

  /** INSERT … RETURNING id; JSON-ish values are passed as JSON text. */
  async insert(table: string, row: Row): Promise<Row[]> {
    const keys = Object.keys(row);
    const params = keys.map((k) => encode(row[k]));
    const sql = `insert into public.${table} (${keys.join(", ")}) values (${keys.map((_, i) => `$${i + 1}`).join(", ")}) returning *`;
    return this.query(sql, params);
  }

  /** UPDATE … WHERE <where> RETURNING *. Rows hidden by RLS simply do not match (like PostgREST). */
  async update(table: string, set: Row, where: Row): Promise<Row[]> {
    const setKeys = Object.keys(set);
    const whereKeys = Object.keys(where);
    const params = [...setKeys.map((k) => encode(set[k])), ...whereKeys.map((k) => encode(where[k]))];
    const sql = `update public.${table} set ${setKeys.map((k, i) => `${k} = $${i + 1}`).join(", ")}
      where ${whereKeys.map((k, i) => `${k} = $${setKeys.length + i + 1}`).join(" and ")} returning *`;
    return this.query(sql, params);
  }
}

function encode(v: unknown): unknown {
  if (Array.isArray(v) && v.length > 0 && v.every((x) => typeof x === "string")) return `{${v.map((x) => JSON.stringify(x)).join(",")}}`;
  if (v !== null && typeof v === "object") return JSON.stringify(v);
  return v;
}

/** A signed-in user (verified Firebase token). Creates their profile, as the app does at sign-in. */
export async function user(db: PGlite, uid: string, role: "anon" | "authenticated" = "anon"): Promise<Client> {
  const client = new Client(db, uid, firebaseClaims(uid), role);
  await client.query(
    `insert into public.profiles (id, display_name) values ($1, $1)
     on conflict (id) do update set display_name = excluded.display_name`,
    [uid],
  );
  return client;
}

export const anonymous = (db: PGlite) => new Client(db, null, null, "anon");

let counter = 0;
export const rid = (label = "r"): string => `${label}${Date.now().toString(36)}${(counter++).toString(36)}xx`;

export interface ErrorInfo {
  message: string;
  sqlstate: string;
  detail: Record<string, any>;
}

/** Asserts a call fails with our error contract: PTnnn + JSON detail {code, reason, …}. */
export async function expectFailure(
  promise: Promise<unknown>,
  code: string,
  extra?: Record<string, unknown>,
): Promise<ErrorInfo> {
  let error: any;
  try {
    await promise;
  } catch (e) {
    error = e;
  }
  if (!error) throw new Error(`Expected ${code}, but the call succeeded.`);
  if (typeof error.code !== "string" || !error.code.startsWith("PT")) throw error;
  const detail = JSON.parse(error.detail);
  expect(detail.code, error.message).toBe(code);
  if (extra) expect(detail).toMatchObject(extra);
  return {message: error.message, sqlstate: error.code, detail};
}

/**
 * Asserts a client write had no effect: refused with an error (RLS 42501,
 * a column privilege, a guard trigger, a constraint) or matched no visible
 * row (an UPDATE that RLS filters out returns nothing, as in PostgREST).
 */
export async function expectNoWrite(promise: Promise<Row[]>): Promise<void> {
  let rows: Row[];
  try {
    rows = await promise;
  } catch (e: any) {
    expect(e.code, e.message).toMatch(/^(42501|PT4\d\d|23\d\d\d|22\w\w\w)$/);
    return;
  }
  expect(rows, "write should have had no effect").toHaveLength(0);
}

export interface Fixture {
  businessId: string;
  categories: Record<string, string>;
}

export async function newBusiness(owner: Client, template = "retail"): Promise<Fixture> {
  const {businessId} = await owner.rpc<{businessId: string}>("create_business", {
    p_request_id: rid("biz"),
    p_name: `Biz ${owner.uid}`,
    p_currency_code: "INR",
    p_timezone: "Asia/Kolkata",
    p_template: template,
  });
  const rows = await owner.query<{id: string; name: string}>(
    "select id, name from public.categories where business_id = $1",
    [businessId],
  );
  return {businessId, categories: Object.fromEntries(rows.map((r) => [r.name, r.id]))};
}

/** Adds a member directly (test setup, like the emulator helper addRole). */
export async function addRole(db: PGlite, businessId: string, uid: string, role: string): Promise<void> {
  await db.query(
    `insert into public.members (business_id, user_id, role) values ($1, $2, $3)
     on conflict (business_id, user_id) do update set role = excluded.role, deleted_at = null`,
    [businessId, uid, role],
  );
}

/** A draft as the client writes it (through RLS). */
export async function draft(client: Client, businessId: string, fields: Row = {}): Promise<string> {
  const id = (fields.id as string | undefined) ?? randomUUID();
  await client.insert("transactions", {
    id,
    business_id: businessId,
    status: "draft",
    type: "sale",
    description: "Test entry",
    date: "2026-10-01",
    due_date: null,
    total_minor: 10000,
    line_items: [],
    custom_fields: {},
    created_by: client.uid,
    version: 0,
    ...fields,
  });
  return id;
}

/** Server-side reads (bypass RLS), like the Admin SDK in the emulator tests. */
export async function tx(db: PGlite, id: string): Promise<Row> {
  return (await db.query<Row>("select * from public.transactions where id = $1", [id])).rows[0];
}

export async function stats(db: PGlite, businessId: string, date: string): Promise<Row | undefined> {
  return (await db.query<Row>("select * from public.daily_stats where business_id = $1 and date = $2", [businessId, date]))
    .rows[0];
}

export const num = (v: unknown): number => Number(v);
