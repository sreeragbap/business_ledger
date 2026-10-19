import {z} from "zod";
import {DOCUMENT_TYPES, MAX_MINOR, SETTLEMENT_KINDS} from "./ledger";
import {isCalendarDate} from "./lib/dates";

export const id = z.string().min(1).max(128).regex(/^[^/]+$/, "Invalid id");
export const requestId = z.string().min(8).max(64).regex(/^[A-Za-z0-9_-]+$/, "Invalid request id");
export const calendarDate = z.string().refine(isCalendarDate, "Use a yyyy-MM-dd date");
export const minor = z.number().int().min(0).max(MAX_MINOR);
export const role = z.enum(["admin", "editor", "viewer"]);

const text = (max: number) => z.string().trim().max(max);

export const createBusiness = z.object({
  requestId,
  name: text(80).min(1, "Enter a business name"),
  description: text(500).optional(),
  currencyCode: z.string().length(3),
  timezone: z.string().min(1).max(64),
  template: z.string().min(1).max(32),
});

export const addMember = z.object({
  businessId: id,
  email: z.email(),
  role,
});

export const updateMemberRole = z.object({
  businessId: id,
  uid: id,
  role: z.enum(["owner", "admin", "editor", "viewer"]),
});

export const removeMember = z.object({businessId: id, uid: id});

const txTarget = {
  businessId: id,
  transactionId: id,
  requestId,
  expectedVersion: z.number().int().min(0).optional(),
};

export const confirmTransaction = z.object({
  ...txTarget,
  settleNow: z.boolean().optional(),
  settleDate: calendarDate.optional(),
  settleMethod: text(40).optional(),
});

export const lineItem = z.object({
  description: text(200),
  quantityMilli: z.number().int().min(1).max(MAX_MINOR),
  rateMinor: minor,
  amountMinor: minor,
});

export const editConfirmed = z.object({
  ...txTarget,
  expectedVersion: z.number().int().min(0),
  changes: z.object({
    description: text(200).optional(),
    reference: text(80).optional(),
    notes: text(2000).optional(),
    paymentMethod: text(40).optional(),
    date: calendarDate.optional(),
    dueDate: calendarDate.nullable().optional(),
    categoryId: id.optional(),
    partyId: id.nullable().optional(),
    projectId: id.nullable().optional(),
    lineItems: z.array(lineItem).max(200).optional(),
    totalMinor: minor.optional(),
    customFields: z.record(z.string(), z.unknown()).optional(),
  }).strict(),
});

export const cancelTransaction = z.object({...txTarget, reason: text(500).optional()});

export const recordSettlement = z.object({
  ...txTarget,
  kind: z.enum(SETTLEMENT_KINDS),
  amountMinor: z.number().int(),
  date: calendarDate,
  method: text(40).optional(),
  note: text(500).optional(),
});

export const deleteCategory = z.object({businessId: id, categoryId: id});

export const issueDocument = z.object({
  businessId: id,
  transactionId: id,
  settlementId: id.optional(),
  type: z.enum(DOCUMENT_TYPES),
  requestId,
});
