# Callable functions — contract

Region `asia-south1`. Every call needs a signed-in user. Source:
`functions/src/handlers/`, schemas in `functions/src/schemas.ts`.

`requestId`: client-generated, `^[A-Za-z0-9_-]{8,64}$`, new per user action and
**reused on retry** of the same action. A repeat returns the first result.

## Errors

`FirebaseFunctionsException.code` + `details`:

| code | details.reason | meaning |
|---|---|---|
| `invalid-argument` | `validation` | bad input; `details.field` names it |
| `failed-precondition` | `violation` | ledger rule; `details.violation` = `LedgerViolation` key |
| `failed-precondition` | `inUse` | category referenced by transactions |
| `aborted` | `conflict` | `expectedVersion` stale: reload and retry |
| `permission-denied` | `notMember` / `role` | |
| `not-found` | `notFound` | |
| `already-exists` | `requestReused` | requestId used for another operation |

`message` is always safe to show.

## Calls

| name | input | result | min role |
|---|---|---|---|
| `createBusiness` | requestId, name, description?, currencyCode, timezone, template (`general`/`retail`/`construction`/`services`/`blank`) | businessId | signed in |
| `addMember` | businessId, email, role (`admin`/`editor`/`viewer`) | uid | admin (owner for admins) |
| `updateMemberRole` | businessId, uid, role (`owner` = transfer) | uid, role | admin |
| `removeMember` | businessId, uid (self = leave) | uid | admin / self |
| `confirmTransaction` | businessId, transactionId, requestId, expectedVersion?, settleNow?, settleDate?, settleMethod? | transactionId, version, paymentStatus, settlementId | admin |
| `editConfirmedTransaction` | businessId, transactionId, requestId, expectedVersion, changes{description, reference, notes, paymentMethod, date, dueDate, categoryId, partyId, projectId, lineItems, totalMinor, customFields, attachments} | transactionId, version, paymentStatus | admin |
| `cancelTransaction` | businessId, transactionId, requestId, expectedVersion?, reason? | transactionId, version, voidedDocuments | admin |
| `recordSettlement` | businessId, transactionId, requestId, kind (`payment`/`refund`/`credit`), amountMinor, date, method?, note?, expectedVersion? | settlementId (= requestId), linkedTransactionId, version, paymentStatus, outstandingMinor | admin |
| `deleteCategory` | businessId, categoryId | categoryId | editor |
| `issueDocument` | businessId, transactionId, settlementId? (receipts), type (`invoice`/`bill`/`receipt`), requestId | documentId, number, created | editor |

## Draft shape (written by the client, checked by rules)

`status: 'draft'`, `type` (not `refund`), `createdBy`, `createdAt`, `updatedAt`,
`version: 0`, and any of: `direction` (payment/adjustment), `categoryId`,
`partyId`, `projectId`, `description`, `reference`, `notes`, `paymentMethod`,
`date`, `dueDate`, `lineItems[]`, `totalMinor`, `customFields{}`,
`attachments[]`, `searchTokens[]`. Never `paidMinor`/`refundedMinor`/
`creditedMinor`, `confirmed*`, `cancelled*` or link fields.

## Notes for running locally

`npm run test:emulator` needs Java (17 works; firebase-tools 15 will need 21).
Deploying functions needs the Blaze plan and the Firestore API enabled on
`busineedger-ab7a1`.
