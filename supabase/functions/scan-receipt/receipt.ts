// Pure helpers for the scan-receipt function: request checks, the prompt,
// the output schema and the clean-up of Claude's answer. No Deno or npm
// imports, so supabase/tests can run them under vitest.

export const PAYMENT_METHODS = [
  "Cash",
  "Bank transfer",
  "UPI",
  "Card",
  "Cheque",
] as const;

export const LIMITS = {
  textChars: 12000,
  categories: 300,
  categoryName: 80,
  merchant: 60,
  description: 120,
  reference: 80,
  lineItems: 50,
  lineDescription: 120,
  sellerAddress: 160,
};

export interface ScanCategory {
  id: string;
  name: string;
}

export interface ScanRequest {
  /** Receipt text from on-device OCR, one printed row per line. */
  text: string;
  /** ISO code of the business currency. */
  currency: string;
  /** `yyyy-MM-dd` on the phone, to reject future dates. */
  today: string;
  /** Categories that fit the entry's direction. */
  categories: ScanCategory[];
}

export interface ScanLine {
  description: string;
  quantity: string;
  rate: string;
}

export interface ScanResult {
  merchant: string | null;
  date: string | null;
  total: string | null;
  currency: string | null;
  reference: string | null;
  paymentMethod: (typeof PAYMENT_METHODS)[number] | null;
  categoryId: string | null;
  description: string | null;
  lineItems: ScanLine[];
  sellerGstin: string | null;
  sellerPhone: string | null;
  sellerEmail: string | null;
  sellerAddress: string | null;
}

/** The request body, checked; a string says what is wrong. */
export function parseRequest(body: unknown): ScanRequest | string {
  if (typeof body !== "object" || body === null) return "body must be JSON";
  const b = body as Record<string, unknown>;
  if (typeof b.text !== "string" || b.text.trim() === "") {
    return "text is required";
  }
  if (b.text.length > LIMITS.textChars) return "text is too long";
  if (typeof b.currency !== "string" || !/^[A-Z]{3}$/.test(b.currency)) {
    return "currency must be an ISO code";
  }
  if (typeof b.today !== "string" || !isDay(b.today)) {
    return "today must be yyyy-MM-dd";
  }
  const raw = Array.isArray(b.categories) ? b.categories : [];
  if (raw.length > LIMITS.categories) return "too many categories";
  const categories: ScanCategory[] = [];
  for (const c of raw) {
    if (typeof c !== "object" || c === null) continue;
    const { id, name } = c as Record<string, unknown>;
    if (typeof id === "string" && typeof name === "string" && id && name) {
      categories.push({ id, name: name.slice(0, LIMITS.categoryName) });
    }
  }
  return { text: b.text, currency: b.currency, today: b.today, categories };
}

export const SYSTEM_PROMPT = `You read shop receipts, bills and invoices for a small-business ledger app, mostly in India.

You get the receipt text as recognised by OCR, one printed row per line. OCR can misread characters (O for 0, l for 1, S for 5); correct those only when the receipt makes the intended value clear.

Extract:
- merchant: the shop or business that issued the receipt, as a person would write it (title case, no address, no "GSTIN"). null if unclear.
- date: the bill date as yyyy-MM-dd. Indian receipts write day first (03/04/26 is 3 April 2026) unless the currency is USD. null if there is no date, or it would be after the "today" date given.
- total: the final amount the customer paid or owes (grand total / net amount after tax, discounts and round-off; not a subtotal, tax line, amount tendered or change). Digits with a dot for decimals and no separators, e.g. "1234.50". The text comes from OCR, which often reads the "₹" sign as "7" or "2" ("73,100.00" for "₹3,100.00"): check the total against the amount in words ("Three Thousand One Hundred Only") and against the items and taxes adding up, and prefer what they agree on. null if unsure.
- currency: the ISO code the amounts are in, if the receipt shows it (₹/Rs/INR is INR). Otherwise the business currency given.
- reference: the bill / invoice / receipt number, exactly as printed. null if none.
- paymentMethod: how it was paid, only if the receipt says so, as one of the allowed values.
- categoryId: the id of the best matching category from the list given, only if one clearly fits what was bought. null otherwise; never invent an id.
- description: a short note of what was bought, under 60 characters, e.g. "Groceries" or "Tyre and tube for bike". null if unclear.
- sellerGstin, sellerPhone, sellerEmail, sellerAddress: the seller's (not the buyer's) GST number, phone, email and postal address as printed. The address on one line with commas, without the shop name, phone numbers or form labels from the next column ("Delivery Note", "Invoice No."). A GSTIN is 15 characters: 2 digits, 5 letters, 4 digits, a letter, a digit or letter, "Z", a check character; fix OCR look-alikes (O/0, I/1, S/5, B/8, Z/2) by position and drop stray spaces. null when not printed.
- lineItems: the goods or services bought, one entry per item, so the ledger entry can be itemised.
  - description: the item as printed, joining a name that wraps onto the next line (e.g. "350/19 Michelin Sirac Street RTT"); no HSN/SAC codes, serial numbers or units.
  - quantity and rate: decimal strings ("1", "2.5", "2750.00"); rate is the price of one unit.
  - The lines must add up exactly to total (the sum of quantity × rate):
    - when the bill prints its taxes (CGST, SGST, IGST, VAT…) between the items and the total, use each item's own (pre-tax) rate, then add every tax, charge or positive round-off printed there as its own line with quantity "1", named like "SGST 14%", "CGST 14%", "Delivery charge", "Round off", so the GST shows on its own lines;
    - otherwise, when the receipt prints a tax-inclusive rate or amount per item (a column such as "Rate (Incl. of Tax)", "MRP" or "Net Rate") and those add up to the total, use them, one line per item;
    - take items and tax lines only from the bill above its total. Everything below the total only repeats it: the GST/tax summary table by HSN/SAC or rate (taxable value, CGST, SGST, total tax), the amount in words, bank details. Never take lines from there;
    - leave out column headers, subtotals and discount lines.
  - Empty when the items cannot be read reliably.

Never guess: a missing value is better than a wrong one in a ledger.`;

export function userPrompt(request: ScanRequest): string {
  const categories = request.categories.length === 0
    ? "(none)"
    : request.categories.map((c) => `${c.id}: ${c.name}`).join("\n");
  return `Business currency: ${request.currency}
Today: ${request.today}

Categories (id: name):
${categories}

Receipt text:
"""
${request.text}
"""`;
}

const nullable = (schema: Record<string, unknown>) => ({
  anyOf: [schema, { type: "null" }],
});

/** JSON schema for structured output. Fixed for every request, so the API
 * compiles it once and caches it. */
export const OUTPUT_SCHEMA = {
  type: "object",
  properties: {
    merchant: nullable({ type: "string" }),
    date: nullable({ type: "string", format: "date" }),
    total: nullable({ type: "string" }),
    currency: nullable({ type: "string" }),
    reference: nullable({ type: "string" }),
    paymentMethod: nullable({ type: "string", enum: [...PAYMENT_METHODS] }),
    categoryId: nullable({ type: "string" }),
    description: nullable({ type: "string" }),
    sellerGstin: nullable({ type: "string" }),
    sellerPhone: nullable({ type: "string" }),
    sellerEmail: nullable({ type: "string" }),
    sellerAddress: nullable({ type: "string" }),
    lineItems: {
      type: "array",
      items: {
        type: "object",
        properties: {
          description: { type: "string" },
          quantity: { type: "string" },
          rate: { type: "string" },
        },
        required: ["description", "quantity", "rate"],
        additionalProperties: false,
      },
    },
  },
  required: [
    "merchant",
    "date",
    "total",
    "currency",
    "reference",
    "paymentMethod",
    "categoryId",
    "description",
    "lineItems",
    "sellerGstin",
    "sellerPhone",
    "sellerEmail",
    "sellerAddress",
  ],
  additionalProperties: false,
} as const;

/** Claude's answer, cleaned: anything malformed, out of range or not in the
 * request becomes null, so the app only ever fills checked values. */
export function cleanResult(raw: unknown, request: ScanRequest): ScanResult {
  const r = (typeof raw === "object" && raw !== null ? raw : {}) as Record<
    string,
    unknown
  >;
  const date = text(r.date, 10);
  const total = text(r.total, 20)?.replace(/,/g, "") ?? null;
  const currency = text(r.currency, 3)?.toUpperCase() ?? null;
  const method = text(r.paymentMethod, 20);
  const categoryId = text(r.categoryId, 100);
  const lines = Array.isArray(r.lineItems) ? r.lineItems : [];
  const gstin = text(r.sellerGstin, 15)?.toUpperCase() ?? null;
  const email = text(r.sellerEmail, 80);
  return {
    merchant: text(r.merchant, LIMITS.merchant),
    date: date && isDay(date) && date <= nextDay(request.today) ? date : null,
    total: total && /^\d{1,13}(\.\d{1,4})?$/.test(total) && Number(total) > 0
      ? total
      : null,
    currency: currency && /^[A-Z]{3}$/.test(currency) ? currency : null,
    reference: text(r.reference, LIMITS.reference),
    paymentMethod: PAYMENT_METHODS.find((m) => m === method) ?? null,
    categoryId: request.categories.some((c) => c.id === categoryId)
      ? categoryId
      : null,
    description: text(r.description, LIMITS.description),
    lineItems: lines.slice(0, LIMITS.lineItems).flatMap((line) => {
      if (typeof line !== "object" || line === null) return [];
      const l = line as Record<string, unknown>;
      const description = text(l.description, LIMITS.lineDescription);
      const quantity = text(l.quantity, 12);
      const rate = text(l.rate, 20)?.replace(/,/g, "") ?? null;
      if (!description || !quantity || !rate) return [];
      if (!/^\d+(\.\d+)?$/.test(quantity) || !/^\d+(\.\d+)?$/.test(rate)) {
        return [];
      }
      return [{ description, quantity, rate }];
    }),
    sellerGstin: gstin && validGstin(gstin) ? gstin : null,
    sellerPhone: text(r.sellerPhone, 30),
    sellerEmail: email && /^[^\s@]+@[^\s@]+\.[A-Za-z]{2,}$/.test(email)
      ? email
      : null,
    sellerAddress: text(r.sellerAddress, LIMITS.sellerAddress),
  };
}

function text(value: unknown, max: number): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  return trimmed === "" ? null : trimmed.slice(0, max);
}

function isDay(value: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const d = new Date(`${value}T00:00:00Z`);
  return !Number.isNaN(d.getTime()) && d.toISOString().startsWith(value);
}

/** The day after [day]: a receipt can be "tomorrow" across time zones. */
function nextDay(day: string): string {
  const d = new Date(`${day}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + 1);
  return d.toISOString().slice(0, 10);
}

const BASE36 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";

/** A GSTIN with the right layout and check character (Luhn mod 36). */
export function validGstin(gstin: string): boolean {
  if (!/^\d{2}[A-Z]{5}\d{4}[A-Z][0-9A-Z]Z[0-9A-Z]$/.test(gstin)) return false;
  let sum = 0;
  for (let i = 0; i < 14; i++) {
    const product = BASE36.indexOf(gstin[i]) * (i % 2 === 0 ? 1 : 2);
    sum += Math.floor(product / 36) + (product % 36);
  }
  return gstin[14] === BASE36[(36 - (sum % 36)) % 36];
}
