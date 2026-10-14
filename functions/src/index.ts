/**
 * Callable Cloud Functions: every operation that moves money or must be
 * atomic across documents. Region `asia-south1`. See docs/ARCHITECTURE.md §2.
 * Export names are the callable names the Flutter `CallableClient` uses.
 */
import {setGlobalOptions} from "firebase-functions/options";
import * as business from "./handlers/business";
import * as categories from "./handlers/categories";
import * as documents from "./handlers/documents";
import * as members from "./handlers/members";
import * as transactions from "./handlers/transactions";
import {callable} from "./lib/callable";

setGlobalOptions({region: "asia-south1", maxInstances: 10});

export const createBusiness = callable(business.createBusiness);
export const addMember = callable(members.addMember);
export const updateMemberRole = callable(members.updateMemberRole);
export const removeMember = callable(members.removeMember);
export const confirmTransaction = callable(transactions.confirmTransaction);
export const editConfirmedTransaction = callable(transactions.editConfirmedTransaction);
export const cancelTransaction = callable(transactions.cancelTransaction);
export const recordSettlement = callable(transactions.recordSettlement);
export const deleteCategory = callable(categories.deleteCategory);
export const issueDocument = callable(documents.issueDocument);
