import {FieldValue, Firestore, Transaction} from "firebase-admin/firestore";
import {fail} from "./errors";

/**
 * Runs [body] in a Firestore transaction at most once per
 * (user, requestId). A retry after a timeout gets the stored result back
 * instead of applying the operation again.
 *
 * [body] must do all its reads before its first write (a Firestore
 * transaction rule); the request record is written after it.
 */
export async function once<T>(
  db: Firestore,
  uid: string,
  requestId: string,
  op: string,
  body: (tx: Transaction) => Promise<T>,
): Promise<T> {
  const ref = db.collection("requests").doc(`${uid}_${requestId}`);
  return db.runTransaction(async (tx) => {
    const prior = await tx.get(ref);
    if (prior.exists) {
      if (prior.get("op") !== op) {
        fail("already-exists", "This request id was already used for another action.", "requestReused");
      }
      return prior.get("result") as T;
    }
    const result = await body(tx);
    tx.set(ref, {uid, op, result: result ?? null, createdAt: FieldValue.serverTimestamp()});
    return result;
  });
}
