/**
 * shared/ledger_cases.json against the SQL ledger functions — the same
 * fixtures the Dart (ledger_math_test.dart) and TypeScript
 * (functions/test/unit/ledger.test.ts) suites run.
 */
import type {PGlite} from "@electric-sql/pglite";
import {readFileSync} from "node:fs";
import {join} from "node:path";
import {beforeAll, describe, expect, it} from "vitest";
import {createDb, repoRoot} from "./helpers";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const cases: any = JSON.parse(readFileSync(join(repoRoot, "shared/ledger_cases.json"), "utf8"));

let db: PGlite;
beforeAll(async () => {
  db = await createDb();
});

interface Balance {
  total: number;
  paid: number;
  refunded: number;
  credited: number;
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const balanceOf = (s: any): Balance => ({total: s.total, paid: s.paid ?? 0, refunded: s.refunded ?? 0, credited: s.credited ?? 0});
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const statusOf = (s: any): string => s.transactionStatus ?? "confirmed";

async function one<T = Record<string, unknown>>(sql: string, params: unknown[]): Promise<T> {
  return (await db.query<T>(sql, params)).rows[0];
}

function apply(b: Balance, kind: string, amount: number): Balance {
  if (kind === "payment") return {...b, paid: b.paid + amount};
  if (kind === "refund") return {...b, refunded: b.refunded + amount};
  return {...b, credited: b.credited + amount};
}

const checkSettlement = async (kind: string, b: Balance, amount: number, status: string, settleable: boolean) =>
  (await one<{v: string | null}>(
    "select app.check_settlement($1, $2, $3, $4, $5, $6, $7, $8) as v",
    [kind, b.total, b.paid, b.refunded, b.credited, amount, status, settleable],
  )).v;

// eslint-disable-next-line @typescript-eslint/no-explicit-any
async function expectEnd(b: Balance, end: any, settleable: boolean) {
  const r = await one<{outstanding: string; effective: string; status: string}>(
    `select app.outstanding($1, $2, $3, $4) as outstanding, app.effective($1, $2, $3, $4) as effective,
            app.payment_status_of($1, $2, $3, $4, $5) as status`,
    [b.total, b.paid, b.refunded, b.credited, settleable],
  );
  const checks: Record<string, number> = {
    paid: b.paid, refunded: b.refunded, credited: b.credited,
    outstanding: Number(r.outstanding), effective: Number(r.effective),
  };
  for (const [key, value] of Object.entries(checks)) {
    if (end[key] !== undefined) expect(value, key).toBe(end[key]);
  }
  if (end.status !== undefined) expect(r.status).toBe(end.status);
}

describe("settlements", () => {
  for (const c of cases.settlements) {
    it(c.name, async () => {
      const settleable = c.start.settleable ?? true;
      let balance = balanceOf(c.start);
      for (const op of c.ops) {
        const violation = await checkSettlement(op.kind, balance, op.amount, statusOf(c.start), settleable);
        expect(violation ?? undefined).toBe(op.violation);
        if (!violation) balance = apply(balance, op.kind, op.amount);
      }
      await expectEnd(balance, c.end, settleable);
    });
  }
});

describe("total edits", () => {
  for (const c of cases.totalEdits) {
    it(c.name, async () => {
      const b = balanceOf(c.start);
      const {v} = await one<{v: string | null}>("select app.check_total_edit($1, $2, $3, $4, $5) as v",
        [b.total, b.paid, b.refunded, b.credited, c.newTotal]);
      expect(v ?? undefined).toBe(c.violation);
      if (c.end) await expectEnd({...b, total: c.newTotal}, c.end, true);
    });
  }
});

describe("cancels", () => {
  for (const c of cases.cancels) {
    it(c.name, async () => {
      const b = balanceOf(c.start);
      const {v} = await one<{v: string | null}>("select app.check_cancel($1, $2, $3) as v",
        [b.paid, b.refunded, statusOf(c.start)]);
      expect(v ?? undefined).toBe(c.violation);
    });
  }
});

describe("overdue", () => {
  for (const c of cases.overdue) {
    it(c.name, async () => {
      const {v} = await one<{v: boolean}>("select app.is_overdue($1, $2, $3::date, $4::date) as v",
        [c.status, c.outstanding, c.dueDate, c.today]);
      expect(v).toBe(c.expect);
    });
  }
});

describe("line amounts", () => {
  for (const c of cases.lineAmounts) {
    it(`${c.quantityMilli} × ${c.rateMinor}`, async () => {
      const {v} = await one<{v: string}>("select app.line_amount($1, $2)::text as v", [c.quantityMilli, c.rateMinor]);
      expect(Number(v)).toBe(c.expect);
    });
  }
  it("rounds half away from zero for negatives too", async () => {
    const {v} = await one<{v: string}>("select app.line_amount(-1500, 1)::text as v", []);
    expect(Number(v)).toBe(-2);
  });
});

describe("search tokens", () => {
  for (const c of cases.searchTokens) {
    it(JSON.stringify(c.parts), async () => {
      const {v} = await one<{v: string[]}>(
        "select app.search_tokens(array(select value from jsonb_array_elements_text($1::jsonb))) as v",
        [JSON.stringify(c.parts)],
      );
      expect(v).toEqual(c.expect);
    });
  }
  it("caps words at 15 characters and the list at 200 tokens", async () => {
    const {v} = await one<{v: string[]}>("select app.search_tokens(array[$1]) as v",
      ["abcdefghijklmnopqrstuvwxyz " + Array.from({length: 30}, (_, i) => `w${i}xxxxxxxxxx`).join(" ")]);
    expect(v).toHaveLength(200);
    expect(v).toContain("abcdefghijklmno");
    expect(v).not.toContain("abcdefghijklmnop");
    expect([...v].sort()).toEqual(v);
  });
});

it("every refund keeps outstanding non-negative and amounts single", async () => {
  for (let total = 1; total <= 40; total += 13) {
    for (let pay = 0; pay <= total; pay += 7) {
      for (let refund = 0; refund <= pay; refund += 5) {
        let b = balanceOf({total});
        for (const [kind, amount] of [["payment", pay], ["refund", refund]] as const) {
          if (amount === 0) continue;
          expect(await checkSettlement(kind, b, amount, "confirmed", true)).toBeNull();
          b = apply(b, kind, amount);
        }
        const r = await one<{o: string; e: string}>("select app.outstanding($1,$2,$3,$4) o, app.effective($1,$2,$3,$4) e",
          [b.total, b.paid, b.refunded, b.credited]);
        expect(Number(r.o)).toBe(total - pay);
        expect(Number(r.e)).toBe(total - refund);
      }
    }
  }
});
