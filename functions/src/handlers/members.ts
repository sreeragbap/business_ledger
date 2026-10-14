import {getAuth} from "firebase-admin/auth";
import {FieldValue} from "firebase-admin/firestore";
import {audit} from "../lib/audit";
import {handler} from "../lib/callable";
import {fail, notFound} from "../lib/errors";
import {db} from "../lib/firebase";
import {memberRef, rank, requireRole, Role} from "../lib/roles";
import * as s from "../schemas";

/** Admins manage editors and viewers; only the owner manages admins. */
function canManage(actor: Role, target: Role): boolean {
  return actor === "owner" || rank(actor) > rank(target);
}

export const addMember = handler("addMember", s.addMember, async (caller, data) => {
  const firestore = db();
  // Role first: a non-admin must not learn which emails have accounts.
  const actorSnap = await memberRef(firestore, data.businessId, caller.uid).get();
  const actorRole = actorSnap.get("role") as Role | undefined;
  if (!actorRole || rank(actorRole) < rank("admin")) {
    fail("permission-denied", "This needs the admin role or higher.", "role");
  }
  if (!canManage(actorRole, data.role)) fail("permission-denied", "Only the owner can add admins.", "role");

  let user;
  try {
    user = await getAuth().getUserByEmail(data.email.toLowerCase());
  } catch {
    fail("not-found", "No account uses that email yet. Ask them to sign in to the app once, then add them.", "notFound");
  }
  return firestore.runTransaction(async (tx) => {
    // Re-checked inside the transaction in case the role changed meanwhile.
    const actor = await requireRole(tx, firestore, data.businessId, caller.uid, "admin");
    if (!canManage(actor.role, data.role)) {
      fail("permission-denied", "Only the owner can add admins.", "role");
    }
    const ref = memberRef(firestore, data.businessId, user.uid);
    if ((await tx.get(ref)).exists) {
      fail("already-exists", "That person is already a member.", "validation");
    }
    tx.set(ref, {
      role: data.role,
      email: user.email ?? data.email,
      displayName: user.displayName ?? "",
      photoUrl: user.photoURL ?? "",
      addedBy: caller.uid,
      addedAt: FieldValue.serverTimestamp(),
    });
    tx.update(firestore.doc(`businesses/${data.businessId}`), {
      memberUids: FieldValue.arrayUnion(user.uid),
      updatedAt: FieldValue.serverTimestamp(),
    });
    audit(tx, firestore, data.businessId, {
      entity: "member", entityId: user.uid, action: "add", actor: caller.uid, after: {role: data.role},
    });
    return {uid: user.uid};
  });
});

export const updateMemberRole = handler("updateMemberRole", s.updateMemberRole, async (caller, data) => {
  const firestore = db();
  return firestore.runTransaction(async (tx) => {
    const actor = await requireRole(tx, firestore, data.businessId, caller.uid, "admin");
    const targetSnap = await tx.get(memberRef(firestore, data.businessId, data.uid));
    if (!targetSnap.exists) notFound("That member");
    const current = targetSnap.get("role") as Role;
    if (data.uid === caller.uid) fail("failed-precondition", "You cannot change your own role.", "role");
    if (current === "owner") fail("failed-precondition", "The owner's role changes only by a transfer.", "role");

    if (data.role === "owner") {
      // Transfer: the owner hands over and becomes an admin.
      if (actor.role !== "owner") fail("permission-denied", "Only the owner can transfer ownership.", "role");
      tx.update(memberRef(firestore, data.businessId, caller.uid), {role: "admin"});
      tx.update(firestore.doc(`businesses/${data.businessId}`), {
        ownerId: data.uid,
        updatedAt: FieldValue.serverTimestamp(),
      });
    } else if (!canManage(actor.role, current) || !canManage(actor.role, data.role)) {
      fail("permission-denied", "Only the owner can manage admins.", "role");
    }
    tx.update(targetSnap.ref, {role: data.role});
    audit(tx, firestore, data.businessId, {
      entity: "member", entityId: data.uid, action: data.role === "owner" ? "transferOwnership" : "changeRole",
      actor: caller.uid, before: {role: current}, after: {role: data.role},
    });
    return {uid: data.uid, role: data.role};
  });
});

export const removeMember = handler("removeMember", s.removeMember, async (caller, data) => {
  const firestore = db();
  return firestore.runTransaction(async (tx) => {
    const leaving = data.uid === caller.uid;
    const actor = await requireRole(tx, firestore, data.businessId, caller.uid, leaving ? "viewer" : "admin");
    const targetSnap = await tx.get(memberRef(firestore, data.businessId, data.uid));
    if (!targetSnap.exists) notFound("That member");
    const target = targetSnap.get("role") as Role;
    if (target === "owner") {
      fail("failed-precondition", "Transfer ownership before the owner leaves.", "role");
    }
    if (!leaving && !canManage(actor.role, target)) {
      fail("permission-denied", "Only the owner can remove admins.", "role");
    }
    tx.delete(targetSnap.ref);
    tx.update(firestore.doc(`businesses/${data.businessId}`), {
      memberUids: FieldValue.arrayRemove(data.uid),
      updatedAt: FieldValue.serverTimestamp(),
    });
    audit(tx, firestore, data.businessId, {
      entity: "member", entityId: data.uid, action: leaving ? "leave" : "remove",
      actor: caller.uid, before: {role: target},
    });
    return {uid: data.uid};
  });
});
