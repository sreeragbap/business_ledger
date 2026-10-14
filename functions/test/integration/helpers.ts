import {getAuth} from "firebase-admin/auth";
import {FieldValue} from "firebase-admin/firestore";
import {HttpsError} from "firebase-functions/https";
import {expect} from "vitest";
import {z} from "zod";
import {createBusiness} from "../../src/handlers/business";
import {Caller, Handler, invoke} from "../../src/lib/callable";
import {db} from "../../src/lib/firebase";

export const projectId = process.env.GCLOUD_PROJECT ?? "demo-business-ledger";

let counter = 0;
export const rid = (label = "r"): string => `${label}${Date.now().toString(36)}${(counter++).toString(36)}xx`;

export async function clearFirestore(): Promise<void> {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  if (!host) throw new Error("Run through `npm run test:emulator`.");
  await fetch(`http://${host}/emulator/v1/projects/${projectId}/databases/(default)/documents`, {method: "DELETE"});
}

export const call = <S extends z.ZodType, R>(h: Handler<S, R>, caller: Caller, data: unknown) =>
  invoke(h, caller, data);

/** Asserts the call fails with [code] and, optionally, a violation key. */
export async function expectFailure(promise: Promise<unknown>, code: string, violation?: string) {
  try {
    await promise;
  } catch (error) {
    expect(error).toBeInstanceOf(HttpsError);
    const e = error as HttpsError;
    expect(e.code, e.message).toBe(code);
    if (violation) expect((e.details as {violation?: string}).violation).toBe(violation);
    return e;
  }
  throw new Error(`Expected ${code}, but the call succeeded.`);
}

export async function user(uid: string, email = `${uid}@example.com`): Promise<Caller> {
  try {
    await getAuth().createUser({uid, email, displayName: uid});
  } catch {
    // Already created by an earlier test.
  }
  return {uid, email, name: uid};
}

export interface Fixture {
  businessId: string;
  categories: Record<string, string>;
}

export async function newBusiness(owner: Caller, template = "retail"): Promise<Fixture> {
  const {businessId} = await call(createBusiness, owner, {
    requestId: rid("biz"), name: `Biz ${owner.uid}`, currencyCode: "INR", timezone: "Asia/Kolkata", template,
  });
  const snap = await db().collection(`businesses/${businessId}/categories`).get();
  const categories = Object.fromEntries(snap.docs.map((d) => [d.get("name") as string, d.id]));
  return {businessId, categories};
}

export async function addRole(businessId: string, uid: string, role: string): Promise<void> {
  await db().doc(`businesses/${businessId}/members/${uid}`).set({role});
  await db().doc(`businesses/${businessId}`).update({memberUids: FieldValue.arrayUnion(uid)});
}

/** A draft as the client would write it. */
export async function draft(
  businessId: string,
  createdBy: string,
  fields: Record<string, unknown>,
): Promise<string> {
  const ref = db().collection(`businesses/${businessId}/transactions`).doc();
  await ref.set({
    status: "draft",
    type: "sale",
    description: "Test entry",
    date: "2026-10-01",
    dueDate: null,
    totalMinor: 10000,
    lineItems: [],
    customFields: {},
    attachments: [],
    createdBy,
    version: 0,
    ...fields,
  });
  return ref.id;
}

export async function tx(businessId: string, id: string) {
  return (await db().doc(`businesses/${businessId}/transactions/${id}`).get()).data()!;
}

export async function stats(businessId: string, date: string) {
  return (await db().doc(`businesses/${businessId}/stats/${date}`).get()).data() ?? {};
}
