/**
 * Port of functions/test/integration/ledger.test.ts: the RPCs end to end,
 * called the way PostgREST calls them (role anon + Firebase claims).
 */
import type {PGlite} from "@electric-sql/pglite";
import {beforeAll, beforeEach, describe, expect, it} from "vitest";
import {
  addRole, Client, createDb, draft, expectFailure, type Fixture, newBusiness, num, rid, stats, tx, user,
} from "./helpers";

let db: PGlite;
let owner: Client;
let stranger: Client;
let biz: Fixture;

beforeAll(async () => {
  db = await createDb();
  owner = await user(db, "owner");
  stranger = await user(db, "stranger");
});

beforeEach(async () => {
  biz = await newBusiness(owner);
});

const confirm = (id: string, extra: Record<string, unknown> = {}, as: Client = owner) =>
  as.rpc("confirm_transaction", {p_business_id: biz.businessId, p_transaction_id: id, p_request_id: rid(), ...extra});

const settle = (id: string, kind: string, amount: number, extra: Record<string, unknown> = {}) =>
  owner.rpc("record_settlement", {
    p_business_id: biz.businessId, p_transaction_id: id, p_request_id: rid(), p_kind: kind,
    p_amount_minor: amount, p_date: "2026-10-05", ...extra,
  });

const sale = (fields: Record<string, unknown> = {}) =>
  draft(owner, biz.businessId, {category_id: biz.categories["Product sales"], ...fields});

const issue = (id: string, type: string, extra: Record<string, unknown> = {}) =>
  owner.rpc("issue_document", {
    p_business_id: biz.businessId, p_transaction_id: id, p_type: type, p_request_id: rid(), ...extra,
  });

const year = async () =>
  num((await db.query<{y: number}>("select extract(year from now() at time zone 'Asia/Kolkata')::int as y")).rows[0].y);

describe("businesses", () => {
  it("seeds the template and keeps businesses separate", async () => {
    const other = await newBusiness(owner, "construction");
    expect(Object.keys(biz.categories)).toContain("Stock purchases");
    expect(Object.keys(other.categories)).toEqual(expect.arrayContaining(["Materials", "Labour", "Transport"]));
    expect(other.businessId).not.toBe(biz.businessId);

    const [business] = await owner.query("select * from public.businesses where id = $1", [biz.businessId]);
    expect(business).toMatchObject({
      currency_code: "INR", currency_decimals: 2, currency_symbol: "₹", owner_id: "owner", timezone: "Asia/Kolkata",
    });
    expect(business.settings).toMatchObject({invoicePrefix: "INV", billPrefix: "BILL", receiptPrefix: "RCPT"});
    expect(business.settings.enabledStandardFields).not.toContain("attachments");
    const members = await owner.query("select user_id, role from public.members where business_id = $1", [biz.businessId]);
    expect(members).toEqual([{user_id: "owner", role: "owner"}]);

    // Template fields are linked by id from their categories.
    const [materials] = await owner.query(
      "select field_ids from public.categories where business_id = $1 and name = 'Materials'", [other.businessId]);
    const labels = await owner.query(
      "select label from public.custom_fields where id = any($1::uuid[]) order by label", [materials.field_ids]);
    expect(labels.map((r) => r.label)).toEqual(["Site", "Unit"]);

    const [profile] = await owner.query("select last_business_id from public.profiles where id = 'owner'");
    expect(profile.last_business_id).toBe(other.businessId);
    const audit = await db.query("select * from public.audit_log where business_id = $1", [biz.businessId]);
    expect(audit.rows[0]).toMatchObject({entity: "business", action: "create", actor: "owner"});
  });

  it("create_business is idempotent and validates its input", async () => {
    const requestId = rid("same");
    const args = {p_request_id: requestId, p_name: "  Shop  ", p_currency_code: "USD", p_timezone: "UTC", p_template: "blank"};
    const first = await owner.rpc("create_business", args);
    const again = await owner.rpc("create_business", args);
    expect(again).toEqual(first);
    const [row] = await owner.query("select name from public.businesses where id = $1", [first.businessId]);
    expect(row.name).toBe("Shop");

    await expectFailure(owner.rpc("create_business", {...args, p_request_id: rid(), p_currency_code: "XYZ"}),
      "invalid-argument", {field: "currencyCode"});
    await expectFailure(owner.rpc("create_business", {...args, p_request_id: rid(), p_timezone: "Mars/Base"}),
      "invalid-argument", {field: "timezone"});
    await expectFailure(owner.rpc("create_business", {...args, p_request_id: rid(), p_template: "nope"}),
      "invalid-argument", {field: "template"});
    await expectFailure(owner.rpc("create_business", {...args, p_request_id: rid(), p_name: "   "}),
      "invalid-argument", {field: "name"});
    await expectFailure(owner.rpc("create_business", {...args, p_request_id: "short"}),
      "invalid-argument", {field: "requestId"});
  });

  it("refuses financial calls from non-members and viewers", async () => {
    const id = await sale();
    await expectFailure(confirm(id, {}, stranger), "permission-denied", {reason: "notMember"});
    const viewer = await user(db, "viewer");
    await addRole(db, biz.businessId, viewer.uid!, "viewer");
    const e = await expectFailure(confirm(id, {}, viewer), "permission-denied", {reason: "role", required: "admin"});
    expect(e.message).toBe("This needs the admin role or higher.");
    expect(e.sqlstate).toBe("PT403");
    expect((await tx(db, id)).status).toBe("draft");
  });

  it("refuses callers without a verified Firebase token", async () => {
    const nobody = new Client(db, null, null);
    await expectFailure(nobody.rpc("create_business", {
      p_request_id: rid(), p_name: "x", p_currency_code: "INR", p_timezone: "UTC", p_template: "blank",
    }), "unauthenticated");
    const forged = new Client(db, "owner", {sub: "owner", iss: "https://evil.example.com", aud: "busineedger-ab7a1"});
    await expectFailure(forged.rpc("confirm_transaction", {
      p_business_id: biz.businessId, p_transaction_id: crypto.randomUUID(), p_request_id: rid(),
    }), "unauthenticated");
  });
});

describe("confirm", () => {
  it("validates required fields before confirming", async () => {
    const missingCategory = await draft(owner, biz.businessId, {category_id: null});
    const e = await expectFailure(confirm(missingCategory), "invalid-argument", {reason: "validation"});
    expect(e.detail.field).toBe("categoryId");
    expect(e.message).toBe("Choose a category.");

    const wrongKind = await sale({category_id: biz.categories["Rent"]});
    const kind = await expectFailure(confirm(wrongKind), "invalid-argument");
    expect(kind.message).toBe('"Rent" is an expense category.');

    const badLines = await sale({line_items: [{description: "x", quantityMilli: 2500, rateMinor: 333, amountMinor: 832}]});
    await expectFailure(confirm(badLines), "invalid-argument", {field: "lineItems"});

    const noDate = await sale({date: null});
    await expectFailure(confirm(noDate), "invalid-argument", {field: "date"});
    const dueBefore = await sale({due_date: "2026-09-30"});
    await expectFailure(confirm(dueBefore), "invalid-argument", {field: "dueDate"});
    const zero = await sale({total_minor: 0});
    await expectFailure(confirm(zero), "failed-precondition", {violation: "nonPositiveAmount"});
    const noDirection = await draft(owner, biz.businessId, {type: "adjustment", category_id: biz.categories["Rent"]});
    await expectFailure(confirm(noDirection), "invalid-argument", {field: "direction"});
    await expectFailure(confirm(crypto.randomUUID()), "not-found");
  });

  it("checks required custom fields of the category", async () => {
    const [field] = await owner.query(
      "select id from public.custom_fields where business_id = $1 and label = 'SKU / item code'", [biz.businessId]);
    await owner.update("custom_fields", {required: true}, {id: field.id});
    const id = await sale();
    const e = await expectFailure(confirm(id), "invalid-argument", {field: `customFields.${field.id}`});
    expect(e.message).toBe("SKU / item code is required.");
    await owner.update("transactions", {custom_fields: {[field.id]: "SKU-1"}}, {id});
    await confirm(id);
  });

  it("drafts never count; confirming adds income by transaction date", async () => {
    await sale({total_minor: 99999});
    expect(await stats(db, biz.businessId, "2026-10-01")).toBeUndefined();

    const id = await sale({
      total_minor: 0,
      line_items: [{description: "Bag", quantityMilli: 2500, rateMinor: 333, amountMinor: 833}],
      due_date: "2026-10-31",
    });
    const result = await confirm(id);
    expect(result).toMatchObject({transactionId: id, version: 1, paymentStatus: "unpaid", settlementId: null});
    const t = await tx(db, id);
    expect(t).toMatchObject({status: "confirmed", direction: "in", is_open: true, version: 1, confirmed_by: "owner"});
    expect(num(t.total_minor)).toBe(833);
    expect(num(t.outstanding_minor)).toBe(833);
    expect(t.category_name).toBe("Product sales");
    expect(t.search_tokens).toContain("tes");
    expect(t.search_tokens).toContain("product");
    const s = (await stats(db, biz.businessId, "2026-10-01"))!;
    expect(num(s.income_minor)).toBe(833);
    expect(num(s.cash_in_minor)).toBe(0);
    expect(s.by_category[biz.categories["Product sales"]].in).toBe(833);
    expect(s.by_type.sale.in).toBe(833);

    await expectFailure(confirm(id), "failed-precondition", {violation: "draftOnly"});
  });

  it("settleNow confirms a cash expense as Paid in one step", async () => {
    const id = await draft(owner, biz.businessId, {type: "expense", category_id: biz.categories["Rent"], total_minor: 5000});
    const result = await confirm(id, {p_settle_now: true, p_settle_date: "2026-10-02", p_settle_method: "cash"});
    expect(result.paymentStatus).toBe("paid");
    expect(result.settlementId).toBeTruthy();
    expect(num((await stats(db, biz.businessId, "2026-10-01"))!.expense_minor)).toBe(5000);
    expect(num((await stats(db, biz.businessId, "2026-10-02"))!.cash_out_minor)).toBe(5000);
    const settlements = await owner.query("select * from public.settlements where transaction_id = $1", [id]);
    expect(settlements).toHaveLength(1);
    expect(settlements[0]).toMatchObject({kind: "payment", method: "cash", id: result.settlementId});
    expect(settlements[0].balance_after).toMatchObject({paidMinor: 5000, outstandingMinor: 0, paymentStatus: "paid"});
  });

  it("a payment entry is settled on confirm and counts as cash only", async () => {
    const id = await draft(owner, biz.businessId, {type: "payment", direction: "in", category_id: null, total_minor: 700});
    expect((await confirm(id)).paymentStatus).toBe("paid");
    const s = (await stats(db, biz.businessId, "2026-10-01"))!;
    expect(num(s.income_minor)).toBe(0);
    expect(num(s.cash_in_minor)).toBe(700);
  });
});

describe("settlements", () => {
  it("partial payments move the balance to Paid, and overpayment is refused", async () => {
    const id = await sale();
    await confirm(id);
    expect((await settle(id, "payment", 4000)).paymentStatus).toBe("partiallyPaid");
    const e = await expectFailure(settle(id, "payment", 6001), "failed-precondition", {violation: "overpayment"});
    expect(e.message).toBe("That is more than the outstanding balance.");
    expect(e.sqlstate).toBe("PT412");
    const done = await settle(id, "payment", 6000);
    expect(done).toMatchObject({paymentStatus: "paid", outstandingMinor: 0, version: 3});
    expect((await tx(db, id)).is_open).toBe(false);
    expect(num((await stats(db, biz.businessId, "2026-10-05"))!.cash_in_minor)).toBe(10000);
    expect(num((await stats(db, biz.businessId, "2026-10-01"))!.income_minor)).toBe(10000);
  });

  it("a retried request applies once; reusing its id for another action is refused", async () => {
    const id = await sale();
    await confirm(id);
    const requestId = rid("dup");
    const first = await settle(id, "payment", 3000, {p_request_id: requestId});
    const second = await settle(id, "payment", 3000, {p_request_id: requestId});
    expect(second).toEqual(first);
    expect(num((await tx(db, id)).paid_minor)).toBe(3000);
    expect(await owner.query("select * from public.settlements where transaction_id = $1", [id])).toHaveLength(1);
    await expectFailure(
      owner.rpc("cancel_transaction", {p_business_id: biz.businessId, p_transaction_id: id, p_request_id: requestId}),
      "already-exists", {reason: "requestReused"});
    // Request ids are per user: another admin may use the same string.
    const admin = await user(db, "admin-dup");
    await addRole(db, biz.businessId, "admin-dup", "admin");
    const other = await admin.rpc("record_settlement", {
      p_business_id: biz.businessId, p_transaction_id: id, p_request_id: rid("other"), p_kind: "payment",
      p_amount_minor: 1000, p_date: "2026-10-05",
    });
    expect(other.paymentStatus).toBe("partiallyPaid");
  });

  it("serial payments cannot together exceed the balance (row lock covers concurrent ones)", async () => {
    // PGlite has one connection, so the two calls run one after the other;
    // the RPC re-reads the balance under `select … for update`, which is
    // what makes truly concurrent calls safe on a real Postgres.
    const id = await sale();
    await confirm(id);
    const results = await Promise.allSettled([settle(id, "payment", 6000), settle(id, "payment", 6000)]);
    expect(results.filter((r) => r.status === "fulfilled")).toHaveLength(1);
    const t = await tx(db, id);
    expect(num(t.paid_minor)).toBe(6000);
    expect(num(t.outstanding_minor)).toBe(4000);
  });

  it("refunds keep the original, add a linked entry and reduce income once", async () => {
    const id = await sale();
    await confirm(id);
    await settle(id, "payment", 10000);
    const refund = await settle(id, "refund", 3000, {p_date: "2026-10-07", p_note: "damaged", p_method: "upi"});
    expect(refund.paymentStatus).toBe("partiallyRefunded");
    const original = await tx(db, id);
    expect(original).toMatchObject({status: "confirmed", payment_status: "partiallyRefunded"});
    expect(num(original.refunded_minor)).toBe(3000);
    expect(num(original.outstanding_minor)).toBe(0);
    expect(num(original.effective_minor)).toBe(7000);
    const linked = await tx(db, refund.linkedTransactionId);
    expect(linked).toMatchObject({
      type: "refund", linked_transaction_id: id, link_kind: "refund", direction: "out", status: "confirmed",
      description: "Refund · Test entry", notes: "damaged", payment_method: "upi", settlement_id: refund.settlementId,
      payment_status: "notApplicable", is_open: false, version: 1,
    });
    expect(num(linked.total_minor)).toBe(3000);
    expect(linked.search_tokens).toContain("refund");
    expect(num((await stats(db, biz.businessId, "2026-10-01"))!.income_minor)).toBe(7000);
    expect(num((await stats(db, biz.businessId, "2026-10-07"))!.cash_out_minor)).toBe(3000);
    await expectFailure(settle(id, "refund", 7001), "failed-precondition", {violation: "overRefund"});
    // The linked entry is not cancellable or editable on its own.
    await expectFailure(owner.rpc("cancel_transaction", {
      p_business_id: biz.businessId, p_transaction_id: linked.id, p_request_id: rid(),
    }), "failed-precondition");
  });

  it("credits close the balance without cash", async () => {
    const id = await sale();
    await confirm(id);
    await settle(id, "payment", 9500);
    expect((await settle(id, "credit", 500)).paymentStatus).toBe("paid");
    expect(num((await stats(db, biz.businessId, "2026-10-01"))!.income_minor)).toBe(9500);
    expect(num((await stats(db, biz.businessId, "2026-10-05"))!.cash_in_minor)).toBe(9500);
  });

  it("drafts and non-settleable entries take no settlements", async () => {
    const d = await sale();
    await expectFailure(settle(d, "payment", 100), "failed-precondition", {violation: "notConfirmed"});
    const adj = await draft(owner, biz.businessId, {type: "adjustment", direction: "out", category_id: biz.categories["Rent"]});
    await confirm(adj);
    await expectFailure(settle(adj, "payment", 100), "failed-precondition", {violation: "notSettleable"});
    await expectFailure(settle(adj, "payment", 0), "failed-precondition", {violation: "nonPositiveAmount"});
    await expectFailure(settle(adj, "bogus", 1), "invalid-argument", {field: "kind"});
    await expectFailure(settle(adj, "payment", 1, {p_date: "2026-02-30"}), "invalid-argument", {field: "date"});
  });

  it("a stale expected version is a conflict", async () => {
    const id = await sale();
    await confirm(id);
    await expectFailure(settle(id, "payment", 100, {p_expected_version: 0}), "aborted", {reason: "conflict"});
    expect((await settle(id, "payment", 100, {p_expected_version: 1})).version).toBe(2);
  });
});

describe("edit and cancel", () => {
  const edit = (id: string, expectedVersion: number, changes: Record<string, unknown>) =>
    owner.rpc("edit_confirmed_transaction", {
      p_business_id: biz.businessId, p_transaction_id: id, p_request_id: rid(),
      p_expected_version: expectedVersion, p_changes: changes,
    });

  it("edits move stats by the difference and reject stale versions", async () => {
    const id = await sale();
    const {version} = await confirm(id);
    await settle(id, "payment", 4000);
    const stale = await expectFailure(edit(id, version, {totalMinor: 12000}), "aborted");
    expect(stale.message).toBe("This record was changed by someone else. Reload and try again.");
    const current = (await tx(db, id)).version;
    await expectFailure(edit(id, current, {totalMinor: 3999}), "failed-precondition", {violation: "totalBelowSettled"});
    const result = await edit(id, current, {totalMinor: 12000, date: "2026-10-03", description: "  Renamed "});
    expect(result).toMatchObject({version: current + 1, paymentStatus: "partiallyPaid"});
    expect(num((await stats(db, biz.businessId, "2026-10-01"))!.income_minor)).toBe(0);
    expect(num((await stats(db, biz.businessId, "2026-10-03"))!.income_minor)).toBe(12000);
    const t = await tx(db, id);
    expect(t).toMatchObject({payment_status: "partiallyPaid", description: "Renamed", updated_by: "owner"});
    expect(num(t.outstanding_minor)).toBe(8000);
    expect(t.search_tokens).toContain("renamed");
    const audit = await owner.query(
      "select before, after from public.audit_log where entity_id = $1 and action = 'edit'", [id]);
    expect(audit[0].before).toMatchObject({totalMinor: 10000, date: "2026-10-01", description: "Test entry"});
    expect(audit[0].after).toMatchObject({totalMinor: 12000, date: "2026-10-03", description: "Renamed"});
    expect(audit[0].before).not.toHaveProperty("categoryName"); // unchanged keys are left out
  });

  it("validates the changes like schemas.ts editConfirmed (strict, no attachments)", async () => {
    const id = await sale();
    const {version} = await confirm(id);
    await expectFailure(edit(id, version, {attachments: []}), "invalid-argument", {field: "changes"});
    await expectFailure(edit(id, version, {date: "2026-13-01"}), "invalid-argument", {field: "changes.date"});
    await expectFailure(edit(id, version, {description: "x".repeat(201)}), "invalid-argument");
    await expectFailure(edit(id, version, {categoryId: null}), "invalid-argument", {field: "changes.categoryId"});
    await expectFailure(edit(id, version, {categoryId: biz.categories["Rent"]}), "invalid-argument", {field: "categoryId"});
    await expectFailure(edit(id, version, {lineItems: [{description: "a", quantityMilli: 1000, rateMinor: 5, amountMinor: 6}]}),
      "invalid-argument", {field: "lineItems"});
    const lines = await edit(id, version, {lineItems: [{description: "a", quantityMilli: 1500, rateMinor: 1001, amountMinor: 1502, extra: 1}]});
    expect(lines.version).toBe(version + 1);
    const t = await tx(db, id);
    expect(num(t.total_minor)).toBe(1502);
    expect(t.line_items).toEqual([{description: "a", quantityMilli: 1500, rateMinor: 1001, amountMinor: 1502}]);
    expect(num((await stats(db, biz.businessId, "2026-10-01"))!.income_minor)).toBe(1502);
  });

  it("keeps the receipt date beside the entry's date, through confirm and edit", async () => {
    const dates = async (id: string) => (await db.query<{date: string; receipt: string | null}>(
      "select date::text as date, receipt_date::text as receipt from public.transactions where id = $1", [id])).rows[0];
    const id = await sale({receipt_date: "2024-03-15"});
    const {version} = await confirm(id);
    expect(await dates(id)).toEqual({date: "2026-10-01", receipt: "2024-03-15"});
    await expectFailure(edit(id, version, {receiptDate: "2024-02-30"}), "invalid-argument",
      {field: "changes.receiptDate"});
    await edit(id, version, {receiptDate: "2024-03-16"});
    expect(await dates(id)).toEqual({date: "2026-10-01", receipt: "2024-03-16"});
    const audit = await owner.query(
      "select before, after from public.audit_log where entity_id = $1 and action = 'edit'", [id]);
    expect(audit[0].before).toMatchObject({receiptDate: "2024-03-15"});
    expect(audit[0].after).toMatchObject({receiptDate: "2024-03-16"});
    await edit(id, version + 1, {receiptDate: null});
    expect((await dates(id)).receipt).toBeNull();
  });

  it("cancel needs refunds first, keeps the record and voids documents", async () => {
    const id = await sale();
    await confirm(id);
    await settle(id, "payment", 2000);
    const cancel = () => owner.rpc("cancel_transaction", {
      p_business_id: biz.businessId, p_transaction_id: id, p_request_id: rid(), p_reason: "mistake",
    });
    await expectFailure(cancel(), "failed-precondition", {violation: "cancelWithMoney"});
    const doc = await issue(id, "invoice");
    await settle(id, "refund", 2000);
    const result = await cancel();
    expect(result.voidedDocuments).toBe(1);
    const t = await tx(db, id);
    expect(t).toMatchObject({status: "cancelled", is_open: false, cancel_reason: "mistake", cancelled_by: "owner"});
    expect(num((await stats(db, biz.businessId, "2026-10-01"))!.income_minor)).toBe(0);
    const [issued] = await owner.query("select voided from public.documents where id = $1", [doc.documentId]);
    expect(issued.voided).toBe(true);
    await expectFailure(issue(id, "invoice"), "failed-precondition");
    await expectFailure(cancel(), "failed-precondition", {violation: "alreadyCancelled"});
  });

  it("drafts are deleted, not cancelled", async () => {
    const id = await sale();
    await expectFailure(owner.rpc("cancel_transaction", {
      p_business_id: biz.businessId, p_transaction_id: id, p_request_id: rid(),
    }), "failed-precondition");
  });
});

describe("documents", () => {
  it("numbers are sequential, unique and stable per subject", async () => {
    const a = await sale();
    const b = await sale();
    await confirm(a);
    await confirm(b);
    const first = await issue(a, "invoice");
    const again = await issue(a, "invoice");
    const second = await issue(b, "invoice");
    const y = await year();
    expect(first).toMatchObject({number: `INV-${y}-0001`, created: true, documentId: `invoice-${a}-main`});
    expect(again).toMatchObject({number: first.number, created: false});
    expect(second.number).toBe(`INV-${y}-0002`);
    await expectFailure(issue(a, "bill"), "failed-precondition");
    const unconfirmed = await sale();
    await expectFailure(issue(unconfirmed, "invoice"), "failed-precondition");

    // Same request id → same answer, no second number.
    const requestId = rid("doc");
    const c = await sale();
    await confirm(c);
    const x = await issue(c, "invoice", {p_request_id: requestId});
    const y2 = await issue(c, "invoice", {p_request_id: requestId});
    expect(y2).toEqual(x);
    expect(x.number).toBe(`INV-${y}-0003`);
  });

  it("a receipt shows the balance as of its payment", async () => {
    const id = await sale({party_id: null});
    await confirm(id);
    const p1 = await settle(id, "payment", 4000);
    await settle(id, "payment", 1000);
    await expectFailure(issue(id, "receipt"), "invalid-argument");
    const receipt = await issue(id, "receipt", {p_settlement_id: p1.settlementId});
    expect(receipt.number).toBe(`RCPT-${await year()}-0001`);
    const [doc] = await owner.query("select snapshot from public.documents where id = $1", [receipt.documentId]);
    expect(doc.snapshot.settlement).toMatchObject({amountMinor: 4000, paidToDateMinor: 4000, remainingMinor: 6000});
    expect(doc.snapshot.business).toMatchObject({name: "Biz owner", currency: {code: "INR", decimals: 2, symbol: "₹"}});
    expect(doc.snapshot.transaction).toMatchObject({type: "sale", totalMinor: 10000, paidMinor: 5000, date: "2026-10-01"});
  });

  it("the snapshot carries the party and the counter restarts each year", async () => {
    const partyId = crypto.randomUUID();
    await owner.insert("parties", {id: partyId, business_id: biz.businessId, name: "ACME Ltd", kind: "customer", phone: "99"});
    const id = await sale({party_id: partyId});
    await confirm(id);
    expect((await tx(db, id)).party_name).toBe("ACME Ltd");
    await db.query("insert into public.counters values ($1, 'invoice', 2001, 57)", [biz.businessId]);
    const doc = await issue(id, "invoice");
    expect(doc.number).toBe(`INV-${await year()}-0001`);
    const [row] = await owner.query("select snapshot from public.documents where id = $1", [doc.documentId]);
    expect(row.snapshot.party).toEqual({name: "ACME Ltd", address: "", phone: "99", email: ""});
  });
});

describe("categories and members", () => {
  it("a used category cannot be deleted; an unused one can", async () => {
    const used = biz.categories["Product sales"];
    await sale({category_id: used});
    const e = await expectFailure(
      owner.rpc("delete_category", {p_business_id: biz.businessId, p_category_id: used}),
      "failed-precondition", {reason: "inUse"});
    expect(e.message).toBe("Transactions use this category, so it cannot be deleted. Archive it instead.");
    const unused = biz.categories["Utilities"];
    expect(await owner.rpc("delete_category", {p_business_id: biz.businessId, p_category_id: unused}))
      .toEqual({categoryId: unused});
    const [row] = await owner.query("select deleted_at from public.categories where id = $1", [unused]);
    expect(row.deleted_at).not.toBeNull(); // soft delete, so other devices see it
    await expectFailure(owner.rpc("delete_category", {p_business_id: biz.businessId, p_category_id: unused}), "not-found");
  });

  it("members are added, re-roled and removed with role limits", async () => {
    const admin = await user(db, "admin1");
    const editor = await user(db, "editor1");
    const active = async () => (await owner.query(
      "select user_id from public.members where business_id = $1 and deleted_at is null order by added_at, user_id",
      [biz.businessId])).map((r) => r.user_id);

    await owner.rpc("add_member", {p_business_id: biz.businessId, p_email: "ADMIN1@example.com", p_role: "admin"});
    await admin.rpc("add_member", {p_business_id: biz.businessId, p_email: "editor1@example.com", p_role: "editor"});
    await expectFailure(
      admin.rpc("add_member", {p_business_id: biz.businessId, p_email: "stranger@example.com", p_role: "admin"}),
      "permission-denied");
    await expectFailure(
      editor.rpc("add_member", {p_business_id: biz.businessId, p_email: "stranger@example.com", p_role: "viewer"}),
      "permission-denied");
    const missing = await expectFailure(
      owner.rpc("add_member", {p_business_id: biz.businessId, p_email: "nobody@example.com", p_role: "viewer"}),
      "not-found");
    expect(missing.message).toContain("Ask them to sign in to the app once");
    await expectFailure(
      owner.rpc("add_member", {p_business_id: biz.businessId, p_email: "editor1@example.com", p_role: "viewer"}),
      "already-exists");
    const [added] = await owner.query("select * from public.members where business_id = $1 and user_id = 'editor1'", [biz.businessId]);
    expect(added).toMatchObject({role: "editor", email: "editor1@example.com", display_name: "editor1", added_by: "admin1"});

    await admin.rpc("update_member_role", {p_business_id: biz.businessId, p_uid: "editor1", p_role: "viewer"});
    await expectFailure(
      admin.rpc("update_member_role", {p_business_id: biz.businessId, p_uid: "owner", p_role: "viewer"}),
      "failed-precondition");
    await expectFailure(
      admin.rpc("update_member_role", {p_business_id: biz.businessId, p_uid: "admin1", p_role: "viewer"}),
      "failed-precondition");
    await expectFailure(
      admin.rpc("update_member_role", {p_business_id: biz.businessId, p_uid: "editor1", p_role: "admin"}),
      "permission-denied");
    await editor.rpc("remove_member", {p_business_id: biz.businessId, p_uid: "editor1"});
    expect(await active()).toEqual(["owner", "admin1"]);
    // The removed member loses access at once.
    expect(await editor.query("select id from public.businesses where id = $1", [biz.businessId])).toHaveLength(0);
    await expectFailure(
      owner.rpc("remove_member", {p_business_id: biz.businessId, p_uid: "owner"}), "failed-precondition");

    await owner.rpc("update_member_role", {p_business_id: biz.businessId, p_uid: "admin1", p_role: "owner"});
    const [after] = await admin.query("select owner_id from public.businesses where id = $1", [biz.businessId]);
    expect(after.owner_id).toBe("admin1");
    const roles = await admin.query(
      "select user_id, role from public.members where business_id = $1 and deleted_at is null order by user_id",
      [biz.businessId]);
    expect(roles).toEqual([{user_id: "admin1", role: "owner"}, {user_id: "owner", role: "admin"}]);
    const audit = await admin.query(
      "select action from public.audit_log where business_id = $1 and entity = 'member' order by id", [biz.businessId]);
    expect(audit.map((r) => r.action)).toEqual(["add", "add", "changeRole", "leave", "transferOwnership"]);

    // A removed member can be added back.
    await admin.rpc("add_member", {p_business_id: biz.businessId, p_email: "editor1@example.com", p_role: "viewer"});
    expect(await editor.query("select id from public.businesses where id = $1", [biz.businessId])).toHaveLength(1);
  });
});
