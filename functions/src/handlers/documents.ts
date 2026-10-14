import {DocumentData, FieldValue} from "firebase-admin/firestore";
import {TransactionType, TYPE_INFO} from "../ledger";
import {audit} from "../lib/audit";
import {handler} from "../lib/callable";
import {todayIn} from "../lib/dates";
import {fail, notFound} from "../lib/errors";
import {db} from "../lib/firebase";
import {once} from "../lib/idempotency";
import {requireRole} from "../lib/roles";
import * as s from "../schemas";

const PREFIX_KEY = {invoice: "invoicePrefix", bill: "billPrefix", receipt: "receiptPrefix"} as const;

/**
 * Issues an invoice, bill or receipt with a gap-free `PREFIX-YYYY-NNNN`
 * number. The document id is derived from what it documents, so asking
 * twice returns the same document and never burns a second number.
 */
export const issueDocument = handler("issueDocument", s.issueDocument, async (caller, data) => {
  const firestore = db();
  return once(firestore, caller.uid, data.requestId, "issueDocument", async (tx) => {
    await requireRole(tx, firestore, data.businessId, caller.uid, "editor");
    const base = `businesses/${data.businessId}`;
    const documentId = `${data.type}-${data.transactionId}-${data.settlementId ?? "main"}`;
    const documentRef = firestore.doc(`${base}/documents/${documentId}`);
    const txRef = firestore.doc(`${base}/transactions/${data.transactionId}`);
    const counterRef = firestore.doc(`${base}/counters/${data.type}`);

    const [existing, txSnap, businessSnap, counter] = await tx.getAll(
      documentRef, txRef, firestore.doc(base), counterRef,
    );
    if (existing.exists && existing.get("voided") !== true) {
      return {documentId, number: existing.get("number") as string, created: false};
    }
    if (!txSnap.exists) notFound("That transaction");
    const t = txSnap.data()!;
    if (t.status === "cancelled") {
      fail("failed-precondition", "Cancelled transactions cannot issue documents.", "violation");
    }
    if (t.status !== "confirmed") {
      fail("failed-precondition", "Confirm the transaction before issuing a document.", "violation");
    }

    let settlement: DocumentData | null = null;
    if (data.type === "receipt") {
      if (!data.settlementId) fail("invalid-argument", "Choose the payment to issue a receipt for.", "validation");
      const settlementSnap = await tx.get(txRef.collection("settlements").doc(data.settlementId));
      if (!settlementSnap.exists) notFound("That payment");
      settlement = settlementSnap.data()!;
      if (settlement.kind !== "payment" || settlement.voided === true) {
        fail("failed-precondition", "Receipts are issued for recorded payments only.", "violation");
      }
    } else if (TYPE_INFO[t.type as TransactionType]?.documentType !== data.type) {
      fail("failed-precondition", `A ${t.type} does not produce a ${data.type}.`, "violation");
    }

    const party = t.partyId ? await tx.get(firestore.doc(`${base}/parties/${t.partyId}`)) : null;

    const business = businessSnap.data()!;
    const settings = (business.settings ?? {}) as Record<string, string>;
    const year = Number(todayIn(business.timezone ?? "UTC").slice(0, 4));
    const next = counter.exists && counter.get("year") === year ? (counter.get("next") as number) : 1;
    const prefix = (settings[PREFIX_KEY[data.type]] || data.type.toUpperCase()).trim();
    const number = `${prefix}-${year}-${String(next).padStart(4, "0")}`;

    const snapshot = {
      business: {
        name: business.name, address: settings.address ?? "", phone: settings.phone ?? "",
        email: settings.email ?? "", taxId: settings.taxId ?? "", currency: business.currency,
      },
      party: party?.exists ? {
        name: party.get("name") ?? "", address: party.get("address") ?? "",
        phone: party.get("phone") ?? "", email: party.get("email") ?? "",
      } : t.partyName ? {name: t.partyName, address: "", phone: "", email: ""} : null,
      transaction: {
        type: t.type, direction: t.direction, description: t.description ?? "", reference: t.reference ?? "",
        date: t.date, dueDate: t.dueDate ?? null, categoryName: t.categoryName ?? null,
        projectName: t.projectName ?? null, paymentMethod: t.paymentMethod ?? "", notes: t.notes ?? "",
        lineItems: t.lineItems ?? [],
        totalMinor: t.totalMinor, creditedMinor: t.creditedMinor ?? 0, paidMinor: t.paidMinor ?? 0,
        refundedMinor: t.refundedMinor ?? 0, outstandingMinor: t.outstandingMinor ?? 0,
        paymentStatus: t.paymentStatus,
      },
      // For a receipt, the balance as it stood right after this payment:
      // a receipt for an early instalment must not show later ones.
      settlement: settlement ? {
        amountMinor: settlement.amountMinor, date: settlement.date, method: settlement.method ?? "",
        note: settlement.note ?? "", paidToDateMinor: settlement.balanceAfter?.paidMinor ?? null,
        remainingMinor: settlement.balanceAfter?.outstandingMinor ?? null,
      } : null,
    };

    tx.set(counterRef, {year, next: next + 1});
    tx.set(documentRef, {
      type: data.type,
      number,
      transactionId: data.transactionId,
      settlementId: data.settlementId ?? null,
      snapshot,
      issuedAt: FieldValue.serverTimestamp(),
      issuedBy: caller.uid,
      voided: false,
      storagePath: null,
    });
    audit(tx, firestore, data.businessId, {
      entity: "document", entityId: documentId, action: "issue", actor: caller.uid,
      after: {number, transactionId: data.transactionId},
    });
    return {documentId, number, created: true};
  });
});
