import {FieldValue, Firestore, Transaction} from "firebase-admin/firestore";
import {Direction, effective, SettlementKind, TYPE_INFO} from "../ledger";
import {dayTimestamp} from "./dates";
import {TxState} from "./transaction";

/** date → flat field path → amount, e.g. `{"2026-10-14": {"incomeMinor": 500}}`. */
export type StatsDelta = Map<string, Map<string, number>>;

function add(delta: StatsDelta, date: string, path: string, amount: number): void {
  if (amount === 0) return;
  const day = delta.get(date) ?? new Map<string, number>();
  day.set(path, (day.get(path) ?? 0) + amount);
  delta.set(date, day);
}

/**
 * What a transaction adds to income/expense by its own date. Drafts,
 * cancelled entries, cash-only payments and the linked refund entries
 * (whose effect sits on the original) add nothing.
 */
export function recognised(tx: TxState | null): StatsDelta {
  const delta: StatsDelta = new Map();
  if (!tx || tx.status !== "confirmed" || !TYPE_INFO[tx.type].recognised || !tx.direction) return delta;
  const amount = effective(tx.balance);
  const side = tx.direction;
  add(delta, tx.date, side === "in" ? "incomeMinor" : "expenseMinor", amount);
  add(delta, tx.date, `byType.${tx.type}.${side}`, amount);
  if (tx.categoryId) add(delta, tx.date, `byCategory.${tx.categoryId}.${side}`, amount);
  if (tx.projectId) add(delta, tx.date, `byProject.${tx.projectId}.${side}`, amount);
  return delta;
}

/**
 * Cash moved by one settlement, on the settlement's date. A refund moves
 * money the opposite way to the original; a credit moves none.
 */
export function cash(kind: SettlementKind, direction: Direction, amount: number, date: string): StatsDelta {
  const delta: StatsDelta = new Map();
  if (kind === "credit") return delta;
  const flow = kind === "payment" ? direction : direction === "in" ? "out" : "in";
  add(delta, date, flow === "in" ? "cashInMinor" : "cashOutMinor", amount);
  return delta;
}

/** after − before, plus any extra deltas. Each amount counts once. */
export function diff(before: TxState | null, after: TxState | null, ...extra: StatsDelta[]): StatsDelta {
  const delta: StatsDelta = new Map();
  for (const [date, day] of recognised(after)) for (const [p, v] of day) add(delta, date, p, v);
  for (const [date, day] of recognised(before)) for (const [p, v] of day) add(delta, date, p, -v);
  for (const e of extra) for (const [date, day] of e) for (const [p, v] of day) add(delta, date, p, v);
  for (const [date, day] of delta) {
    for (const [p, v] of day) if (v === 0) day.delete(p);
    if (day.size === 0) delta.delete(date);
  }
  return delta;
}

/** Applies [delta] as increments, inside the caller's transaction. */
export function writeStats(tx: Transaction, db: Firestore, businessId: string, delta: StatsDelta): void {
  for (const [date, day] of delta) {
    const doc: Record<string, unknown> = {date, dateTs: dayTimestamp(date), updatedAt: FieldValue.serverTimestamp()};
    for (const [path, amount] of day) {
      const keys = path.split(".");
      let node = doc;
      for (const key of keys.slice(0, -1)) {
        node[key] = (node[key] as Record<string, unknown> | undefined) ?? {};
        node = node[key] as Record<string, unknown>;
      }
      node[keys[keys.length - 1]] = FieldValue.increment(amount);
    }
    tx.set(db.doc(`businesses/${businessId}/stats/${date}`), doc, {merge: true});
  }
}
