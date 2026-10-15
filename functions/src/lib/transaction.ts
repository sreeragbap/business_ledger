import {DocumentData} from "firebase-admin/firestore";
import {
  Balance, Direction, effective, outstanding, paymentStatusOf, PaymentStatus, searchTokens,
  TransactionStatus, TransactionType, TYPE_INFO,
} from "../ledger";

/** The parts of a transaction document the server reasons about. */
export interface TxState {
  type: TransactionType;
  direction: Direction | null;
  status: TransactionStatus;
  date: string;
  categoryId: string | null;
  projectId: string | null;
  balance: Balance;
  version: number;
}

export function txState(data: DocumentData): TxState {
  return {
    type: data.type as TransactionType,
    direction: (data.direction as Direction | undefined) ?? null,
    status: data.status as TransactionStatus,
    date: data.date as string,
    categoryId: (data.categoryId as string | undefined) ?? null,
    projectId: (data.projectId as string | undefined) ?? null,
    balance: {
      total: (data.totalMinor as number | undefined) ?? 0,
      paid: (data.paidMinor as number | undefined) ?? 0,
      refunded: (data.refundedMinor as number | undefined) ?? 0,
      credited: (data.creditedMinor as number | undefined) ?? 0,
    },
    version: (data.version as number | undefined) ?? 0,
  };
}

/** Every stored figure that follows from the balance. Written together. */
export function moneyFields(
  type: TransactionType,
  status: TransactionStatus,
  b: Balance,
): {
  totalMinor: number;
  paidMinor: number;
  refundedMinor: number;
  creditedMinor: number;
  effectiveMinor: number;
  outstandingMinor: number;
  paymentStatus: PaymentStatus;
  isOpen: boolean;
} {
  const settleable = TYPE_INFO[type].settleable;
  const owed = settleable ? outstanding(b) : 0;
  return {
    totalMinor: b.total,
    paidMinor: b.paid,
    refundedMinor: b.refunded,
    creditedMinor: b.credited,
    effectiveMinor: effective(b),
    outstandingMinor: owed,
    paymentStatus: paymentStatusOf(b, settleable),
    isOpen: status === "confirmed" && owed > 0,
  };
}

export function tokensFor(data: DocumentData): string[] {
  return searchTokens([
    data.description, data.reference, data.partyName, data.categoryName, data.projectName,
  ]);
}

/** Whether a document can be issued for this transaction's type. */
export const documentTypeFor = (type: TransactionType) => TYPE_INFO[type].documentType;
