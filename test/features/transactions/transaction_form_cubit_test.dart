import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/ledger/ledger_math.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/features/business/domain/const/role.dart';
import 'package:business_ledger/features/business/domain/const/standard_field.dart';
import 'package:business_ledger/features/parties/domain/const/party_kind.dart';
import 'package:business_ledger/features/parties/domain/models/party.dart';
import 'package:business_ledger/features/receipt_scan/domain/models/receipt_scan.dart';
import 'package:business_ledger/features/transactions/domain/models/line_item.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_results.dart';
import 'package:business_ledger/features/transactions/logic/request_tracker.dart';
import 'package:business_ledger/features/transactions/logic/transaction_form_cubit/transaction_form_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/stub_business_repositories.dart';
import '../receipt_scan/receipt_fakes.dart';
import 'stub_transaction_repository.dart';
import 'transaction_fixtures.dart';

void main() {
  late StubTransactionRepository repository;
  late StubCategoryRepository categoryRepository;
  late StubCustomFieldRepository fieldRepository;
  late StubPartyRepository parties;
  late StubProjectRepository projects;
  late FakeConnectivity connectivity;

  setUp(() {
    repository = StubTransactionRepository();
    categoryRepository = StubCategoryRepository();
    fieldRepository = StubCustomFieldRepository();
    parties = StubPartyRepository();
    projects = StubProjectRepository();
    connectivity = FakeConnectivity();
  });

  tearDown(() async {
    await repository.dispose();
    await categoryRepository.dispose();
    await fieldRepository.dispose();
    await parties.dispose();
    await projects.dispose();
    await connectivity.dispose();
  });

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  Future<TransactionFormCubit> start({
    Role role = Role.admin,
    TransactionType type = TransactionType.expense,
    String? transactionId,
  }) async {
    final cubit = TransactionFormCubit(
      repository,
      categoryRepository,
      fieldRepository,
      parties,
      projects,
      connectivity.service,
      nextRequestId: requestIds(),
      now: () => now,
    );
    await cubit.start(
      businessId: 'b1',
      currency: Currency.inr,
      role: role,
      enabledFields: StandardField.values.toSet(),
      transactionId: transactionId,
      initialType: type,
    );
    categoryRepository.categories.add(const Success(categories));
    fieldRepository.fields.add(const Success(fields));
    await flush();
    return cubit;
  }

  group('direction and categories', () {
    test(
      'fixed types set the direction; payment keeps the chosen one',
      () async {
        final cubit = await start(type: TransactionType.payment);
        expect(cubit.state.direction, isNull);
        expect(cubit.state.draft!.date, today);

        cubit.setDirection(Direction.outflow);
        expect(cubit.state.direction, Direction.outflow);
        cubit.setType(TransactionType.sale);
        expect(cubit.state.direction, Direction.inflow);
        cubit.setType(TransactionType.adjustment);
        expect(cubit.state.direction, Direction.inflow);
        // A fixed type ignores a direction change.
        cubit
          ..setType(TransactionType.expense)
          ..setDirection(Direction.inflow);
        expect(cubit.state.direction, Direction.outflow);
        await cubit.close();
      },
    );

    test('offers only unarchived categories that fit the direction', () async {
      final cubit = await start();
      expect(cubit.state.availableCategories.map((c) => c.id), [
        'c-rent',
        'c-misc',
      ]);
      cubit.setType(TransactionType.sale);
      expect(cubit.state.availableCategories.map((c) => c.id), [
        'c-sales',
        'c-misc',
      ]);
      await cubit.close();
    });

    test('a category that no longer fits the new type is cleared', () async {
      final cubit = await start()
        ..setCategory(rentCategory);
      expect(cubit.state.draft!.categoryId, 'c-rent');
      cubit.setType(TransactionType.purchase);
      expect(cubit.state.draft!.categoryId, 'c-rent');
      cubit.setType(TransactionType.sale);
      expect(cubit.state.draft!.categoryId, isNull);
      expect(cubit.state.draft!.categoryName, isNull);
      await cubit.close();
    });
  });

  group('amounts', () {
    test('line items: qty × rate per line, total is their sum', () async {
      final cubit = await start()
        ..setTotal(5000)
        ..setUseLineItems(value: true);
      var draft = cubit.state.draft!;
      expect(draft.lineItems.single.amountMinor, 5000, reason: 'carried over');

      cubit
        ..updateLine(0, quantityMilli: 2500, rateMinor: 333)
        ..addLine()
        ..updateLine(1, rateMinor: 1000);
      draft = cubit.state.draft!;
      expect(draft.lineItems[0].amountMinor, 833); // 832.5 → 833
      expect(cubit.state.total, 1833);
      expect(cubit.state.lineKeys, hasLength(2));

      final kept = cubit.state.lineKeys[1];
      cubit.removeLine(0);
      expect(cubit.state.lineKeys, [kept]);
      expect(cubit.state.total, 1000);

      cubit.setUseLineItems(value: false);
      expect(cubit.state.draft!.totalMinor, 1000);
      await cubit.close();
    });

    test('a zero quantity is refused on confirm', () async {
      final cubit = await start()
        ..setCategory(rentCategory)
        ..setUseLineItems(value: true)
        ..updateLine(0, quantityMilli: 0, rateMinor: 100);
      final errors = cubit.validate(forConfirm: true);
      expect(errors['lineItems'], 'Line 1: enter a quantity above zero.');
      await cubit.close();
    });
  });

  group('validation', () {
    test('required custom fields of the category, archived skipped', () async {
      final cubit = await start(type: TransactionType.sale)
        ..setCategory(salesCategory)
        ..setTotal(1000);
      expect(cubit.state.categoryFields.map((f) => f.id), ['f-site']);
      await cubit.saveAndConfirm();
      expect(cubit.state.errors['customFields.f-site'], 'Site is required.');
      expect(repository.calls, isEmpty);
      expect(repository.created, isEmpty);

      cubit.setCustomField('f-site', '  ');
      expect(
        cubit.validate(forConfirm: true).containsKey('customFields.f-site'),
        isTrue,
      );
      cubit.setCustomField('f-site', 'Plot 4');
      expect(cubit.validate(forConfirm: true), isEmpty);
      await cubit.close();
    });

    test('drafts need little; confirm needs category, amount, dates', () async {
      final cubit = await start();
      expect(cubit.validate(forConfirm: false), isEmpty);
      final errors = cubit.validate(forConfirm: true);
      expect(errors['categoryId'], 'Choose a category.');
      expect(errors['totalMinor'], LedgerViolation.nonPositiveAmount.message);

      cubit.setDueDate('2026-10-01');
      expect(
        cubit.validate(forConfirm: false)['dueDate'],
        'The due date cannot be before the transaction date.',
      );
      await cubit.close();
    });

    test('a payment needs a direction but no category', () async {
      final cubit = await start(type: TransactionType.payment)
        ..setTotal(100);
      final errors = cubit.validate(forConfirm: true);
      expect(errors.keys, ['direction']);
      await cubit.close();
    });
  });

  group('confirm availability', () {
    test('editors save drafts; admins confirm, offline too (queued)', () async {
      final editor = await start(role: Role.editor);
      expect(editor.state.canSaveDraft, isTrue);
      expect(editor.state.canConfirm, isFalse);
      expect(editor.state.canSettleNow, isFalse);
      await editor.close();

      final admin = await start();
      expect(admin.state.canConfirm, isTrue);
      expect(admin.state.canSettleNow, isTrue);
      connectivity.setOnline(online: false);
      await flush();
      expect(admin.state.online, isFalse);
      expect(admin.state.canConfirm, isTrue);
      expect(admin.state.canSettleNow, isTrue);
      expect(admin.state.confirmBlockedReason, isNull);
      expect(admin.state.queueNote, contains('applied when synced'));
      await admin.close();
    });

    test('payments settle on confirm anyway: no "as paid" option', () async {
      final cubit = await start(type: TransactionType.payment);
      expect(cubit.state.canConfirm, isTrue);
      expect(cubit.state.canSettleNow, isFalse);
      await cubit.close();
    });

    test('viewers cannot save', () async {
      final cubit = await start(role: Role.viewer);
      await cubit.saveDraft();
      expect(repository.created, isEmpty);
      expect(cubit.state.saveStatus.isFailure, isTrue);
      await cubit.close();
    });
  });

  group('saving', () {
    test('a draft saves offline, then updates the same document', () async {
      connectivity.isOnline = false;
      final cubit = await start()
        ..setTotal(1200);
      await cubit.saveDraft();
      expect(repository.created.single.totalMinor, 1200);
      expect(repository.awaitedServer.single, isFalse);
      expect(cubit.state.outcome, TransactionFormOutcome.savedDraft);
      expect(cubit.state.saveStatus.message, contains('sync'));

      cubit.setDescription('Diesel');
      await cubit.saveDraft();
      expect(repository.updated.single.description, 'Diesel');
      expect(repository.updated.single.id, repository.created.single.id);
      await cubit.close();
    });

    test(
      'save & confirm writes, waits for the server, then confirms',
      () async {
        final cubit = await start()
          ..setCategory(rentCategory)
          ..setTotal(2500);
        await cubit.saveAndConfirm(settleNow: true);
        expect(repository.awaitedServer.single, isTrue);
        final call = repository.calls.single;
        expect(call.name, 'confirm');
        expect(call.data['settleNow'], isTrue);
        expect(call.data['expectedVersion'], 0);
        expect(call.data['settleDate'], today);
        expect(cubit.state.outcome, TransactionFormOutcome.confirmedPaid);
        await cubit.close();
      },
    );

    test(
      'a retry after a timeout reuses the request id and skips the save',
      () async {
        repository.confirmResults.addAll([
          const Failure(
            AppException(kind: AppErrorKind.timeout, message: 'Too slow'),
          ),
          const Success(ConfirmResult(transactionId: 't', version: 1)),
        ]);
        final cubit = await start()
          ..setCategory(rentCategory)
          ..setTotal(2500);
        await cubit.saveAndConfirm();
        expect(cubit.state.saveStatus.isFailure, isTrue);
        await cubit.saveAndConfirm();

        expect(repository.calls, hasLength(2));
        expect(repository.calls[0].requestId, repository.calls[1].requestId);
        expect(repository.created, hasLength(1), reason: 'no second write');
        expect(cubit.state.outcome, TransactionFormOutcome.confirmed);
        await cubit.close();
      },
    );

    test(
      'offline: the draft is saved on the device and the confirm queued',
      () async {
        connectivity.isOnline = false;
        repository.queueActions = true;
        final cubit = await start()
          ..setCategory(rentCategory)
          ..setDescription('Office rent')
          ..setTotal(2500);
        await cubit.saveAndConfirm();
        expect(repository.awaitedServer.single, isFalse, reason: 'local');
        final call = repository.calls.single;
        expect(call.name, 'confirm');
        expect(call.label, 'Confirm ₹25.00 · Office rent');
        expect(cubit.state.outcome, TransactionFormOutcome.queued);
        expect(cubit.state.saveStatus.message, contains('when synced'));
        await cubit.close();
      },
    );

    test(
      'a save that loses the connection keeps the draft locally and goes on',
      () async {
        repository.writeResults.addAll([
          const Failure(AppException.offline()),
          const Success(null),
        ]);
        repository.queueActions = true;
        final cubit = await start()
          ..setCategory(rentCategory)
          ..setTotal(2500);
        await cubit.saveAndConfirm();
        expect(repository.awaitedServer, [isTrue, isFalse]);
        expect(cubit.state.outcome, TransactionFormOutcome.queued);
        await cubit.close();
      },
    );

    test('a definitive refusal starts a new request next time', () async {
      repository.confirmResults.add(
        const Failure(
          AppException(
            kind: AppErrorKind.validation,
            message: 'That category is archived. Choose another.',
            field: 'categoryId',
          ),
        ),
      );
      final cubit = await start()
        ..setCategory(rentCategory)
        ..setTotal(2500);
      await cubit.saveAndConfirm();
      expect(
        cubit.state.errors['categoryId'],
        'That category is archived. Choose another.',
      );
      await cubit.saveAndConfirm();
      expect(
        repository.calls[0].requestId,
        isNot(repository.calls[1].requestId),
      );
      await cubit.close();
    });
  });

  group('editing a confirmed entry', () {
    test('sends only changed keys at the loaded version', () async {
      repository.emitTransaction(confirmedSale(version: 7));
      final cubit = await start(transactionId: 't1');
      expect(cubit.state.mode, TransactionFormMode.editConfirmed);
      expect(cubit.state.canConfirm, isFalse);

      cubit
        ..setCustomField('f-site', 'Plot 4')
        ..setDescription('Cement bags (50)');
      await cubit.saveConfirmedChanges();
      final call = repository.calls.single;
      expect(call.name, 'edit');
      expect(call.data['expectedVersion'], 7);
      expect(call.data['changes'], {
        'description': 'Cement bags (50)',
        'customFields': {'f-site': 'Plot 4'},
      });
      expect(cubit.state.outcome, TransactionFormOutcome.edited);
      await cubit.close();
    });

    test('offline the edit is queued against the loaded version', () async {
      repository
        ..emitTransaction(confirmedSale(version: 7))
        ..queueActions = true;
      connectivity.isOnline = false;
      final cubit = await start(transactionId: 't1');
      expect(cubit.state.editBlockedReason, isNull);
      expect(cubit.state.queueNote, contains('applied when synced'));
      cubit
        ..setCustomField('f-site', 'Plot 4')
        ..setDescription('Cement bags (50)');
      await cubit.saveConfirmedChanges();
      final call = repository.calls.single;
      expect(call.data['expectedVersion'], 7);
      expect(call.label, startsWith('Edit · '));
      expect(cubit.state.outcome, TransactionFormOutcome.edited);
      expect(cubit.state.saveStatus.message, contains('when synced'));
      await cubit.close();
    });

    test('a total below what is settled is refused before the call', () async {
      repository.emitTransaction(
        confirmedSale(paid: 40000, status: PaymentStatus.partiallyPaid),
      );
      final cubit = await start(transactionId: 't1')
        ..setCustomField('f-site', 'x')
        ..setTotal(30000);
      await cubit.saveConfirmedChanges();
      expect(
        cubit.state.errors['totalMinor'],
        LedgerViolation.totalBelowSettled.message,
      );
      expect(repository.calls, isEmpty);
      await cubit.close();
    });

    test('a conflict offers a reload that brings the latest version', () async {
      repository
        ..emitTransaction(confirmedSale())
        ..editResults.add(
          const Failure(
            AppException(
              kind: AppErrorKind.conflict,
              message: 'Changed by someone else.',
              reason: AppErrorReason.conflict,
            ),
          ),
        );
      final cubit = await start(transactionId: 't1')
        ..setCustomField('f-site', 'x')
        ..setDescription('Mine');
      await cubit.saveConfirmedChanges();
      expect(cubit.state.hasConflict, isTrue);

      repository.emitTransaction(confirmedSale(version: 4));
      await cubit.reload();
      expect(cubit.state.hasConflict, isFalse);
      expect(cubit.state.original!.version, 4);
      expect(cubit.state.draft!.description, 'Cement bags');
      await cubit.close();
    });

    test('a cancelled entry cannot be edited', () async {
      repository.emitTransaction(cancelledSale());
      final cubit = await start(transactionId: 't1');
      expect(cubit.state.loadStatus.isFailure, isTrue);
      expect(cubit.state.draft, isNull);
      await cubit.close();
    });
  });

  test('RequestTracker keeps an id only while the outcome is unknown', () {
    final tracker = RequestTracker(requestIds());
    final first = tracker.idFor('a');
    tracker.settle(const AppException.offline());
    expect(tracker.idFor('a'), first);
    expect(tracker.idFor('b'), isNot(first), reason: 'a different action');
    tracker.settle(null);
    expect(tracker.isPending('b'), isFalse);
  });

  group('unsaved changes', () {
    test('a new form is clean until something is typed', () async {
      final cubit = await start();
      expect(cubit.state.hasUnsavedChanges, isFalse);

      cubit.setDescription('Diesel');
      expect(cubit.state.hasUnsavedChanges, isTrue);

      // Back to how it opened: nothing to lose.
      cubit.setDescription('');
      expect(cubit.state.hasUnsavedChanges, isFalse);
      await cubit.close();
    });

    test('saving clears it, so leaving after a save does not ask', () async {
      final cubit = await start()
        ..setTotal(1200);
      expect(cubit.state.hasUnsavedChanges, isTrue);
      await cubit.saveDraft();
      expect(cubit.state.hasUnsavedChanges, isFalse);
      await cubit.close();
    });

    test('an edit starts clean and turns dirty on change', () async {
      repository.emitTransaction(confirmedSale(version: 7));
      final cubit = await start(transactionId: 't1');
      expect(cubit.state.hasUnsavedChanges, isFalse);
      cubit.setDescription('Cement bags (50)');
      expect(cubit.state.hasUnsavedChanges, isTrue);
      await cubit.close();
    });
  });

  group('receipt scan', () {
    const receipt = ReceiptScan(
      totalMinor: 95500,
      date: '2026-10-24',
      merchant: 'Reliance Fresh',
      reference: 'RF-4821',
      paymentMethod: 'UPI',
      categoryId: 'c-rent',
      description: 'Groceries',
      reader: ReceiptReader.ai,
    );

    test('fills every field it can and adds the shop as a supplier', () async {
      final cubit = await start();
      final today = cubit.state.draft!.date;
      final result = await cubit.applyReceipt(receipt);
      final draft = cubit.state.draft!;
      expect(result.filled, 7);
      expect(result.addedSupplier, 'Reliance Fresh');
      expect(parties.created.single.kind, PartyKind.supplier);
      expect(draft.totalMinor, 95500);
      // The entry keeps today; the receipt's date goes beside it.
      expect(draft.date, today);
      expect(draft.receiptDate, '2026-10-24');
      expect(draft.categoryId, 'c-rent');
      expect(draft.partyId, 'p-new');
      expect(draft.partyName, 'Reliance Fresh');
      expect(draft.description, 'Groceries');
      expect(draft.reference, 'RF-4821');
      expect(draft.paymentMethod, 'UPI');
      expect(cubit.state.receiptFilled, {
        'totalMinor',
        'receiptDate',
        'categoryId',
        'partyId',
        'description',
        'reference',
        'paymentMethod',
      });
      expect(cubit.state.formRevision, 1);
      expect(cubit.state.hasUnsavedChanges, isTrue);
      await cubit.close();
    });

    test('a scan is always itemised: one line when no item was read', () async {
      final cubit = await start();
      await cubit.applyReceipt(receipt);
      final draft = cubit.state.draft!;
      expect(draft.useLineItems, isTrue);
      expect(draft.lineItems, [
        LineItem.of(description: 'Groceries', rateMinor: 95500),
      ]);
      expect(draft.total, 95500);
      expect(cubit.state.lineKeys, hasLength(1));
      await cubit.close();
    });

    test('a known supplier is picked instead of adding one', () async {
      final cubit = await start();
      parties.parties.add(
        const Success([
          Party(
            id: 'p-rf',
            name: 'Reliance Fresh Ltd',
            kind: PartyKind.supplier,
          ),
        ]),
      );
      await flush();
      final result = await cubit.applyReceipt(receipt);
      expect(result.addedSupplier, isNull);
      expect(parties.created, isEmpty);
      expect(cubit.state.draft!.partyId, 'p-rf');
      await cubit.close();
    });

    test('a refused supplier leaves the shop in the description', () async {
      parties.createResult = const Failure(scanFailure);
      final cubit = await start();
      final result = await cubit.applyReceipt(receipt);
      expect(result.addedSupplier, isNull);
      expect(cubit.state.draft!.partyId, isNull);
      expect(cubit.state.draft!.description, 'Groceries · Reliance Fresh');
      await cubit.close();
    });

    test('money coming in never adds the shop as a supplier', () async {
      final cubit = await start(type: TransactionType.sale);
      await cubit.applyReceipt(receipt);
      expect(parties.created, isEmpty);
      expect(cubit.state.draft!.partyId, isNull);
      await cubit.close();
    });

    test('the seller details go into the notes, with the supplier', () async {
      final cubit = await start();
      await cubit.applyReceipt(
        const ReceiptScan(
          totalMinor: 310000,
          merchant: 'Calicut Tyres',
          sellerGstin: '32AAHFC5361P1Z7',
          sellerPhone: '8606206660',
          sellerEmail: 'mail@calicuttyres.com',
        ),
      );
      expect(
        cubit.state.draft!.notes,
        'Calicut Tyres · GSTIN 32AAHFC5361P1Z7 · Ph 8606206660 · '
        'mail@calicuttyres.com',
      );
      final supplier = parties.created.single;
      expect(supplier.phone, '8606206660');
      expect(supplier.email, 'mail@calicuttyres.com');
      expect(cubit.state.receiptFilled, contains('notes'));
      await cubit.close();
    });

    test('never overwrites typed text, and skips a category that does '
        'not fit the direction', () async {
      final cubit = await start()
        ..setDescription('Monthly stock')
        ..setReference('MY-REF');
      await cubit.applyReceipt(
        const ReceiptScan(
          totalMinor: 100,
          reference: 'RF-1',
          description: 'Groceries',
          categoryId: 'c-sales',
        ),
      );
      final draft = cubit.state.draft!;
      expect(draft.description, 'Monthly stock');
      expect(draft.reference, 'MY-REF');
      expect(draft.categoryId, isNull);
      expect(draft.totalMinor, 100);
      await cubit.close();
    });

    test('a tyre invoice fills as two items, Itemise on, names as the '
        'description', () async {
      final cubit = await start();
      await cubit.applyReceipt(
        ReceiptScan(
          totalMinor: 310000,
          date: '2024-03-15',
          reference: '3335',
          lineItems: [
            LineItem.of(
              description: '350/19 Michelin Sirac Street RTT',
              rateMinor: 275000,
            ),
            LineItem.of(description: '3.50/19 Michelin Tube', rateMinor: 35000),
          ],
        ),
      );
      final draft = cubit.state.draft!;
      expect(draft.useLineItems, isTrue);
      expect(draft.lineItems.map((l) => l.description), [
        '350/19 Michelin Sirac Street RTT',
        '3.50/19 Michelin Tube',
      ]);
      expect(draft.total, 310000);
      expect(draft.receiptDate, '2024-03-15');
      expect(draft.reference, '3335');
      expect(
        draft.description,
        '350/19 Michelin Sirac Street RTT, 3.50/19 Michelin Tube',
      );
      expect(cubit.state.lineKeys, hasLength(2));
      await cubit.close();
    });

    test('an empty scan changes nothing', () async {
      final cubit = await start();
      expect((await cubit.applyReceipt(const ReceiptScan())).filled, 0);
      expect(cubit.state.formRevision, 0);
      await cubit.close();
    });
  });
}
