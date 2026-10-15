import {DocumentReference, Firestore, Transaction} from "firebase-admin/firestore";
import {fail} from "./errors";

export const ROLES = ["viewer", "editor", "admin", "owner"] as const;
export type Role = (typeof ROLES)[number];

export const rank = (role: Role): number => ROLES.indexOf(role);

export interface Member {
  uid: string;
  role: Role;
}

export const memberRef = (db: Firestore, businessId: string, uid: string): DocumentReference =>
  db.doc(`businesses/${businessId}/members/${uid}`);

/**
 * Rules do not apply to the Admin SDK, so every callable re-checks
 * membership here, inside the same transaction as its writes.
 */
export async function requireRole(
  tx: Transaction,
  db: Firestore,
  businessId: string,
  uid: string,
  min: Role,
): Promise<Member> {
  const snap = await tx.get(memberRef(db, businessId, uid));
  if (!snap.exists) {
    // Same answer as a missing business: do not reveal which exists.
    fail("permission-denied", "You do not have access to this business.", "notMember");
  }
  const role = snap.get("role") as Role;
  if (rank(role) < rank(min)) {
    fail("permission-denied", `This needs the ${min} role or higher.`, "role", {required: min});
  }
  return {uid, role};
}
