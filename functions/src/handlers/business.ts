import {FieldValue} from "firebase-admin/firestore";
import {currencyByCode} from "../currency";
import {audit} from "../lib/audit";
import {handler} from "../lib/callable";
import {invalid} from "../lib/errors";
import {db} from "../lib/firebase";
import {once} from "../lib/idempotency";
import * as s from "../schemas";
import {TEMPLATES} from "../templates";

/**
 * Creates the business, its owner membership and the template's
 * categories and fields in one write, so a business never exists without
 * an owner or half-seeded.
 */
export const createBusiness = handler("createBusiness", s.createBusiness, async (caller, data) => {
  const currency = currencyByCode(data.currencyCode) ?? invalid("Choose a supported currency.", "currencyCode");
  const template = TEMPLATES[data.template] ?? invalid("Choose a template.", "template");
  try {
    new Intl.DateTimeFormat("en", {timeZone: data.timezone});
  } catch {
    invalid("Unknown time zone.", "timezone");
  }

  const firestore = db();
  return once(firestore, caller.uid, data.requestId, "createBusiness", async (tx) => {
    const business = firestore.collection("businesses").doc();
    const now = FieldValue.serverTimestamp();

    tx.set(business, {
      name: data.name,
      description: data.description ?? "",
      currency,
      timezone: data.timezone,
      template: template.key,
      ownerId: caller.uid,
      memberUids: [caller.uid],
      settings: {
        enabledStandardFields: template.standardFields,
        invoicePrefix: "INV",
        billPrefix: "BILL",
        receiptPrefix: "RCPT",
        address: "",
        phone: "",
        email: caller.email ?? "",
        taxId: "",
      },
      archived: false,
      createdAt: now,
      updatedAt: now,
    });
    tx.set(business.collection("members").doc(caller.uid), {
      role: "owner",
      email: caller.email ?? "",
      displayName: caller.name ?? "",
      photoUrl: caller.picture ?? "",
      addedBy: caller.uid,
      addedAt: now,
    });

    const fieldIds = new Map<string, string>();
    template.fields.forEach((field, index) => {
      const ref = business.collection("fields").doc();
      fieldIds.set(field.key, ref.id);
      tx.set(ref, {
        label: field.label,
        type: field.type,
        options: field.options ?? [],
        required: field.required ?? false,
        sortOrder: index,
        archived: false,
        createdAt: now,
        updatedAt: now,
      });
    });
    template.categories.forEach((category, index) => {
      tx.set(business.collection("categories").doc(), {
        name: category.name,
        kind: category.kind,
        icon: category.icon,
        colour: category.colour,
        fieldIds: (category.fields ?? []).map((key) => fieldIds.get(key)).filter(Boolean),
        sortOrder: index,
        archived: false,
        createdAt: now,
        updatedAt: now,
      });
    });

    tx.set(firestore.doc(`users/${caller.uid}`), {lastBusinessId: business.id, updatedAt: now}, {merge: true});
    audit(tx, firestore, business.id, {
      entity: "business", entityId: business.id, action: "create", actor: caller.uid,
      after: {name: data.name, currency: currency.code, template: template.key},
    });
    return {businessId: business.id};
  });
});
