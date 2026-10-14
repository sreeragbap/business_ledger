import {DocumentData, DocumentReference, FieldValue, Firestore, Transaction} from "firebase-admin/firestore";
import {
  checkCancel, checkSettlement, checkTotalEdit, Direction, directionOf, lineAmount, apply as applySettlement,
  TYPE_INFO, TransactionType,
} from "../ledger";
import {audit, changedKeys} from "../lib/audit";
import {handler} from "../lib/callable";
import {dayTimestamp, isCalendarDate} from "../lib/dates";
import {conflict, fail, invalid, notFound, violation} from "../lib/errors";
import {db} from "../lib/firebase";
import {once} from "../lib/idempotency";
import {requireRole} from "../lib/roles";
import {cash, diff, writeStats} from "../lib/stats";
import {moneyFields, tokensFor, txState} from "../lib/transaction";
import * as s from "../schemas";

const txRef = (firestore: Firestore, businessId: string, transactionId: string) =>
  firestore.doc(`businesses/${businessId}/transactions/${transactionId}`);

async function loadTx(tx: Transaction, ref: DocumentReference, expectedVersion?: number): Promise<DocumentData> {
  const snap = await tx.get(ref);
  if (!snap.exists) notFound("That transaction");
  const data = snap.data()!;
  if (expectedVersion !== undefined && (data.version ?? 0) !== expectedVersion) conflict();
  return data;
}

interface LineItem {
  description: string;
  quantityMilli: number;
  rateMinor: number;
  amountMinor: number;
}

/** Totals come from rounded lines when there are lines; see §5 Rounding. */
function totalOf(data: DocumentData): number {
  const lines = (data.lineItems as LineItem[] | undefined) ?? [];
  if (lines.length === 0) return (data.totalMinor as number | undefined) ?? 0;
  let sum = 0;
  lines.forEach((line, index) => {
    if (!Number.isSafeInteger(line.quantityMilli) || line.quantityMilli <= 0) {
      invalid(`Line ${index + 1}: enter a quantity above zero.`, "lineItems");
    }
    if (!Number.isSafeInteger(line.rateMinor) || line.rateMinor < 0) {
      invalid(`Line ${index + 1}: enter a valid rate.`, "lineItems");
    }
    const amount = lineAmount(line.quantityMilli, line.rateMinor);
    if (line.amountMinor !== amount) invalid(`Line ${index + 1}: amount does not match quantity × rate.`, "lineItems");
    sum += amount;
  });
  return sum;
}

interface References {
  categoryName: string | null;
  partyName: string | null;
  projectName: string | null;
  requiredFieldIds: Map<string, string>;
}

/**
 * Reads the category, party and project an entry points at, checks the
 * category fits the direction, and returns fresh name snapshots. Names are
 * copied onto the transaction so history survives a rename or archive.
 */
async function readReferences(
  tx: Transaction,
  firestore: Firestore,
  businessId: string,
  data: DocumentData,
  direction: Direction | null,
): Promise<References> {
  const base = `businesses/${businessId}`;
  const type = data.type as TransactionType;
  const categoryRequired = type !== "payment";
  const refs = {
    category: data.categoryId ? firestore.doc(`${base}/categories/${data.categoryId}`) : null,
    party: data.partyId ? firestore.doc(`${base}/parties/${data.partyId}`) : null,
    project: data.projectId ? firestore.doc(`${base}/projects/${data.projectId}`) : null,
  };
  const [category, party, project] = await Promise.all(
    [refs.category, refs.party, refs.project].map((ref) => (ref ? tx.get(ref) : Promise.resolve(null))),
  );

  if (!category) {
    if (categoryRequired) invalid("Choose a category.", "categoryId");
  } else {
    if (!category.exists) invalid("That category no longer exists.", "categoryId");
    if (category.get("archived") === true) invalid("That category is archived. Choose another.", "categoryId");
    const kind = category.get("kind") as string;
    if ((kind === "income" && direction === "out") || (kind === "expense" && direction === "in")) {
      invalid(`"${category.get("name")}" is an ${kind} category.`, "categoryId");
    }
  }
  if (party && !party.exists) invalid("That customer or supplier no longer exists.", "partyId");
  if (project && !project.exists) invalid("That project no longer exists.", "projectId");

  const requiredFieldIds = new Map<string, string>();
  const fieldIds = (category?.get("fieldIds") as string[] | undefined) ?? [];
  if (fieldIds.length > 0) {
    const fields = await tx.getAll(...fieldIds.map((id) => firestore.doc(`${base}/fields/${id}`)));
    for (const field of fields) {
      if (field.exists && field.get("required") === true && field.get("archived") !== true) {
        requiredFieldIds.set(field.id, field.get("label") as string);
      }
    }
  }

  return {
    categoryName: category?.get("name") ?? null,
    partyName: party?.get("name") ?? null,
    projectName: project?.get("name") ?? null,
    requiredFieldIds,
  };
}

function checkRequiredFields(data: DocumentData, refs: References): void {
  const values = (data.customFields as Record<string, unknown> | undefined) ?? {};
  for (const [fieldId, label] of refs.requiredFieldIds) {
    const value = values[fieldId];
    if (value === undefined || value === null || value === "" || (Array.isArray(value) && value.length === 0)) {
      invalid(`${label} is required.`, `customFields.${fieldId}`);
    }
  }
}

function checkDates(data: DocumentData): void {
  if (typeof data.date !== "string" || !isCalendarDate(data.date)) invalid("Choose a date.", "date");
  if (data.dueDate != null) {
    if (typeof data.dueDate !== "string" || !isCalendarDate(data.dueDate)) invalid("Invalid due date.", "dueDate");
    if (data.dueDate < data.date) invalid("The due date cannot be before the transaction date.", "dueDate");
  }
}

/**
 * Validates a draft and makes it count. With [settleNow] (and always for a
 * payment entry) the full amount is settled in the same write: a cash
 * expense goes straight to Paid.
 */
export const confirmTransaction = handler("confirmTransaction", s.confirmTransaction, async (caller, data) => {
  const firestore = db();
  return once(firestore, caller.uid, data.requestId, "confirmTransaction", async (tx) => {
    await requireRole(tx, firestore, data.businessId, caller.uid, "admin");
    const ref = txRef(firestore, data.businessId, data.transactionId);
    const before = await loadTx(tx, ref, data.expectedVersion);
    if (before.status !== "draft") violation("draftOnly");

    const type = before.type as TransactionType;
    if (!TYPE_INFO[type]?.creatable) invalid("Choose a transaction type.", "type");
    const direction = directionOf(type, before.direction);
    if (!direction) invalid("Choose whether money is coming in or going out.", "direction");
    checkDates(before);
    const total = totalOf(before);
    const amountViolation = checkTotalEdit({total: 0, paid: 0, refunded: 0, credited: 0}, total);
    if (amountViolation) violation(amountViolation);

    const refs = await readReferences(tx, firestore, data.businessId, before, direction);
    checkRequiredFields(before, refs);

    const settleNow = type === "payment" || data.settleNow === true;
    const confirmedState = {...txState(before), status: "confirmed" as const, direction, balance: {total, paid: 0, refunded: 0, credited: 0}};
    const balance = settleNow ? applySettlement(confirmedState.balance, "payment", total) : confirmedState.balance;
    const after = {...confirmedState, balance};
    const version = (before.version ?? 0) + 1;
    const now = FieldValue.serverTimestamp();

    const update = {
      status: "confirmed",
      direction,
      categoryName: refs.categoryName,
      partyName: refs.partyName,
      projectName: refs.projectName,
      dateTs: dayTimestamp(before.date),
      dueDate: before.dueDate ?? null,
      ...moneyFields(type, "confirmed", balance),
      version,
      confirmedAt: now,
      confirmedBy: caller.uid,
      updatedAt: now,
    };
    tx.update(ref, {...update, searchTokens: tokensFor({...before, ...update})});

    let settlementId: string | null = null;
    const extra = [];
    if (settleNow) {
      const date = data.settleDate ?? before.date;
      settlementId = data.requestId;
      tx.set(ref.collection("settlements").doc(settlementId), {
        kind: "payment",
        amountMinor: total,
        date,
        dateTs: dayTimestamp(date),
        method: data.settleMethod ?? before.paymentMethod ?? "",
        note: "",
        balanceAfter: moneyFields(type, "confirmed", balance),
        createdBy: caller.uid,
        createdAt: now,
        voided: false,
      });
      extra.push(cash("payment", direction, total, date));
    }
    writeStats(tx, firestore, data.businessId, diff(null, after, ...extra));
    audit(tx, firestore, data.businessId, {
      entity: "transaction", entityId: data.transactionId, action: settleNow ? "confirmAndSettle" : "confirm",
      actor: caller.uid, after: {totalMinor: total, paymentStatus: update.paymentStatus},
    });
    return {transactionId: data.transactionId, version, paymentStatus: update.paymentStatus, settlementId};
  });
});

/**
 * Changes a confirmed entry. Type and direction are fixed once money has
 * been recorded against them; everything else may change, with stats
 * moved by the difference and the before/after kept in the audit log.
 */
export const editConfirmedTransaction = handler("editConfirmedTransaction", s.editConfirmed, async (caller, data) => {
  const firestore = db();
  return once(firestore, caller.uid, data.requestId, "editConfirmedTransaction", async (tx) => {
    await requireRole(tx, firestore, data.businessId, caller.uid, "admin");
    const ref = txRef(firestore, data.businessId, data.transactionId);
    const before = await loadTx(tx, ref, data.expectedVersion);
    if (before.status !== "confirmed") {
      fail("failed-precondition", "Only confirmed transactions can be edited this way.", "violation");
    }
    if (before.linkKind === "refund") {
      fail("failed-precondition", "A refund entry changes through its original transaction.", "violation");
    }

    const merged: DocumentData = {...before, ...data.changes};
    if (data.changes.lineItems && data.changes.lineItems.length === 0 && data.changes.totalMinor === undefined) {
      merged.totalMinor = before.totalMinor;
    }
    checkDates(merged);
    const type = before.type as TransactionType;
    const refs = await readReferences(tx, firestore, data.businessId, merged, before.direction);
    checkRequiredFields(merged, refs);

    const oldState = txState(before);
    const total = totalOf(merged);
    const totalViolation = checkTotalEdit(oldState.balance, total);
    if (totalViolation) violation(totalViolation);
    if (type === "payment" && total !== oldState.balance.total) {
      fail("failed-precondition", "A payment entry's amount cannot change. Cancel it and record a new one.", "violation");
    }

    const balance = {...oldState.balance, total};
    const newState = {
      ...oldState,
      date: merged.date,
      categoryId: merged.categoryId ?? null,
      projectId: merged.projectId ?? null,
      balance,
    };
    const version = oldState.version + 1;
    const update: DocumentData = {
      ...data.changes,
      categoryName: refs.categoryName,
      partyName: refs.partyName,
      projectName: refs.projectName,
      dateTs: dayTimestamp(merged.date),
      ...moneyFields(type, "confirmed", balance),
      version,
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: caller.uid,
    };
    update.searchTokens = tokensFor({...merged, ...update});
    tx.update(ref, update);

    writeStats(tx, firestore, data.businessId, diff(oldState, newState));
    const trackedKeys = [...Object.keys(data.changes), "totalMinor", "categoryName", "partyName", "projectName"];
    const pick = (src: DocumentData) => Object.fromEntries(trackedKeys.map((k) => [k, src[k] ?? null]));
    const changes = changedKeys(pick(before), pick({...merged, ...update}));
    audit(tx, firestore, data.businessId, {
      entity: "transaction", entityId: data.transactionId, action: "edit", actor: caller.uid, ...changes,
    });
    return {transactionId: data.transactionId, version, paymentStatus: update.paymentStatus as string};
  });
});

/**
 * Voids a confirmed entry. The record stays; it drops out of every active
 * figure and its documents are marked void. Money must be refunded first.
 */
export const cancelTransaction = handler("cancelTransaction", s.cancelTransaction, async (caller, data) => {
  const firestore = db();
  return once(firestore, caller.uid, data.requestId, "cancelTransaction", async (tx) => {
    await requireRole(tx, firestore, data.businessId, caller.uid, "admin");
    const ref = txRef(firestore, data.businessId, data.transactionId);
    const before = await loadTx(tx, ref, data.expectedVersion);
    if (before.status === "draft") {
      fail("failed-precondition", "Drafts are deleted, not cancelled.", "violation");
    }
    if (before.linkKind === "refund") {
      fail("failed-precondition", "A refund entry cannot be cancelled on its own.", "violation");
    }
    const oldState = txState(before);
    const cancelViolation = checkCancel(oldState.balance, oldState.status);
    if (cancelViolation) violation(cancelViolation);

    const documents = await tx.get(
      firestore.collection(`businesses/${data.businessId}/documents`).where("transactionId", "==", data.transactionId),
    );

    const version = oldState.version + 1;
    const type = before.type as TransactionType;
    const now = FieldValue.serverTimestamp();
    tx.update(ref, {
      status: "cancelled",
      ...moneyFields(type, "cancelled", oldState.balance),
      cancelReason: data.reason ?? "",
      cancelledAt: now,
      cancelledBy: caller.uid,
      updatedAt: now,
      version,
    });
    for (const doc of documents.docs) tx.update(doc.ref, {voided: true, voidedAt: now});

    writeStats(tx, firestore, data.businessId, diff(oldState, {...oldState, status: "cancelled"}));
    audit(tx, firestore, data.businessId, {
      entity: "transaction", entityId: data.transactionId, action: "cancel", actor: caller.uid,
      before: {status: "confirmed"}, after: {status: "cancelled"}, note: data.reason,
    });
    return {transactionId: data.transactionId, version, voidedDocuments: documents.size};
  });
});

/**
 * Records a payment, refund or credit. The requestId doubles as the
 * settlement id, so a retried call cannot create a second record, and the
 * balance is re-read inside the transaction, so two concurrent payments
 * cannot together exceed what is owed.
 */
export const recordSettlement = handler("recordSettlement", s.recordSettlement, async (caller, data) => {
  const firestore = db();
  return once(firestore, caller.uid, data.requestId, "recordSettlement", async (tx) => {
    await requireRole(tx, firestore, data.businessId, caller.uid, "admin");
    const ref = txRef(firestore, data.businessId, data.transactionId);
    const before = await loadTx(tx, ref, data.expectedVersion);
    const oldState = txState(before);
    const type = before.type as TransactionType;

    const settlementViolation = checkSettlement({
      kind: data.kind,
      balance: oldState.balance,
      amount: data.amountMinor,
      status: oldState.status,
      settleable: TYPE_INFO[type]?.settleable ?? false,
    });
    if (settlementViolation) violation(settlementViolation);
    const direction = oldState.direction!;

    const balance = applySettlement(oldState.balance, data.kind, data.amountMinor);
    const newState = {...oldState, balance};
    const fields = moneyFields(type, "confirmed", balance);
    const version = oldState.version + 1;
    const now = FieldValue.serverTimestamp();
    tx.update(ref, {...fields, version, updatedAt: now});

    const settlementId = data.requestId;
    let linkedTransactionId: string | null = null;
    if (data.kind === "refund") {
      // A visible ledger entry for the refund. Its money effect is carried
      // by the original (stats exclude it), so nothing counts twice.
      const linked = firestore.collection(`businesses/${data.businessId}/transactions`).doc();
      linkedTransactionId = linked.id;
      const entry: DocumentData = {
        type: "refund",
        direction: direction === "in" ? "out" : "in",
        status: "confirmed",
        description: `Refund · ${before.description || before.categoryName || "transaction"}`,
        reference: before.reference ?? "",
        notes: data.note ?? "",
        paymentMethod: data.method ?? "",
        categoryId: before.categoryId ?? null,
        categoryName: before.categoryName ?? null,
        partyId: before.partyId ?? null,
        partyName: before.partyName ?? null,
        projectId: before.projectId ?? null,
        projectName: before.projectName ?? null,
        date: data.date,
        dateTs: dayTimestamp(data.date),
        dueDate: null,
        lineItems: [],
        ...moneyFields("refund", "confirmed", {total: data.amountMinor, paid: 0, refunded: 0, credited: 0}),
        customFields: {},
        attachments: [],
        linkedTransactionId: data.transactionId,
        linkKind: "refund",
        settlementId,
        version: 1,
        createdBy: caller.uid,
        createdAt: now,
        updatedAt: now,
        confirmedAt: now,
        confirmedBy: caller.uid,
      };
      entry.searchTokens = tokensFor(entry);
      tx.set(linked, entry);
    }

    tx.set(ref.collection("settlements").doc(settlementId), {
      kind: data.kind,
      amountMinor: data.amountMinor,
      date: data.date,
      dateTs: dayTimestamp(data.date),
      method: data.method ?? "",
      note: data.note ?? "",
      balanceAfter: fields,
      linkedTransactionId,
      createdBy: caller.uid,
      createdAt: now,
      voided: false,
    });

    writeStats(tx, firestore, data.businessId, diff(oldState, newState, cash(data.kind, direction, data.amountMinor, data.date)));
    audit(tx, firestore, data.businessId, {
      entity: "settlement", entityId: settlementId, action: data.kind, actor: caller.uid,
      before: {outstandingMinor: moneyFields(type, "confirmed", oldState.balance).outstandingMinor},
      after: {amountMinor: data.amountMinor, outstandingMinor: fields.outstandingMinor, transactionId: data.transactionId},
    });
    return {
      settlementId,
      transactionId: data.transactionId,
      linkedTransactionId,
      version,
      paymentStatus: fields.paymentStatus,
      outstandingMinor: fields.outstandingMinor,
    };
  });
});
