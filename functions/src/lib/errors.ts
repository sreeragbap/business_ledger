import {HttpsError} from "firebase-functions/https";
import {Violation, VIOLATIONS} from "../ledger";

/**
 * Error codes reach the client as `FirebaseFunctionsException.code`; the
 * Dart `AppException.fromFunctions` maps them. `details.reason` carries the
 * machine-readable cause, `message` is safe to show.
 */
export type Reason =
  | "violation"
  | "conflict"
  | "validation"
  | "notMember"
  | "role"
  | "notFound"
  | "inUse"
  | "requestReused";

export function fail(
  code: HttpsError["code"],
  message: string,
  reason: Reason,
  extra: Record<string, unknown> = {},
): never {
  throw new HttpsError(code, message, {reason, ...extra});
}

export function violation(v: Violation): never {
  fail("failed-precondition", VIOLATIONS[v], "violation", {violation: v});
}

export function notFound(what: string): never {
  fail("not-found", `${what} was not found.`, "notFound");
}

/** Another write landed first; the client reloads and retries. */
export function conflict(): never {
  fail("aborted", "This record was changed by someone else. Reload and try again.", "conflict");
}

export function invalid(message: string, field?: string): never {
  fail("invalid-argument", message, "validation", field ? {field} : {});
}
