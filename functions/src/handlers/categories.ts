import {audit} from "../lib/audit";
import {handler} from "../lib/callable";
import {fail, notFound} from "../lib/errors";
import {db} from "../lib/firebase";
import {requireRole} from "../lib/roles";
import * as s from "../schemas";

/**
 * Deletes a category only when no transaction (in any status) points at
 * it. Otherwise the answer is "archive": history keeps its name snapshot.
 */
export const deleteCategory = handler("deleteCategory", s.deleteCategory, async (caller, data) => {
  const firestore = db();
  return firestore.runTransaction(async (tx) => {
    await requireRole(tx, firestore, data.businessId, caller.uid, "editor");
    const ref = firestore.doc(`businesses/${data.businessId}/categories/${data.categoryId}`);
    const category = await tx.get(ref);
    if (!category.exists) notFound("That category");
    const used = await tx.get(
      firestore.collection(`businesses/${data.businessId}/transactions`)
        .where("categoryId", "==", data.categoryId).limit(1),
    );
    if (!used.empty) {
      fail("failed-precondition", "Transactions use this category, so it cannot be deleted. Archive it instead.", "inUse");
    }
    tx.delete(ref);
    audit(tx, firestore, data.businessId, {
      entity: "category", entityId: data.categoryId, action: "delete", actor: caller.uid,
      before: {name: category.get("name")},
    });
    return {categoryId: data.categoryId};
  });
});
