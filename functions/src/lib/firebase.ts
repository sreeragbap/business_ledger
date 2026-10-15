import {getApps, initializeApp} from "firebase-admin/app";
import {Firestore, getFirestore} from "firebase-admin/firestore";

/** One Admin app per process; tests and the runtime share this. */
export function db(): Firestore {
  if (getApps().length === 0) {
    initializeApp();
    getFirestore().settings({ignoreUndefinedProperties: true});
  }
  return getFirestore();
}
