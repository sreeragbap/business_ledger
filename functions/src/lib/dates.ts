import {Timestamp} from "firebase-admin/firestore";

const DATE = /^\d{4}-\d{2}-\d{2}$/;

/** A calendar day `yyyy-MM-dd` that actually exists (no 2026-02-30). */
export function isCalendarDate(value: string): boolean {
  if (!DATE.test(value)) return false;
  const d = new Date(`${value}T00:00:00Z`);
  return !Number.isNaN(d.getTime()) && d.toISOString().slice(0, 10) === value;
}

/** UTC midnight of a calendar day, stored beside it for range queries. */
export const dayTimestamp = (date: string): Timestamp => Timestamp.fromDate(new Date(`${date}T00:00:00Z`));

/** Today's calendar day in the business's time zone. */
export function todayIn(timeZone: string, now: Date = new Date()): string {
  try {
    return new Intl.DateTimeFormat("en-CA", {timeZone, year: "numeric", month: "2-digit", day: "2-digit"}).format(now);
  } catch {
    return now.toISOString().slice(0, 10);
  }
}
