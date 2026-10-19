import {
  assertFails, assertSucceeds, initializeTestEnvironment, RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import {
  collection, doc, getDoc, getDocs, query, setDoc, updateDoc, deleteDoc, where,
} from "firebase/firestore";
import {readFileSync} from "node:fs";
import {join} from "node:path";
import {afterAll, beforeAll, beforeEach, describe, it} from "vitest";

let env: RulesTestEnvironment;
const B = "biz1";
const OTHER = "biz2";

const draft = (extra: Record<string, unknown> = {}) => ({
  status: "draft", type: "sale", description: "Bricks", date: "2026-10-01", totalMinor: 1000,
  lineItems: [], createdBy: "editor", ...extra,
});

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: process.env.GCLOUD_PROJECT ?? "demo-business-ledger",
    firestore: {rules: readFileSync(join(__dirname, "../../../firestore.rules"), "utf8")},
  });
});

afterAll(async () => env?.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    for (const [bid, members] of [[B, {owner: "owner", admin: "admin", editor: "editor", viewer: "viewer"}], [OTHER, {owner: "outsider"}]] as const) {
      await setDoc(doc(db, `businesses/${bid}`), {
        name: bid, currency: {code: "INR", decimals: 2, symbol: "₹"}, ownerId: Object.keys(members)[0],
        memberUids: Object.keys(members), settings: {}, archived: false,
      });
      for (const [uid, role] of Object.entries(members)) {
        await setDoc(doc(db, `businesses/${bid}/members/${uid}`), {role});
      }
    }
    await setDoc(doc(db, `businesses/${B}/transactions/confirmed1`), {...draft(), status: "confirmed", paidMinor: 0});
    await setDoc(doc(db, `businesses/${B}/transactions/draft1`), draft());
    await setDoc(doc(db, `businesses/${B}/stats/2026-10-01`), {incomeMinor: 1000});
  });
});

const as = (uid: string) => env.authenticatedContext(uid).firestore();

describe("business isolation", () => {
  it("members read their business; others and anonymous users cannot", async () => {
    await assertSucceeds(getDoc(doc(as("viewer"), `businesses/${B}`)));
    await assertSucceeds(getDoc(doc(as("viewer"), `businesses/${B}/transactions/confirmed1`)));
    await assertFails(getDoc(doc(as("outsider"), `businesses/${B}`)));
    await assertFails(getDoc(doc(as("outsider"), `businesses/${B}/transactions/confirmed1`)));
    await assertFails(getDoc(doc(as("outsider"), `businesses/${B}/stats/2026-10-01`)));
    await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), `businesses/${B}`)));
  });

  it("listing businesses works only when scoped to the caller", async () => {
    const db = as("editor");
    await assertSucceeds(getDocs(query(collection(db, "businesses"), where("memberUids", "array-contains", "editor"))));
    await assertFails(getDocs(collection(db, "businesses")));
  });

  it("nobody creates a business or membership from the client", async () => {
    await assertFails(setDoc(doc(as("editor"), "businesses/new"), {name: "x", memberUids: ["editor"]}));
    await assertFails(setDoc(doc(as("owner"), `businesses/${B}/members/someone`), {role: "admin"}));
    await assertFails(updateDoc(doc(as("editor"), `businesses/${B}/members/editor`), {role: "owner"}));
  });

  it("admins edit details but never currency or membership lists", async () => {
    await assertSucceeds(updateDoc(doc(as("admin"), `businesses/${B}`), {name: "Renamed"}));
    await assertFails(updateDoc(doc(as("editor"), `businesses/${B}`), {name: "Renamed"}));
    await assertFails(updateDoc(doc(as("admin"), `businesses/${B}`), {currency: {code: "USD", decimals: 2, symbol: "$"}}));
    await assertFails(updateDoc(doc(as("admin"), `businesses/${B}`), {memberUids: ["admin", "evil"]}));
  });
});

describe("transactions", () => {
  it("editors write drafts; viewers cannot", async () => {
    await assertSucceeds(setDoc(doc(as("editor"), `businesses/${B}/transactions/t1`), draft()));
    await assertSucceeds(updateDoc(doc(as("editor"), `businesses/${B}/transactions/draft1`), {description: "Sand"}));
    await assertSucceeds(deleteDoc(doc(as("editor"), `businesses/${B}/transactions/draft1`)));
    await assertFails(setDoc(doc(as("viewer"), `businesses/${B}/transactions/t2`), draft()));
    await assertFails(setDoc(doc(as("outsider"), `businesses/${B}/transactions/t3`), draft()));
  });

  it("clients cannot confirm, settle or alter confirmed entries", async () => {
    const db = as("owner");
    await assertFails(setDoc(doc(db, `businesses/${B}/transactions/t4`), draft({status: "confirmed"})));
    await assertFails(setDoc(doc(db, `businesses/${B}/transactions/t5`), draft({paidMinor: 1000})));
    await assertFails(updateDoc(doc(db, `businesses/${B}/transactions/draft1`), {status: "confirmed"}));
    await assertFails(updateDoc(doc(db, `businesses/${B}/transactions/confirmed1`), {description: "edited"}));
    await assertFails(deleteDoc(doc(db, `businesses/${B}/transactions/confirmed1`)));
    await assertFails(setDoc(doc(db, `businesses/${B}/transactions/confirmed1/settlements/s1`), {kind: "payment", amountMinor: 1}));
    await assertFails(setDoc(doc(db, `businesses/${B}/transactions/t6`), draft({type: "refund"})));
    await assertFails(setDoc(doc(db, `businesses/${B}/transactions/t7`), draft({totalMinor: 1.5})));
  });

  it("stats, audit, counters and documents are server-written", async () => {
    const db = as("owner");
    await assertFails(setDoc(doc(db, `businesses/${B}/stats/2026-10-01`), {incomeMinor: 1}));
    await assertFails(setDoc(doc(db, `businesses/${B}/audit/a1`), {action: "x"}));
    await assertFails(setDoc(doc(db, `businesses/${B}/counters/invoice`), {next: 1}));
    await assertFails(setDoc(doc(db, `businesses/${B}/documents/d1`), {number: "INV-1"}));
    await assertFails(getDoc(doc(db, "requests/x")));
    await assertFails(getDoc(doc(as("viewer"), `businesses/${B}/audit/a1`)));
  });

  it("issued documents are read-only to clients: no field can be changed", async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), `businesses/${B}/documents/d1`), {
        type: "invoice", number: "INV-2026-0001", transactionId: "t1", snapshot: {}, voided: false,
      });
    });
    await assertSucceeds(getDoc(doc(as("viewer"), `businesses/${B}/documents/d1`)));
    await assertFails(getDoc(doc(as("outsider"), `businesses/${B}/documents/d1`)));
    for (const uid of ["owner", "admin", "editor"]) {
      const ref = doc(as(uid), `businesses/${B}/documents/d1`);
      await assertFails(updateDoc(ref, {number: "INV-2026-0099"}));
      await assertFails(updateDoc(ref, {voided: true}));
      await assertFails(updateDoc(ref, {storagePath: `businesses/${B}/documents/d1.pdf`}));
      await assertFails(deleteDoc(ref));
    }
  });
});

describe("configuration", () => {
  const category = {name: "Labour", kind: "expense", archived: false, fieldIds: [], sortOrder: 0};
  it("editors manage categories; nobody deletes them from the client", async () => {
    await assertSucceeds(setDoc(doc(as("editor"), `businesses/${B}/categories/c1`), category));
    await assertSucceeds(updateDoc(doc(as("editor"), `businesses/${B}/categories/c1`), {name: "Wages", archived: true}));
    await assertFails(deleteDoc(doc(as("owner"), `businesses/${B}/categories/c1`)));
    await assertFails(setDoc(doc(as("viewer"), `businesses/${B}/categories/c2`), category));
    await assertFails(setDoc(doc(as("editor"), `businesses/${B}/categories/c3`), {...category, kind: "bogus"}));
    await assertFails(setDoc(doc(as("outsider"), `businesses/${B}/categories/c4`), category));
  });
});
