import {readFileSync} from "node:fs";
import {join} from "node:path";
import {describe, expect, it} from "vitest";
import {
  apply, balanceOf, Balance, checkCancel, checkSettlement, checkTotalEdit, effective,
  isOverdue, lineAmount, outstanding, paymentStatusOf, searchTokens, SettlementKind, TransactionStatus,
} from "../../src/ledger";

/** The same fixtures `test/core/ledger/ledger_math_test.dart` runs. */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const cases: any = JSON.parse(readFileSync(join(__dirname, "../../../shared/ledger_cases.json"), "utf8"));

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const statusOf = (start: any): TransactionStatus => start.transactionStatus ?? "confirmed";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function expectEnd(b: Balance, end: any, settleable: boolean) {
  const checks: Record<string, number> = {
    paid: b.paid, refunded: b.refunded, credited: b.credited,
    outstanding: outstanding(b), effective: effective(b),
  };
  for (const [key, value] of Object.entries(checks)) {
    if (end[key] !== undefined) expect(value, key).toBe(end[key]);
  }
  if (end.status !== undefined) expect(paymentStatusOf(b, settleable)).toBe(end.status);
}

describe("settlements", () => {
  for (const c of cases.settlements) {
    it(c.name, () => {
      const settleable = c.start.settleable ?? true;
      let balance = balanceOf(c.start);
      for (const op of c.ops) {
        const violation = checkSettlement({
          kind: op.kind as SettlementKind, balance, amount: op.amount,
          status: statusOf(c.start), settleable,
        });
        expect(violation ?? undefined).toBe(op.violation);
        if (!violation) balance = apply(balance, op.kind, op.amount);
      }
      expectEnd(balance, c.end, settleable);
    });
  }
});

describe("total edits", () => {
  for (const c of cases.totalEdits) {
    it(c.name, () => {
      const balance = balanceOf(c.start);
      expect(checkTotalEdit(balance, c.newTotal) ?? undefined).toBe(c.violation);
      if (c.end) expectEnd({...balance, total: c.newTotal}, c.end, true);
    });
  }
});

describe("cancels", () => {
  for (const c of cases.cancels) {
    it(c.name, () => {
      expect(checkCancel(balanceOf(c.start), statusOf(c.start)) ?? undefined).toBe(c.violation);
    });
  }
});

describe("overdue", () => {
  for (const c of cases.overdue) {
    it(c.name, () => {
      expect(isOverdue({status: c.status, outstanding: c.outstanding, dueDate: c.dueDate, today: c.today}))
        .toBe(c.expect);
    });
  }
});

describe("line amounts", () => {
  for (const c of cases.lineAmounts) {
    it(`${c.quantityMilli} × ${c.rateMinor}`, () => {
      expect(lineAmount(c.quantityMilli, c.rateMinor)).toBe(c.expect);
    });
  }
});

describe("search tokens", () => {
  for (const c of cases.searchTokens) {
    it(JSON.stringify(c.parts), () => expect(searchTokens(c.parts)).toEqual(c.expect));
  }
});

it("every refund keeps outstanding non-negative and amounts single", () => {
  for (let total = 1; total <= 40; total += 13) {
    for (let pay = 0; pay <= total; pay += 7) {
      for (let refund = 0; refund <= pay; refund += 5) {
        let b = balanceOf({total});
        for (const [kind, amount] of [["payment", pay], ["refund", refund]] as const) {
          if (amount === 0) continue;
          expect(checkSettlement({kind, balance: b, amount, status: "confirmed", settleable: true})).toBeNull();
          b = apply(b, kind, amount);
        }
        expect(outstanding(b)).toBe(total - pay);
        expect(effective(b)).toBe(total - refund);
      }
    }
  }
});
