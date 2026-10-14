import {beforeAll, beforeEach, describe, expect, it} from "vitest";
import {deleteCategory} from "../../src/handlers/categories";
import {issueDocument} from "../../src/handlers/documents";
import {addMember, removeMember, updateMemberRole} from "../../src/handlers/members";
import {
  cancelTransaction, confirmTransaction, editConfirmedTransaction, recordSettlement,
} from "../../src/handlers/transactions";
import {Caller} from "../../src/lib/callable";
import {db} from "../../src/lib/firebase";
import {
  addRole, call, clearFirestore, draft, expectFailure, Fixture, newBusiness, rid, stats, tx, user,
} from "./helpers";

let owner: Caller;
let stranger: Caller;
let biz: Fixture;

beforeAll(async () => {
  owner = await user("owner");
  stranger = await user("stranger");
});

beforeEach(async () => {
  await clearFirestore();
  biz = await newBusiness(owner);
});

const confirm = (id: string, extra: Record<string, unknown> = {}) =>
  call(confirmTransaction, owner, {businessId: biz.businessId, transactionId: id, requestId: rid(), ...extra});

const settle = (id: string, kind: string, amountMinor: number, extra: Record<string, unknown> = {}) =>
  call(recordSettlement, owner, {
    businessId: biz.businessId, transactionId: id, requestId: rid(), kind, amountMinor, date: "2026-10-05", ...extra,
  });

const sale = (fields: Record<string, unknown> = {}) =>
  draft(biz.businessId, owner.uid, {categoryId: biz.categories["Product sales"], ...fields});

describe("businesses", () => {
  it("seeds the template and keeps businesses separate", async () => {
    const other = await newBusiness(owner, "construction");
    expect(Object.keys(biz.categories)).toContain("Stock purchases");
    expect(Object.keys(other.categories)).toEqual(expect.arrayContaining(["Materials", "Labour", "Transport"]));
    expect(other.businessId).not.toBe(biz.businessId);
    const business = (await db().doc(`businesses/${biz.businessId}`).get()).data()!;
    expect(business.memberUids).toEqual([owner.uid]);
    expect(business.currency).toEqual({code: "INR", decimals: 2, symbol: "₹"});
    const member = await db().doc(`businesses/${biz.businessId}/members/${owner.uid}`).get();
    expect(member.get("role")).toBe("owner");
  });

  it("refuses financial calls from non-members and viewers", async () => {
    const id = await sale();
    await expectFailure(
      call(confirmTransaction, stranger, {businessId: biz.businessId, transactionId: id, requestId: rid()}),
      "permission-denied",
    );
    const viewer = await user("viewer");
    await addRole(biz.businessId, viewer.uid, "viewer");
    await expectFailure(
      call(confirmTransaction, viewer, {businessId: biz.businessId, transactionId: id, requestId: rid()}),
      "permission-denied",
    );
    expect((await tx(biz.businessId, id)).status).toBe("draft");
  });
});

describe("confirm", () => {
  it("validates required fields before confirming", async () => {
    const missingCategory = await draft(biz.businessId, owner.uid, {categoryId: null});
    const e = await expectFailure(confirm(missingCategory), "invalid-argument");
    expect((e.details as {field: string}).field).toBe("categoryId");

    const wrongKind = await sale({categoryId: biz.categories["Rent"]});
    await expectFailure(confirm(wrongKind), "invalid-argument");

    const badLines = await sale({lineItems: [{description: "x", quantityMilli: 2500, rateMinor: 333, amountMinor: 832}]});
    await expectFailure(confirm(badLines), "invalid-argument");
  });

  it("drafts never count; confirming adds income by transaction date", async () => {
    await sale({totalMinor: 99999});
    expect(await stats(biz.businessId, "2026-10-01")).toEqual({});

    const id = await sale({
      totalMinor: 0,
      lineItems: [{description: "Bag", quantityMilli: 2500, rateMinor: 333, amountMinor: 833}],
      dueDate: "2026-10-31",
    });
    const result = await confirm(id);
    expect(result.paymentStatus).toBe("unpaid");
    const t = await tx(biz.businessId, id);
    expect(t).toMatchObject({status: "confirmed", direction: "in", totalMinor: 833, outstandingMinor: 833, isOpen: true});
    expect(t.categoryName).toBe("Product sales");
    expect(t.searchTokens).toContain("tes");
    const s = await stats(biz.businessId, "2026-10-01");
    expect(s.incomeMinor).toBe(833);
    expect(s.cashInMinor).toBeUndefined();
    expect(s.byCategory[biz.categories["Product sales"]].in).toBe(833);

    await expectFailure(confirm(id), "failed-precondition", "draftOnly");
  });

  it("settleNow confirms a cash expense as Paid in one step", async () => {
    const id = await draft(biz.businessId, owner.uid, {type: "expense", categoryId: biz.categories["Rent"], totalMinor: 5000});
    const result = await confirm(id, {settleNow: true, settleDate: "2026-10-02", settleMethod: "cash"});
    expect(result.paymentStatus).toBe("paid");
    const s1 = await stats(biz.businessId, "2026-10-01");
    const s2 = await stats(biz.businessId, "2026-10-02");
    expect(s1.expenseMinor).toBe(5000);
    expect(s2.cashOutMinor).toBe(5000);
    const settlements = await db().collection(`businesses/${biz.businessId}/transactions/${id}/settlements`).get();
    expect(settlements.size).toBe(1);
  });
});

describe("settlements", () => {
  it("partial payments move the balance to Paid, and overpayment is refused", async () => {
    const id = await sale();
    await confirm(id);
    expect((await settle(id, "payment", 4000)).paymentStatus).toBe("partiallyPaid");
    await expectFailure(settle(id, "payment", 6001), "failed-precondition", "overpayment");
    const done = await settle(id, "payment", 6000);
    expect(done).toMatchObject({paymentStatus: "paid", outstandingMinor: 0});
    const t = await tx(biz.businessId, id);
    expect(t.isOpen).toBe(false);
    expect((await stats(biz.businessId, "2026-10-05")).cashInMinor).toBe(10000);
    expect((await stats(biz.businessId, "2026-10-01")).incomeMinor).toBe(10000);
  });

  it("a retried request applies once", async () => {
    const id = await sale();
    await confirm(id);
    const requestId = rid("dup");
    const first = await settle(id, "payment", 3000, {requestId});
    const second = await settle(id, "payment", 3000, {requestId});
    expect(second).toEqual(first);
    expect((await tx(biz.businessId, id)).paidMinor).toBe(3000);
    const settlements = await db().collection(`businesses/${biz.businessId}/transactions/${id}/settlements`).get();
    expect(settlements.size).toBe(1);
  });

  it("concurrent payments cannot together exceed the balance", async () => {
    const id = await sale();
    await confirm(id);
    const results = await Promise.allSettled([settle(id, "payment", 6000), settle(id, "payment", 6000)]);
    expect(results.filter((r) => r.status === "fulfilled")).toHaveLength(1);
    const t = await tx(biz.businessId, id);
    expect(t.paidMinor).toBe(6000);
    expect(t.outstandingMinor).toBe(4000);
  });

  it("refunds keep the original, add a linked entry and reduce income once", async () => {
    const id = await sale();
    await confirm(id);
    await settle(id, "payment", 10000);
    const refund = await settle(id, "refund", 3000, {date: "2026-10-07"});
    expect(refund.paymentStatus).toBe("partiallyRefunded");
    const original = await tx(biz.businessId, id);
    expect(original).toMatchObject({status: "confirmed", refundedMinor: 3000, outstandingMinor: 0, effectiveMinor: 7000});
    const linked = await tx(biz.businessId, refund.linkedTransactionId!);
    expect(linked).toMatchObject({type: "refund", linkedTransactionId: id, totalMinor: 3000, direction: "out"});
    expect((await stats(biz.businessId, "2026-10-01")).incomeMinor).toBe(7000);
    expect((await stats(biz.businessId, "2026-10-07")).cashOutMinor).toBe(3000);
    await expectFailure(settle(id, "refund", 7001), "failed-precondition", "overRefund");
  });

  it("credits close the balance without cash", async () => {
    const id = await sale();
    await confirm(id);
    await settle(id, "payment", 9500);
    expect((await settle(id, "credit", 500)).paymentStatus).toBe("paid");
    expect((await stats(biz.businessId, "2026-10-01")).incomeMinor).toBe(9500);
    expect((await stats(biz.businessId, "2026-10-05")).cashInMinor).toBe(9500);
  });

  it("drafts and non-settleable entries take no settlements", async () => {
    const d = await sale();
    await expectFailure(settle(d, "payment", 100), "failed-precondition", "notConfirmed");
    const adj = await draft(biz.businessId, owner.uid, {type: "adjustment", direction: "out", categoryId: biz.categories["Rent"]});
    await confirm(adj);
    await expectFailure(settle(adj, "payment", 100), "failed-precondition", "notSettleable");
  });
});

describe("edit and cancel", () => {
  it("edits move stats by the difference and reject stale versions", async () => {
    const id = await sale();
    const {version} = await confirm(id);
    await settle(id, "payment", 4000);
    await expectFailure(
      call(editConfirmedTransaction, owner, {
        businessId: biz.businessId, transactionId: id, requestId: rid(), expectedVersion: version,
        changes: {totalMinor: 12000},
      }),
      "aborted",
    );
    const current = (await tx(biz.businessId, id)).version;
    await expectFailure(
      call(editConfirmedTransaction, owner, {
        businessId: biz.businessId, transactionId: id, requestId: rid(), expectedVersion: current,
        changes: {totalMinor: 3999},
      }),
      "failed-precondition", "totalBelowSettled",
    );
    await call(editConfirmedTransaction, owner, {
      businessId: biz.businessId, transactionId: id, requestId: rid(), expectedVersion: current,
      changes: {totalMinor: 12000, date: "2026-10-03", description: "Renamed"},
    });
    expect((await stats(biz.businessId, "2026-10-01")).incomeMinor ?? 0).toBe(0);
    expect((await stats(biz.businessId, "2026-10-03")).incomeMinor).toBe(12000);
    const t = await tx(biz.businessId, id);
    expect(t).toMatchObject({outstandingMinor: 8000, paymentStatus: "partiallyPaid"});
    const audit = await db().collection(`businesses/${biz.businessId}/audit`).where("entityId", "==", id).where("action", "==", "edit").get();
    expect(audit.docs[0].get("before")).toMatchObject({totalMinor: 10000, date: "2026-10-01"});
  });

  it("cancel needs refunds first, keeps the record and voids documents", async () => {
    const id = await sale();
    await confirm(id);
    await settle(id, "payment", 2000);
    const cancel = () => call(cancelTransaction, owner, {businessId: biz.businessId, transactionId: id, requestId: rid()});
    await expectFailure(cancel(), "failed-precondition", "cancelWithMoney");
    const doc = await call(issueDocument, owner, {businessId: biz.businessId, transactionId: id, type: "invoice", requestId: rid()});
    await settle(id, "refund", 2000);
    await cancel();
    const t = await tx(biz.businessId, id);
    expect(t).toMatchObject({status: "cancelled", isOpen: false});
    expect((await stats(biz.businessId, "2026-10-01")).incomeMinor ?? 0).toBe(0);
    const issued = await db().doc(`businesses/${biz.businessId}/documents/${doc.documentId}`).get();
    expect(issued.get("voided")).toBe(true);
    await expectFailure(
      call(issueDocument, owner, {businessId: biz.businessId, transactionId: id, type: "invoice", requestId: rid()}),
      "failed-precondition",
    );
  });
});

describe("documents", () => {
  it("numbers are sequential, unique and stable per subject", async () => {
    const a = await sale();
    const b = await sale();
    await confirm(a);
    await confirm(b);
    const issue = (id: string) =>
      call(issueDocument, owner, {businessId: biz.businessId, transactionId: id, type: "invoice", requestId: rid()});
    const first = await issue(a);
    const again = await issue(a);
    const second = await issue(b);
    const year = new Date().getFullYear();
    expect(first.number).toBe(`INV-${year}-0001`);
    expect(again).toMatchObject({number: first.number, created: false});
    expect(second.number).toBe(`INV-${year}-0002`);
    await expectFailure(
      call(issueDocument, owner, {businessId: biz.businessId, transactionId: a, type: "bill", requestId: rid()}),
      "failed-precondition",
    );
  });

  it("a receipt shows the balance as of its payment", async () => {
    const id = await sale();
    await confirm(id);
    const p1 = await settle(id, "payment", 4000);
    await settle(id, "payment", 1000);
    const receipt = await call(issueDocument, owner, {
      businessId: biz.businessId, transactionId: id, settlementId: p1.settlementId, type: "receipt", requestId: rid(),
    });
    const snap = (await db().doc(`businesses/${biz.businessId}/documents/${receipt.documentId}`).get()).get("snapshot");
    expect(snap.settlement).toMatchObject({amountMinor: 4000, paidToDateMinor: 4000, remainingMinor: 6000});
  });
});

describe("categories and members", () => {
  it("a used category cannot be deleted; an unused one can", async () => {
    const used = biz.categories["Product sales"];
    await sale({categoryId: used});
    await expectFailure(call(deleteCategory, owner, {businessId: biz.businessId, categoryId: used}), "failed-precondition");
    await call(deleteCategory, owner, {businessId: biz.businessId, categoryId: biz.categories["Utilities"]});
    expect((await db().doc(`businesses/${biz.businessId}/categories/${biz.categories["Utilities"]}`).get()).exists).toBe(false);
  });

  it("members are added, re-roled and removed with role limits", async () => {
    const admin = await user("admin1");
    const editor = await user("editor1");
    await call(addMember, owner, {businessId: biz.businessId, email: admin.email, role: "admin"});
    await call(addMember, admin, {businessId: biz.businessId, email: editor.email, role: "editor"});
    await expectFailure(
      call(addMember, admin, {businessId: biz.businessId, email: stranger.email, role: "admin"}), "permission-denied",
    );
    await expectFailure(
      call(addMember, owner, {businessId: biz.businessId, email: "nobody@example.com", role: "viewer"}), "not-found",
    );
    await call(updateMemberRole, admin, {businessId: biz.businessId, uid: editor.uid, role: "viewer"});
    await expectFailure(
      call(updateMemberRole, admin, {businessId: biz.businessId, uid: owner.uid, role: "viewer"}), "failed-precondition",
    );
    await call(removeMember, editor, {businessId: biz.businessId, uid: editor.uid});
    const business = (await db().doc(`businesses/${biz.businessId}`).get()).data()!;
    expect(business.memberUids).toEqual([owner.uid, admin.uid]);

    await call(updateMemberRole, owner, {businessId: biz.businessId, uid: admin.uid, role: "owner"});
    const after = (await db().doc(`businesses/${biz.businessId}`).get()).data()!;
    expect(after.ownerId).toBe(admin.uid);
  });
});
