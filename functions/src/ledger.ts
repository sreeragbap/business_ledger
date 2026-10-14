/**
 * The ledger's rules, mirrored from `lib/core/ledger/` (Dart). This side is
 * the authority: it decides what is stored. Both run the fixtures in
 * `shared/ledger_cases.json`, so a rule changed on one side only fails a test.
 * See docs/ARCHITECTURE.md §5.
 */

export type Direction = "in" | "out";

export const TRANSACTION_TYPES = [
  "income",
  "sale",
  "expense",
  "purchase",
  "payment",
  "adjustment",
  "refund",
] as const;
export type TransactionType = (typeof TRANSACTION_TYPES)[number];

export const TRANSACTION_STATUSES = ["draft", "confirmed", "cancelled"] as const;
export type TransactionStatus = (typeof TRANSACTION_STATUSES)[number];

export type PaymentStatus =
  | "unpaid"
  | "partiallyPaid"
  | "paid"
  | "partiallyRefunded"
  | "refunded"
  | "notApplicable";

export const SETTLEMENT_KINDS = ["payment", "refund", "credit"] as const;
export type SettlementKind = (typeof SETTLEMENT_KINDS)[number];

export const DOCUMENT_TYPES = ["invoice", "bill", "receipt"] as const;
export type DocumentType = (typeof DOCUMENT_TYPES)[number];

export interface TypeInfo {
  /** `null` when the user picks the direction per entry. */
  fixedDirection: Direction | null;
  settleable: boolean;
  creatable: boolean;
  /** Receipts come from settlements, not from the transaction itself. */
  documentType: DocumentType | null;
  /** Whether its effective amount is income/expense (vs. cash only). */
  recognised: boolean;
}

export const TYPE_INFO: Record<TransactionType, TypeInfo> = {
  income: {fixedDirection: "in", settleable: true, creatable: true, documentType: "invoice", recognised: true},
  sale: {fixedDirection: "in", settleable: true, creatable: true, documentType: "invoice", recognised: true},
  expense: {fixedDirection: "out", settleable: true, creatable: true, documentType: "bill", recognised: true},
  purchase: {fixedDirection: "out", settleable: true, creatable: true, documentType: "bill", recognised: true},
  payment: {fixedDirection: null, settleable: true, creatable: true, documentType: null, recognised: false},
  adjustment: {fixedDirection: null, settleable: false, creatable: true, documentType: null, recognised: true},
  refund: {fixedDirection: null, settleable: false, creatable: false, documentType: null, recognised: false},
};

/** 10^13 minor units; mirrors `Money.maxMinor`, well inside 2^53. */
export const MAX_MINOR = 10_000_000_000_000;

export interface Balance {
  total: number;
  paid: number;
  refunded: number;
  credited: number;
}

export const balanceOf = (b: Partial<Balance> & {total: number}): Balance => ({
  total: b.total,
  paid: b.paid ?? 0,
  refunded: b.refunded ?? 0,
  credited: b.credited ?? 0,
});

export const payable = (b: Balance): number => b.total - b.credited;
export const netPaid = (b: Balance): number => b.paid - b.refunded;
/** Recognised income or expense: a refund reverses part of the sale. */
export const effective = (b: Balance): number => b.total - b.credited - b.refunded;
/** Still to be settled. A refund does not reopen it. */
export const outstanding = (b: Balance): number => b.total - b.credited - b.paid;
export const refundable = (b: Balance): number => netPaid(b);

export const VIOLATIONS = {
  nonPositiveAmount: "Enter an amount greater than zero.",
  amountTooLarge: "That amount is too large.",
  notConfirmed: "Only confirmed transactions can be settled.",
  notSettleable: "This type of transaction does not take payments.",
  overpayment: "That is more than the outstanding balance.",
  overRefund: "That is more than has been paid.",
  overCredit: "A credit cannot exceed the outstanding balance.",
  totalBelowSettled: "The total cannot be less than what has already been paid or credited.",
  cancelWithMoney: "Refund the payments on this transaction before cancelling it.",
  alreadyCancelled: "This transaction is already cancelled.",
  draftOnly: "Only drafts can be changed this way.",
} as const;
export type Violation = keyof typeof VIOLATIONS;

export function paymentStatusOf(b: Balance, settleable: boolean): PaymentStatus {
  if (!settleable) return "notApplicable";
  if (b.refunded > 0) return b.refunded >= b.paid ? "refunded" : "partiallyRefunded";
  if (outstanding(b) <= 0) return "paid";
  if (b.paid > 0 || b.credited > 0) return "partiallyPaid";
  return "unpaid";
}

export function isOverdue(a: {
  status: TransactionStatus;
  outstanding: number;
  dueDate: string | null | undefined;
  today: string;
}): boolean {
  return a.status === "confirmed" && a.outstanding > 0 && a.dueDate != null && a.dueDate < a.today;
}

export function checkAmount(amount: number): Violation | null {
  if (!Number.isSafeInteger(amount) || amount <= 0) return "nonPositiveAmount";
  if (amount > MAX_MINOR) return "amountTooLarge";
  return null;
}

export function checkSettlement(a: {
  kind: SettlementKind;
  balance: Balance;
  amount: number;
  status: TransactionStatus;
  settleable: boolean;
}): Violation | null {
  const amountViolation = checkAmount(a.amount);
  if (amountViolation) return amountViolation;
  if (a.status !== "confirmed") return "notConfirmed";
  if (!a.settleable) return "notSettleable";
  switch (a.kind) {
    case "payment":
      return a.amount > outstanding(a.balance) ? "overpayment" : null;
    case "credit":
      return a.amount > outstanding(a.balance) ? "overCredit" : null;
    case "refund":
      return a.amount > refundable(a.balance) ? "overRefund" : null;
  }
}

/** The balance after a settlement that passed [checkSettlement]. */
export function apply(b: Balance, kind: SettlementKind, amount: number): Balance {
  switch (kind) {
    case "payment":
      return {...b, paid: b.paid + amount};
    case "refund":
      return {...b, refunded: b.refunded + amount};
    case "credit":
      return {...b, credited: b.credited + amount};
  }
}

export function checkTotalEdit(b: Balance, newTotal: number): Violation | null {
  const amountViolation = checkAmount(newTotal);
  if (amountViolation) return amountViolation;
  if (newTotal < b.paid + b.credited) return "totalBelowSettled";
  return null;
}

export function checkCancel(b: Balance, status: TransactionStatus): Violation | null {
  if (status === "cancelled") return "alreadyCancelled";
  if (netPaid(b) !== 0) return "cancelWithMoney";
  return null;
}

/**
 * quantity (thousandths) × rate (minor units), rounded half away from zero
 * to a whole minor unit. BigInt so a large product cannot lose precision
 * the way a double would; Dart's 64-bit int is exact over the same range.
 */
export function lineAmount(quantityMilli: number, rateMinor: number): number {
  const product = BigInt(quantityMilli) * BigInt(rateMinor);
  const abs = product < 0n ? -product : product;
  const rounded = (abs + 500n) / 1000n;
  return Number(product < 0n ? -rounded : rounded);
}

/** Direction of a transaction: fixed by its type, or chosen per entry. */
export function directionOf(type: TransactionType, chosen: Direction | null | undefined): Direction | null {
  return TYPE_INFO[type].fixedDirection ?? chosen ?? null;
}

/**
 * Lowercase word prefixes for `array-contains` search. Mirrors
 * `SearchTokens.of` in Dart; fixtures in `shared/ledger_cases.json`.
 */
export function searchTokens(parts: Array<string | null | undefined>): string[] {
  const tokens = new Set<string>();
  for (const part of parts) {
    if (!part) continue;
    for (const word of part.toLowerCase().split(/[^\p{L}\p{N}]+/u)) {
      if (!word) continue;
      const max = Math.min(word.length, 15);
      for (let i = 1; i <= max; i++) tokens.add(word.slice(0, i));
    }
  }
  return [...tokens].sort().slice(0, 200);
}
