import {FieldValue, Firestore, Transaction} from "firebase-admin/firestore";

export interface AuditEntry {
  entity: "business" | "member" | "transaction" | "settlement" | "category" | "document";
  entityId: string;
  action: string;
  actor: string;
  before?: Record<string, unknown> | null;
  after?: Record<string, unknown> | null;
  note?: string;
}

export function audit(tx: Transaction, db: Firestore, businessId: string, entry: AuditEntry): void {
  tx.set(db.collection(`businesses/${businessId}/audit`).doc(), {
    ...entry,
    before: entry.before ?? null,
    after: entry.after ?? null,
    at: FieldValue.serverTimestamp(),
  });
}

/** Only the keys whose values differ, for a compact before/after pair. */
export function changedKeys(
  before: Record<string, unknown>,
  after: Record<string, unknown>,
): {before: Record<string, unknown>; after: Record<string, unknown>} {
  const b: Record<string, unknown> = {};
  const a: Record<string, unknown> = {};
  for (const key of new Set([...Object.keys(before), ...Object.keys(after)])) {
    if (JSON.stringify(before[key]) !== JSON.stringify(after[key])) {
      b[key] = before[key] ?? null;
      a[key] = after[key] ?? null;
    }
  }
  return {before: b, after: a};
}
