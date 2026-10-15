import {logger} from "firebase-functions";
import {HttpsError, onCall} from "firebase-functions/https";
import {z} from "zod";

export interface Caller {
  uid: string;
  email?: string;
  name?: string;
  picture?: string;
}

export interface Handler<S extends z.ZodType, R> {
  name: string;
  schema: S;
  impl: (caller: Caller, data: z.infer<S>) => Promise<R>;
}

export const handler = <S extends z.ZodType, R>(
  name: string,
  schema: S,
  impl: (caller: Caller, data: z.infer<S>) => Promise<R>,
): Handler<S, R> => ({name, schema, impl});

/**
 * Validates input and runs a handler. Shared by the deployed callable and
 * the integration tests, which call it directly against the emulator.
 */
export async function invoke<S extends z.ZodType, R>(h: Handler<S, R>, caller: Caller, raw: unknown): Promise<R> {
  const parsed = h.schema.safeParse(raw);
  if (!parsed.success) {
    const issue = parsed.error.issues[0];
    throw new HttpsError("invalid-argument", issue?.message ?? "Invalid request.", {
      reason: "validation",
      field: issue?.path.join("."),
    });
  }
  try {
    return await h.impl(caller, parsed.data);
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    logger.error(`${h.name} failed`, error);
    throw new HttpsError("internal", "Something went wrong. Please try again.");
  }
}

export function callable<S extends z.ZodType, R>(h: Handler<S, R>) {
  return onCall({region: "asia-south1", cors: false}, async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Sign in to continue.");
    const token = request.auth.token;
    return invoke(h, {
      uid: request.auth.uid,
      email: token.email,
      name: token.name as string | undefined,
      picture: token.picture,
    }, request.data);
  });
}
