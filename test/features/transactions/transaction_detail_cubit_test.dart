import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/ledger/ledger_math.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/features/business/domain/const/role.dart';
import 'package:business_ledger/features/transactions/domain/models/audit_entry.dart';
import 'package:business_ledger/features/transactions/domain/models/pending_settlements.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_results.dart';
import 'package:business_ledger/features/transactions/logic/settlement_form_cubit/settlement_form_cubit.dart';
import 'package:business_ledger/features/transactions/logic/transaction_detail_cubit/transaction_detail_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/stub_business_repositories.dart';
import 'stub_transaction_repository.dart';
import 'transaction_fixtures.dart';

void main() {
  late StubTransactionRepository repository;
  late StubCustomFieldRepository fieldRepository;
  late FakeConnectivity connectivity;

  setUp(() {
    repository = StubTransactionRepository();
    fieldRepository = StubCustomFieldRepository();
    connectivity = FakeConnectivity();
  });

  tearDown(() async {
    await repository.dispose();
    await fieldRepository.dispose();
    await connectivity.dispose();
  });

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  Future<TransactionDetailCubit> start({Role role = Role.admin}) async {
    final cubit = TransactionDetailCubit(
      repository,
      fieldRepository,
      connectivity.service,
      nextRequestId: requestIds(),
      now: () => now,
    );
    await cubit.start(businessId: 'b1', transactionId: 't1', role: role);
    await flush();
    return cubit;
  }

  group('settlement pre-validation (LedgerMath)', () {
    test('overpayment and overcredit beyond the outstanding', () async {
      repository.emitTransaction(
        confirmedSale(paid: 40000, status: PaymentStatus.partiallyPaid),
      );
      final cubit = await start();
      expect(cubit.settlementViolation(SettlementKind.payment, 60000), isNull);
      expect(
        cubit.settlementViolation(SettlementKind.payment, 60001),
        LedgerViolation.overpayment,
      );
      expect(
        cubit.settlementViolation(SettlementKind.credit, 60001),
        LedgerViolation.overCredit,
      );
      expect(
        cubit.settlementViolation(SettlementKind.payment, 0),
        LedgerViolation.nonPositiveAmount,
      );
      expect(
        cubit.previewSettlement(SettlementKind.payment, 60000)?.outstanding,
        0,
      );
      expect(cubit.previewSettlement(SettlementKind.payment, 60001), isNull);
      await cubit.close();
    });

    test('a refund cannot exceed what was paid and not refunded', () async {
      repository.emitTransaction(
        confirmedSale(
          paid: 50000,
          refunded: 20000,
          status: PaymentStatus.partiallyRefunded,
        ),
      );
      final cubit = await start();
      expect(cubit.settlementViolation(SettlementKind.refund, 30000), isNull);
      expect(
        cubit.settlementViolation(SettlementKind.refund, 30001),
        LedgerViolation.overRefund,
      );
      expect(
        cubit.previewSettlement(SettlementKind.refund, 30000)?.effective,
        100000 - 50000,
      );
      await cubit.close();
    });

    test('nothing settles on a draft', () async {
      repository.emitTransaction(draftExpense(id: 't1'));
      final cubit = await start();
      expect(
        cubit.settlementViolation(SettlementKind.payment, 100),
        LedgerViolation.notConfirmed,
      );
      expect(
        cubit.state.kindUnavailableReason(SettlementKind.payment),
        'Confirm the transaction first.',
      );
      await cubit.close();
    });

    test('kinds are unavailable to editors; offline they stay available '
        '(queued)', () async {
      repository.emitTransaction(confirmedSale());
      final editor = await start(role: Role.editor);
      expect(
        editor.state.kindUnavailableReason(SettlementKind.payment),
        contains('admins'),
      );
      expect(repository.auditWatches, 0, reason: 'audit is admin only');
      await editor.close();

      final admin = await start();
      expect(admin.state.kindUnavailableReason(SettlementKind.payment), isNull);
      connectivity.setOnline(online: false);
      await flush();
      expect(admin.state.online, isFalse);
      expect(admin.state.kindUnavailableReason(SettlementKind.payment), isNull);
      expect(admin.state.can(DetailAction.confirm), isFalse, reason: 'draft');
      await admin.close();
    });
  });

  group('actions', () {
    test('cancel with money still held explains and does not call', () async {
      repository.emitTransaction(
        confirmedSale(paid: 1000, status: PaymentStatus.partiallyPaid),
      );
      final cubit = await start();
      await cubit.cancel(reason: 'oops');
      expect(cubit.state.actionStatus.isFailure, isTrue);
      expect(
        cubit.state.actionStatus.message,
        LedgerViolation.cancelWithMoney.message,
      );
      expect(repository.calls, isEmpty);
      await cubit.close();
    });

    test('cancel sends the reason and version', () async {
      repository.emitTransaction(confirmedSale(version: 5));
      final cubit = await start();
      await cubit.cancel(reason: 'Entered twice');
      final call = repository.calls.single;
      expect(call.name, 'cancel');
      expect(call.data['expectedVersion'], 5);
      expect(call.data['reason'], 'Entered twice');
      expect(cubit.state.actionStatus.isSuccess, isTrue);
      await cubit.close();
    });

    test('confirm reuses the request id after an unknown outcome', () async {
      repository
        ..emitTransaction(draftExpense(id: 't1'))
        ..confirmResults.addAll([
          const Failure(AppException(kind: AppErrorKind.timeout, message: 't')),
          const Success(ConfirmResult(transactionId: 't1', version: 1)),
        ]);
      final cubit = await start();
      await cubit.confirm();
      await cubit.confirm();
      expect(repository.calls[0].requestId, repository.calls[1].requestId);
      expect(cubit.state.actionStatus.message, 'Confirmed.');
      await cubit.close();
    });

    test('offline a confirm is queued: success that says so, and a second '
        'confirm is blocked while it waits', () async {
      repository
        ..emitTransaction(draftExpense(id: 't1', total: 120000))
        ..queueActions = true;
      connectivity.isOnline = false;
      final cubit = await start();
      expect(cubit.state.can(DetailAction.confirm), isTrue);
      await cubit.confirm();
      final call = repository.calls.single;
      expect(call.name, 'confirm');
      expect(call.label, startsWith('Confirm ₹1,200.00 · '));
      expect(cubit.state.actionStatus.isSuccess, isTrue);
      expect(cubit.state.actionQueued, isTrue);
      expect(cubit.state.actionStatus.message, contains('when synced'));

      repository.queued.add([
        queuedEntry(call.requestId, kind: OutboxKind.confirm),
      ]);
      await flush();
      expect(cubit.state.hasQueued, isTrue);
      expect(cubit.state.syncMark, SyncMark.pending);
      expect(
        cubit.state.blockedReason(DetailAction.confirm),
        'A confirm is already waiting to sync.',
      );
      await cubit.close();
    });

    test('a queued cancel blocks recording money', () async {
      repository.emitTransaction(confirmedSale());
      final cubit = await start();
      expect(cubit.state.canSettleAny, isTrue);
      repository.queued.add([queuedEntry('c', kind: OutboxKind.cancel)]);
      await flush();
      expect(
        cubit.state.kindUnavailableReason(SettlementKind.payment),
        PendingSettlements.cancelQueuedReason,
      );
      expect(cubit.state.canSettleAny, isFalse);
      await cubit.close();
    });

    test('a draft with a queued confirm takes payments, checked against its '
        'total', () async {
      repository.emitTransaction(draftExpense(id: 't1'));
      final cubit = await start();
      expect(
        cubit.state.kindUnavailableReason(SettlementKind.payment),
        'Confirm the transaction first.',
      );
      repository.queued.add([queuedEntry('c', kind: OutboxKind.confirm)]);
      await flush();
      expect(cubit.state.kindUnavailableReason(SettlementKind.payment), isNull);
      expect(cubit.settlementViolation(SettlementKind.payment, 5000), isNull);
      expect(
        cubit.settlementViolation(SettlementKind.payment, 5001),
        LedgerViolation.overpayment,
      );
      await cubit.close();
    });

    test("only this transaction's queued actions are listed", () async {
      repository.emitTransaction(confirmedSale());
      final cubit = await start();
      repository.queued.add([
        queuedEntry('a'),
        queuedEntry('b', transactionId: 't2'),
      ]);
      await flush();
      expect(cubit.state.queued.map((e) => e.id), ['a']);
      await cubit.close();
    });

    test('editors cannot confirm; drafts can be deleted', () async {
      repository.emitTransaction(draftExpense(id: 't1'));
      final cubit = await start(role: Role.editor);
      await cubit.confirm();
      expect(cubit.state.actionStatus.message, contains('admins'));
      expect(repository.calls, isEmpty);
      await cubit.deleteDraft();
      expect(repository.deleted, ['t1']);
      expect(cubit.state.removed, isTrue);
      await cubit.close();
    });

    test('a refund entry cannot be cancelled on its own', () async {
      repository.emitTransaction(
        confirmedSale().copyAsRefundEntry(),
      );
      final cubit = await start();
      expect(
        cubit.state.blockedReason(DetailAction.cancel),
        contains('refund entry'),
      );
      await cubit.close();
    });

    test('audit permission-denied hides the section quietly', () async {
      repository.emitTransaction(confirmedSale());
      final cubit = await start();
      expect(repository.auditWatches, 1);
      repository.audit.add(
        const Failure(
          AppException(kind: AppErrorKind.permissionDenied, message: 'no'),
        ),
      );
      await flush();
      expect(cubit.state.audit, isEmpty);
      expect(cubit.state.auditStatus.isFailure, isFalse);
      repository.audit.add(
        const Success([
          AuditEntry(
            id: 'a',
            entity: 'transaction',
            entityId: 't1',
            action: 'confirm',
          ),
        ]),
      );
      await flush();
      expect(cubit.state.audit, hasLength(1));
      await cubit.close();
    });
  });

  group('SettlementFormCubit', () {
    Future<SettlementFormCubit> settle({SettlementKind? kind}) async {
      final tx = confirmedSale(
        paid: 40000,
        status: PaymentStatus.partiallyPaid,
      );
      repository.emitTransaction(tx);
      final cubit = SettlementFormCubit(
        repository,
        nextRequestId: requestIds(),
        now: () => now,
      );
      await cubit.start(businessId: 'b1', transaction: tx, kind: kind);
      await flush();
      return cubit;
    }

    test('defaults: first possible kind, today, quick fill', () async {
      final cubit = await settle();
      expect(cubit.state.kind, SettlementKind.payment);
      expect(cubit.state.date, today);
      cubit.fillFull();
      expect(cubit.state.amountMinor, 60000);
      expect(cubit.state.preview?.outstanding, 0);
      expect(cubit.state.previewStatus, PaymentStatus.paid);
      cubit.setKind(SettlementKind.refund);
      expect(cubit.state.amountMinor, isNull);
      cubit.fillFull();
      expect(cubit.state.amountMinor, 40000);
      await cubit.close();
    });

    test('an overpayment is refused before the server', () async {
      final cubit = await settle()
        ..setAmount(60001);
      expect(cubit.state.violation, LedgerViolation.overpayment);
      expect(cubit.state.canSubmit, isFalse);
      await cubit.submit();
      expect(
        cubit.state.errors['amountMinor'],
        LedgerViolation.overpayment.message,
      );
      expect(repository.calls, isEmpty);
      await cubit.close();
    });

    test('submits with the live version; retries reuse the id', () async {
      repository.settleResults.add(
        const Failure(AppException(kind: AppErrorKind.timeout, message: 't')),
      );
      final cubit = await settle()
        ..setAmount(10000)
        ..setMethod('UPI');
      await cubit.submit();
      await cubit.submit();
      expect(repository.calls, hasLength(2));
      expect(repository.calls[0].requestId, repository.calls[1].requestId);
      expect(repository.calls.last.data['expectedVersion'], 3);
      expect(repository.calls.last.data['method'], 'UPI');
      expect(cubit.state.result, isNotNull);
      await cubit.close();
    });

    test('offline the settlement is queued with a readable label', () async {
      repository.queueActions = true;
      final cubit = await settle()
        ..setAmount(120000 - 60000 - 1000);
      await cubit.submit();
      expect(repository.calls.single.label, 'Payment ₹590.00 · Cement bags');
      expect(cubit.state.wasQueued, isTrue);
      expect(cubit.state.result, isNull, reason: 'nothing applied yet');
      expect(cubit.state.submitStatus.message, contains('when synced'));
      await cubit.close();
    });

    test(
      'queued settlements of the transaction count; others do not',
      () async {
        final cubit = await settle();
        repository.queued.add([
          queuedEntry('q1', payload: {'kind': 'payment', 'amountMinor': 50000}),
          queuedEntry(
            'q2',
            transactionId: 't9',
            payload: {'kind': 'payment', 'amountMinor': 50000},
          ),
        ]);
        await flush();
        expect(cubit.state.maxAmount, 10000);
        cubit.setAmount(10001);
        expect(cubit.state.violation, LedgerViolation.overpayment);
        await cubit.submit();
        expect(repository.calls, isEmpty, reason: 'refused before the call');
        cubit.setAmount(10000);
        expect(cubit.state.previewIncludesPending, isTrue);
        expect(cubit.state.preview!.outstanding, 0);
        await cubit.close();
      },
    );

    test('a conflict refreshes and asks to check again', () async {
      repository.settleResults.add(
        const Failure(
          AppException(
            kind: AppErrorKind.conflict,
            message: 'conflict',
            reason: AppErrorReason.conflict,
          ),
        ),
      );
      final cubit = await settle()
        ..setAmount(10000);
      await cubit.submit();
      expect(cubit.state.submitStatus.message, contains('Someone else'));
      repository.emitTransaction(
        confirmedSale(
          paid: 95000,
          version: 4,
          status: PaymentStatus.partiallyPaid,
        ),
      );
      await flush();
      expect(cubit.state.transaction!.version, 4);
      expect(cubit.state.violation, LedgerViolation.overpayment);
      await cubit.close();
    });
  });
}
