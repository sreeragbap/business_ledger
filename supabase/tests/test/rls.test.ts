/**
 * Port of functions/test/rules/rules.test.ts to RLS + privileges, plus the
 * Supabase-specific parts: anon vs authenticated role, forged issuers,
 * profiles, and the sync seq.
 */
import type {PGlite} from "@electric-sql/pglite";
import {randomUUID} from "node:crypto";
import {beforeAll, describe, expect, it} from "vitest";
import {
  addRole, anonymous, Client, createDb, expectFailure, expectNoWrite, firebaseClaims, ISSUER, newBusiness, rid, user,
} from "./helpers";

let db: PGlite;
let B: string;
let OTHER: string;
let owner: Client;
let admin: Client;
let editor: Client;
let viewer: Client;
let outsider: Client;
let confirmed1: string;
let category: string;

const draftRow = (by: Client, extra: Record<string, unknown> = {}) => ({
  id: randomUUID(), business_id: B, status: "draft", type: "sale", description: "Bricks", date: "2026-10-01",
  total_minor: 1000, line_items: [], created_by: by.uid, ...extra,
});

beforeAll(async () => {
  db = await createDb();
  owner = await user(db, "owner");
  admin = await user(db, "admin");
  editor = await user(db, "editor");
  viewer = await user(db, "viewer", "authenticated"); // either API role works
  outsider = await user(db, "outsider");
  B = (await newBusiness(owner, "general")).businessId;
  OTHER = (await newBusiness(outsider, "blank")).businessId;
  await addRole(db, B, "admin", "admin");
  await addRole(db, B, "editor", "editor");
  await addRole(db, B, "viewer", "viewer");
  category = (await owner.query("select id from public.categories where business_id = $1 and name = 'Sales'", [B]))[0].id;
  const id = randomUUID();
  await editor.insert("transactions", draftRow(editor, {id, category_id: category}));
  await owner.rpc("confirm_transaction", {p_business_id: B, p_transaction_id: id, p_request_id: rid()});
  confirmed1 = id;
});

const newDraft = async (by: Client = editor, extra: Record<string, unknown> = {}) => {
  const row = draftRow(by, extra);
  await by.insert("transactions", row);
  return row.id as string;
};

describe("business isolation", () => {
  it("members read their business; others and unauthenticated callers cannot", async () => {
    expect(await viewer.query("select id from public.businesses where id = $1", [B])).toHaveLength(1);
    expect(await viewer.query("select id from public.transactions where id = $1", [confirmed1])).toHaveLength(1);
    expect(await viewer.query("select * from public.daily_stats where business_id = $1", [B])).toHaveLength(1);
    expect(await outsider.query("select id from public.businesses where id = $1", [B])).toHaveLength(0);
    expect(await outsider.query("select id from public.transactions where id = $1", [confirmed1])).toHaveLength(0);
    expect(await outsider.query("select * from public.daily_stats where business_id = $1", [B])).toHaveLength(0);
    expect(await outsider.query("select * from public.members where business_id = $1", [B])).toHaveLength(0);
    expect(await outsider.query("select * from public.categories where business_id = $1", [B])).toHaveLength(0);
    expect(await anonymous(db).query("select id from public.businesses")).toHaveLength(0);
    expect(await anonymous(db).query("select id from public.transactions")).toHaveLength(0);
  });

  it("a token from another issuer or audience sees nothing", async () => {
    for (const claims of [
      {...firebaseClaims("owner"), iss: "https://unvpyjnotaukdxgmpytr.supabase.co/auth/v1"},
      {...firebaseClaims("owner"), iss: "https://securetoken.google.com/some-other-project", aud: "some-other-project"},
      {...firebaseClaims("owner"), aud: "some-other-project"},
      {...firebaseClaims("owner"), sub: ""},
      {iss: ISSUER, aud: "busineedger-ab7a1"},
    ]) {
      for (const role of ["anon", "authenticated"] as const) {
        const forged = new Client(db, "owner", claims, role);
        expect(await forged.query("select id from public.businesses")).toHaveLength(0);
        expect(await forged.query("select id from public.profiles")).toHaveLength(0);
        await expectNoWrite(forged.insert("transactions", draftRow(owner)));
      }
    }
  });

  it("listing businesses returns only the caller's", async () => {
    const mine = await editor.query<{id: string}>("select id from public.businesses");
    expect(mine.map((r) => r.id)).toEqual([B]);
    const theirs = await outsider.query<{id: string}>("select id from public.businesses");
    expect(theirs.map((r) => r.id)).toEqual([OTHER]);
  });

  it("nobody creates a business or membership from the client", async () => {
    await expectNoWrite(editor.insert("businesses", {
      name: "x", currency_code: "INR", currency_decimals: 2, currency_symbol: "₹", timezone: "UTC",
      template: "blank", owner_id: "editor",
    }));
    await expectNoWrite(owner.insert("members", {business_id: B, user_id: "someone", role: "admin"}));
    await expectNoWrite(editor.update("members", {role: "owner"}, {business_id: B, user_id: "editor"}));
    await expectNoWrite(owner.query("delete from public.members where business_id = $1 and user_id = 'viewer' returning *", [B]));
    await expectNoWrite(owner.query("delete from public.businesses where id = $1 returning *", [B]));
  });

  it("admins edit details but never currency, owner or template", async () => {
    expect(await admin.update("businesses", {name: "Renamed", settings: {invoicePrefix: "IN"}}, {id: B})).toHaveLength(1);
    await expectNoWrite(editor.update("businesses", {name: "Editor"}, {id: B}));
    await expectNoWrite(admin.update("businesses", {currency_code: "USD"}, {id: B}));
    await expectNoWrite(admin.update("businesses", {owner_id: "admin"}, {id: B}));
    await expectNoWrite(admin.update("businesses", {template: "retail"}, {id: B}));
    await expectNoWrite(admin.update("businesses", {seq: 1}, {id: B}));
    await expectNoWrite(admin.update("businesses", {name: ""}, {id: B}));
    await expectFailure(admin.update("businesses", {timezone: "Nowhere/City"}, {id: B}), "invalid-argument");
    await expectFailure(admin.update("businesses", {archived: true}, {id: B}), "permission-denied");
    expect(await owner.update("businesses", {archived: true}, {id: B})).toHaveLength(1);
    expect(await owner.update("businesses", {archived: false, timezone: "Europe/London"}, {id: B})).toHaveLength(1);
    const [b] = await db.query<{name: string; currency_code: string}>("select * from public.businesses where id = $1", [B])
      .then((r) => r.rows);
    expect(b).toMatchObject({name: "Renamed", currency_code: "INR"});
  });
});

describe("transactions", () => {
  it("editors write drafts; viewers and outsiders cannot", async () => {
    const id = await newDraft(editor);
    expect(await editor.update("transactions", {description: "Sand"}, {id})).toHaveLength(1);
    // Delete = soft delete; afterwards the draft is frozen.
    const [deleted] = await editor.update("transactions", {deleted_at: new Date().toISOString()}, {id});
    expect(deleted.deleted_at).not.toBeNull();
    await expectNoWrite(editor.update("transactions", {description: "again"}, {id}));
    await expectNoWrite(editor.update("transactions", {deleted_at: null}, {id}));
    await expectNoWrite(editor.query("delete from public.transactions where id = $1 returning *", [id]));
    await expectNoWrite(viewer.insert("transactions", draftRow(viewer)));
    await expectNoWrite(outsider.insert("transactions", draftRow(outsider)));
    await expectNoWrite(outsider.insert("transactions", {...draftRow(outsider), business_id: OTHER, id: id}));
  });

  it("drafts and configuration can be pushed as upserts (PostgREST resolution=merge-duplicates)", async () => {
    const row = {...draftRow(editor), created_at: "2000-01-01T00:00:00Z"};
    const upsert = (r: Record<string, unknown>) => {
      const keys = Object.keys(r);
      return editor.query(
        `insert into public.transactions (${keys.join(", ")})
         select * from jsonb_populate_record(null::public.transactions, $1::jsonb) r
         on conflict (id) do update set ${keys.map((k) => `${k} = excluded.${k}`).join(", ")} returning *`
          .replace("select * from", `select ${keys.map((k) => `r.${k}`).join(", ")} from`),
        [JSON.stringify(r)],
      );
    };
    const [created] = await upsert(row);
    expect(new Date(created.created_at).getFullYear()).toBeGreaterThan(2000);
    const [updated] = await upsert({...row, description: "Upserted"});
    expect(updated).toMatchObject({description: "Upserted", created_by: "editor"});
    expect(updated.created_at).toEqual(created.created_at);
    expect(Number(updated.seq)).toBeGreaterThan(Number(created.seq));
    // Upserting over a confirmed entry is still refused.
    await expectNoWrite(upsert({...row, id: confirmed1}));
  });

  it("clients cannot confirm, settle or alter confirmed entries", async () => {
    await expectNoWrite(owner.insert("transactions", draftRow(owner, {status: "confirmed"})));
    await expectNoWrite(owner.insert("transactions", draftRow(owner, {paid_minor: 1000})));
    await expectNoWrite(owner.insert("transactions", draftRow(owner, {outstanding_minor: 1000})));
    await expectNoWrite(owner.insert("transactions", draftRow(owner, {payment_status: "paid"})));
    await expectNoWrite(owner.insert("transactions", draftRow(owner, {is_open: true})));
    await expectNoWrite(owner.insert("transactions", draftRow(owner, {confirmed_at: new Date().toISOString()})));
    await expectNoWrite(owner.insert("transactions", draftRow(owner, {linked_transaction_id: confirmed1, link_kind: "refund"})));
    await expectNoWrite(owner.insert("transactions", draftRow(owner, {version: 3})));
    await expectNoWrite(owner.insert("transactions", draftRow(owner, {type: "refund"})));
    await expectNoWrite(owner.insert("transactions", draftRow(owner, {total_minor: 1.5})));
    await expectNoWrite(owner.insert("transactions", draftRow(owner, {total_minor: 10_000_000_000_001})));
    await expectNoWrite(owner.insert("transactions", draftRow(owner, {description: "x".repeat(201)})));
    await expectNoWrite(owner.insert("transactions", draftRow(owner, {line_items: Array(201).fill({})})));
    await expectNoWrite(owner.insert("transactions", draftRow(owner, {created_by: "editor"})));
    const id = await newDraft(editor);
    await expectNoWrite(owner.update("transactions", {status: "confirmed"}, {id}));
    await expectNoWrite(owner.update("transactions", {credited_minor: 5}, {id}));
    await expectNoWrite(owner.update("transactions", {created_by: "owner"}, {id}));
    await expectNoWrite(owner.update("transactions", {business_id: OTHER}, {id}));
    await expectNoWrite(owner.update("transactions", {description: "edited"}, {id: confirmed1}));
    await expectNoWrite(owner.update("transactions", {deleted_at: new Date().toISOString()}, {id: confirmed1}));
    await expectNoWrite(owner.query("delete from public.transactions where id = $1 returning *", [confirmed1]));
    await expectNoWrite(owner.insert("settlements", {
      business_id: B, transaction_id: confirmed1, id: "s1234567", kind: "payment", amount_minor: 1, date: "2026-10-01",
      balance_after: {}, created_by: "owner",
    }));
    // Another editor may change someone else's draft; the author stays.
    const [row] = await owner.update("transactions", {description: "by owner"}, {id});
    expect(row.created_by).toBe("editor");
  });

  it("stats, audit, counters, documents and requests are server-written", async () => {
    await expectNoWrite(owner.insert("daily_stats", {business_id: B, date: "2026-10-02", income_minor: 1}));
    await expectNoWrite(owner.update("daily_stats", {income_minor: 1}, {business_id: B, date: "2026-10-01"}));
    await expectNoWrite(owner.insert("audit_log", {business_id: B, entity: "x", entity_id: "x", action: "x", actor: "owner"}));
    await expectNoWrite(owner.insert("counters", {business_id: B, doc_type: "invoice", year: 2026, next: 1}));
    await expectNoWrite(owner.insert("documents", {
      business_id: B, id: "d1", type: "invoice", number: "INV-1", transaction_id: confirmed1, snapshot: {}, issued_by: "owner",
    }));
    await expectNoWrite(owner.insert("requests", {uid: "owner", request_id: "abcdefgh", op: "x"}));
    await expectNoWrite(owner.query("select * from public.requests"));
    await expectNoWrite(owner.query("select * from public.counters"));
    expect(await viewer.query("select * from public.audit_log where business_id = $1", [B])).toHaveLength(0);
    expect(await editor.query("select * from public.audit_log where business_id = $1", [B])).toHaveLength(0);
    expect((await admin.query("select * from public.audit_log where business_id = $1", [B])).length).toBeGreaterThan(0);
  });

  it("issued documents are read-only to clients", async () => {
    const {documentId} = await owner.rpc("issue_document", {
      p_business_id: B, p_transaction_id: confirmed1, p_type: "invoice", p_request_id: rid(),
    });
    expect(await viewer.query("select * from public.documents where id = $1", [documentId])).toHaveLength(1);
    expect(await outsider.query("select * from public.documents where id = $1", [documentId])).toHaveLength(0);
    for (const client of [owner, admin, editor]) {
      await expectNoWrite(client.update("documents", {number: "INV-2026-0099"}, {id: documentId}));
      await expectNoWrite(client.update("documents", {voided: true}, {id: documentId}));
      await expectNoWrite(client.query("delete from public.documents where id = $1 returning *", [documentId]));
    }
  });

  it("internal functions cannot be called by clients", async () => {
    await expectNoWrite(owner.query("select app.apply_stats($1, '{\"2026-10-01\":{\"income_minor\":5}}'::jsonb)", [B]));
    await expectNoWrite(owner.query("select app.request_end('owner', 'abcdefgh', 'x', '{}'::jsonb)"));
    await expectNoWrite(owner.query("select nextval('app.sync_seq')"));
  });
});

describe("configuration", () => {
  const categoryRow = (extra: Record<string, unknown> = {}) => ({
    id: randomUUID(), business_id: B, name: "Labour", kind: "expense", archived: false, sort_order: 0, ...extra,
  });

  it("editors manage categories; nobody deletes them from the client", async () => {
    const c1 = categoryRow();
    expect(await editor.insert("categories", c1)).toHaveLength(1);
    expect(await editor.update("categories", {name: "Wages", archived: true}, {id: c1.id})).toHaveLength(1);
    await expectNoWrite(owner.query("delete from public.categories where id = $1 returning *", [c1.id]));
    await expectNoWrite(editor.update("categories", {deleted_at: new Date().toISOString()}, {id: c1.id}));
    await expectNoWrite(editor.update("categories", {business_id: OTHER}, {id: c1.id}));
    await expectNoWrite(viewer.insert("categories", categoryRow()));
    await expectNoWrite(editor.insert("categories", categoryRow({kind: "bogus"})));
    await expectNoWrite(editor.insert("categories", categoryRow({name: ""})));
    await expectNoWrite(editor.insert("categories", categoryRow({name: "x".repeat(61)})));
    await expectNoWrite(outsider.insert("categories", categoryRow()));
    // Server-set fields are not the client's to choose.
    const c2 = categoryRow({deleted_at: new Date().toISOString(), created_at: "2000-01-01T00:00:00Z"});
    const [row] = await editor.insert("categories", c2);
    expect(row.deleted_at).toBeNull();
    expect(new Date(row.created_at).getFullYear()).toBeGreaterThan(2000);
    // A deleted category is frozen.
    await owner.rpc("delete_category", {p_business_id: B, p_category_id: c2.id});
    await expectNoWrite(editor.update("categories", {archived: true}, {id: c2.id}));
  });

  it("fields, parties and projects: editor+, validated, never deleted", async () => {
    expect(await editor.insert("custom_fields", {id: randomUUID(), business_id: B, label: "Site", type: "text"})).toHaveLength(1);
    await expectNoWrite(editor.insert("custom_fields", {id: randomUUID(), business_id: B, label: "Bad", type: "file"}));
    const party = {id: randomUUID(), business_id: B, name: "ACME", kind: "supplier"};
    expect(await editor.insert("parties", party)).toHaveLength(1);
    expect(await editor.update("parties", {archived: true}, {id: party.id})).toHaveLength(1);
    await expectNoWrite(editor.insert("parties", {id: randomUUID(), business_id: B, name: "X", kind: "friend"}));
    await expectNoWrite(viewer.insert("parties", {id: randomUUID(), business_id: B, name: "X", kind: "both"}));
    await expectNoWrite(editor.query("delete from public.parties where id = $1 returning *", [party.id]));
    const project = {id: randomUUID(), business_id: B, name: "Tower A", code: "TA"};
    expect(await editor.insert("projects", project)).toHaveLength(1);
    await expectNoWrite(outsider.update("projects", {name: "Mine"}, {id: project.id}));
  });
});

describe("profiles", () => {
  it("each user sees and writes only their own profile; email comes from the token", async () => {
    const mine = await owner.query("select * from public.profiles");
    expect(mine.map((r) => r.id)).toEqual(["owner"]);
    // Claiming someone else's email is ignored: add_member must not be fooled.
    const [p] = await editor.update("profiles", {email: "owner@example.com", display_name: "Ed"}, {id: "editor"});
    expect(p).toMatchObject({email: "editor@example.com", display_name: "Ed"});
    await expectNoWrite(editor.update("profiles", {display_name: "pwned"}, {id: "owner"}));
    await expectNoWrite(editor.insert("profiles", {id: "someone-else"}));
    const upper = new Client(db, "mixed", firebaseClaims("mixed", {email: "Mixed.Case@Example.COM"}));
    const [created] = await upper.insert("profiles", {id: "mixed"});
    expect(created.email).toBe("mixed.case@example.com");
  });
});

describe("sync", () => {
  it("every insert and update takes a new, higher seq; pulls see changes after a cursor", async () => {
    const id = await newDraft(editor);
    const [first] = await editor.query("select seq from public.transactions where id = $1", [id]);
    const cursor = Number(first.seq);
    expect(cursor).toBeGreaterThan(0);
    await editor.update("transactions", {description: "v2"}, {id});
    const [second] = await editor.query("select seq from public.transactions where id = $1", [id]);
    expect(Number(second.seq)).toBeGreaterThan(cursor);

    const category2 = randomUUID();
    await editor.insert("categories", {id: category2, business_id: B, name: "Fuel", kind: "expense"});
    await editor.update("transactions", {deleted_at: new Date().toISOString()}, {id});
    const changedTx = await viewer.query(
      "select id, deleted_at from public.transactions where business_id = $1 and seq > $2 order by seq", [B, cursor]);
    expect(changedTx).toHaveLength(1);
    expect(changedTx[0]).toMatchObject({id});
    expect(changedTx[0].deleted_at).not.toBeNull(); // soft deletes reach other devices
    const changedCategories = await viewer.query(
      "select id from public.categories where business_id = $1 and seq > $2", [B, cursor]);
    expect(changedCategories.map((r) => r.id)).toEqual([category2]);
    // Nothing of another business leaks into a pull.
    expect(await viewer.query("select id from public.transactions where business_id = $1 and seq > 0", [OTHER]))
      .toHaveLength(0);
  });

  it("RPC writes stamp seq too (transactions, settlements, stats, members)", async () => {
    const [{max}] = (await db.query<{max: string}>("select max(seq) as max from public.daily_stats")).rows;
    const id = await newDraft(editor, {category_id: category});
    await owner.rpc("confirm_transaction", {
      p_business_id: B, p_transaction_id: id, p_request_id: rid(), p_settle_now: true,
    });
    const after = Number(max);
    expect(await viewer.query("select 1 from public.settlements where business_id = $1 and seq > $2", [B, after]))
      .toHaveLength(1);
    expect((await viewer.query("select 1 from public.daily_stats where business_id = $1 and seq > $2", [B, after])).length)
      .toBeGreaterThan(0);
    await owner.rpc("remove_member", {p_business_id: B, p_uid: "viewer"});
    const removed = await admin.query("select deleted_at from public.members where business_id = $1 and user_id = 'viewer' and seq > $2",
      [B, after]);
    expect(removed[0].deleted_at).not.toBeNull();
    await addRole(db, B, "viewer", "viewer");
  });
});
