import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/features/categories/domain/const/category_kind.dart';
import 'package:business_ledger/features/categories/domain/models/category.dart';
import 'package:business_ledger/features/categories/domain/models/custom_field.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_transaction.dart';

/// "Today" in every transactions test.
final DateTime now = DateTime(2026, 10, 14, 10);
const String today = '2026-10-14';

/// A sequential id generator for request ids.
String Function() requestIds() {
  var next = 0;
  return () => 'req-${(next++).toString().padLeft(4, '0')}';
}

const Category salesCategory = Category(
  id: 'c-sales',
  name: 'Sales',
  kind: CategoryKind.income,
  fieldIds: ['f-site', 'f-old'],
);
const Category rentCategory = Category(
  id: 'c-rent',
  name: 'Rent',
  kind: CategoryKind.expense,
  sortOrder: 1,
);
const Category miscCategory = Category(
  id: 'c-misc',
  name: 'Misc',
  sortOrder: 2,
);
const Category archivedCategory = Category(
  id: 'c-old',
  name: 'Old',
  kind: CategoryKind.expense,
  sortOrder: 3,
  archived: true,
);
const List<Category> categories = [
  salesCategory,
  rentCategory,
  miscCategory,
  archivedCategory,
];

const CustomField siteField = CustomField(
  id: 'f-site',
  label: 'Site',
  required: true,
);
const CustomField oldField = CustomField(
  id: 'f-old',
  label: 'Old field',
  required: true,
  archived: true,
);
const List<CustomField> fields = [siteField, oldField];

LedgerTransaction confirmedSale({
  String id = 't1',
  int total = 100000,
  int paid = 0,
  int refunded = 0,
  int credited = 0,
  int version = 3,
  String? dueDate,
  PaymentStatus status = PaymentStatus.unpaid,
}) => LedgerTransaction(
  id: id,
  type: TransactionType.sale,
  status: TransactionStatus.confirmed,
  direction: Direction.inflow,
  categoryId: salesCategory.id,
  categoryName: salesCategory.name,
  partyId: 'p1',
  partyName: 'Asha Traders',
  description: 'Cement bags',
  date: '2026-10-01',
  dueDate: dueDate,
  totalMinor: total,
  paidMinor: paid,
  refundedMinor: refunded,
  creditedMinor: credited,
  outstandingMinor: total - credited - paid,
  effectiveMinor: total - credited - refunded,
  paymentStatus: status,
  isOpen: total - credited - paid > 0,
  version: version,
  searchTokens: const ['a', 'as', 'ash', 'asha', 'c', 'ce', 'cem', 'cement'],
  createdAt: DateTime(2026, 10, 1, 9),
);

LedgerTransaction draftExpense({String id = 'd1', int total = 5000}) =>
    LedgerTransaction(
      id: id,
      type: TransactionType.expense,
      status: TransactionStatus.draft,
      direction: Direction.outflow,
      categoryId: rentCategory.id,
      categoryName: rentCategory.name,
      description: 'October rent',
      date: '2026-10-05',
      totalMinor: total,
      createdAt: DateTime(2026, 10, 5, 9),
    );

LedgerTransaction cancelledSale({String id = 't1'}) =>
    LedgerTransaction.fromMap(
      id,
      const {
        'type': 'sale',
        'status': 'cancelled',
        'direction': 'in',
        'date': '2026-10-01',
        'description': 'Cement bags',
        'totalMinor': 100000,
        'paymentStatus': 'unpaid',
        'cancelReason': 'Entered twice',
        'version': 4,
      },
    );

extension RefundEntry on LedgerTransaction {
  /// This entry as the server's visible refund record.
  LedgerTransaction copyAsRefundEntry() => LedgerTransaction(
    id: id,
    type: TransactionType.refund,
    status: TransactionStatus.confirmed,
    direction: Direction.outflow,
    description: 'Refund · $description',
    date: date,
    totalMinor: 1000,
    paymentStatus: PaymentStatus.notApplicable,
    linkedTransactionId: 't-original',
    linkKind: 'refund',
    settlementId: 'req-1',
    version: 1,
  );
}
