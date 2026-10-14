import 'dart:async';

import 'package:business_ledger/core/bloc/status.dart';
import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/ledger/ledger_math.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

/// `FirebaseFunctionsException`'s constructor is protected; a subclass is
/// how the plugin itself builds one.
class _FunctionsError extends FirebaseFunctionsException {
  _FunctionsError(String code, {super.message = 'msg', super.details})
    : super(code: code);
}

void main() {
  group('AppException.fromFunctions', () {
    test('violation carries the ledger rule and its message', () {
      final error = AppException.fromFunctions(
        _FunctionsError(
          'failed-precondition',
          message: 'That is more than the outstanding balance.',
          details: const {'reason': 'violation', 'violation': 'overpayment'},
        ),
      );
      expect(error.kind, AppErrorKind.violation);
      expect(error.reason, AppErrorReason.violation);
      expect(error.violation, LedgerViolation.overpayment);
      expect(error.message, LedgerViolation.overpayment.message);
    });

    test('aborted + conflict is a conflict the client reloads on', () {
      final error = AppException.fromFunctions(
        _FunctionsError(
          'aborted',
          message: 'This record was changed by someone else.',
          details: const {'reason': 'conflict'},
        ),
      );
      expect(error.kind, AppErrorKind.conflict);
      expect(error.isConflict, isTrue);
      expect(error.message, 'This record was changed by someone else.');
    });

    test('validation exposes the rejected field', () {
      final error = AppException.fromFunctions(
        _FunctionsError(
          'invalid-argument',
          message: 'Amount must be positive.',
          details: const {'reason': 'validation', 'field': 'amountMinor'},
        ),
      );
      expect(error.kind, AppErrorKind.validation);
      expect(error.field, 'amountMinor');
      expect(
        Status.fromException(error).errorFor('amountMinor'),
        'Amount must be positive.',
      );
    });

    test('notMember and role are permission failures', () {
      for (final reason in ['notMember', 'role']) {
        final error = AppException.fromFunctions(
          _FunctionsError(
            'permission-denied',
            details: {'reason': reason},
          ),
        );
        expect(error.kind, AppErrorKind.permissionDenied, reason: reason);
      }
    });

    test('notFound, inUse and requestReused map to their kinds', () {
      const expected = {
        'notFound': AppErrorKind.notFound,
        'inUse': AppErrorKind.inUse,
        'requestReused': AppErrorKind.requestReused,
      };
      for (final MapEntry(key: reason, value: kind) in expected.entries) {
        final error = AppException.fromFunctions(
          _FunctionsError(
            'failed-precondition',
            details: {'reason': reason},
          ),
        );
        expect(error.kind, kind, reason: reason);
      }
    });

    test('unavailable without a reason is offline, with generic copy', () {
      final error = AppException.fromFunctions(
        _FunctionsError('unavailable', message: 'UNAVAILABLE: io error'),
      );
      expect(error.kind, AppErrorKind.offline);
      expect(error.isOffline, isTrue);
      expect(error.message, isNot(contains('io error')));
    });

    test('an internal crash never leaks its server text', () {
      final error = AppException.fromFunctions(
        _FunctionsError('internal', message: 'TypeError: x is undefined'),
      );
      expect(error.kind, AppErrorKind.unknown);
      expect(error.message, isNot(contains('TypeError')));
      expect(error.cause, contains('TypeError'));
    });

    test('platform spellings of the code are normalised', () {
      final error = AppException.fromFunctions(
        _FunctionsError('DEADLINE_EXCEEDED'),
      );
      expect(error.code, 'deadline-exceeded');
      expect(error.kind, AppErrorKind.timeout);
    });

    test('details as Map<Object?, Object?> from the platform channel', () {
      final error = AppException.fromFunctions(
        _FunctionsError(
          'aborted',
          details: const <Object?, Object?>{'reason': 'conflict'},
        ),
      );
      expect(error.kind, AppErrorKind.conflict);
    });

    test('an unknown violation key is ignored, not a crash', () {
      final error = AppException.fromFunctions(
        _FunctionsError(
          'failed-precondition',
          message: 'Something new.',
          details: const {'reason': 'violation', 'violation': 'brandNewRule'},
        ),
      );
      expect(error.kind, AppErrorKind.violation);
      expect(error.violation, isNull);
      expect(error.message, 'Something new.');
    });
  });

  group('AppException.fromFirebase', () {
    test('Firestore codes map to kinds', () {
      const expected = {
        'permission-denied': AppErrorKind.permissionDenied,
        'unavailable': AppErrorKind.offline,
        'not-found': AppErrorKind.notFound,
        'aborted': AppErrorKind.conflict,
        'cloud_firestore/unauthenticated': AppErrorKind.unauthenticated,
        'something-else': AppErrorKind.unknown,
      };
      for (final MapEntry(key: code, value: kind) in expected.entries) {
        final error = AppException.fromFirebase(
          FirebaseException(plugin: 'cloud_firestore', code: code),
        );
        expect(error.kind, kind, reason: code);
        expect(error.message, isNotEmpty);
      }
    });
  });

  group('AppException.fromAuth', () {
    test('network failure is offline', () {
      final error = AppException.fromAuth(
        FirebaseAuthException(code: 'network-request-failed'),
      );
      expect(error.kind, AppErrorKind.offline);
    });

    test('a dismissed provider sheet is cancelled', () {
      final error = AppException.fromAuth(
        FirebaseAuthException(code: 'canceled'),
      );
      expect(error.isCancelled, isTrue);
    });

    test('account exists with another provider has specific copy', () {
      final error = AppException.fromAuth(
        FirebaseAuthException(code: 'account-exists-with-different-credential'),
      );
      expect(error.kind, AppErrorKind.alreadyExists);
      expect(error.message, contains('already exists'));
    });
  });

  group('AppException.from', () {
    test('dispatches subtypes before FirebaseException', () {
      expect(
        AppException.from(_FunctionsError('aborted')).kind,
        AppErrorKind.conflict,
      );
      expect(
        AppException.from(
          FirebaseAuthException(code: 'network-request-failed'),
        ).kind,
        AppErrorKind.offline,
      );
      expect(
        AppException.from(TimeoutException('slow')).kind,
        AppErrorKind.timeout,
      );
      expect(AppException.from(StateError('x')).kind, AppErrorKind.unknown);
    });

    test('passes an AppException through unchanged', () {
      const original = AppException.offline();
      expect(AppException.from(original), same(original));
    });
  });

  group('AppResult', () {
    test('guard turns a throw into a Failure', () async {
      final result = await AppResult.guard<int>(
        () async => throw _FunctionsError('unavailable'),
      );
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull?.kind, AppErrorKind.offline);
    });

    test('when and map', () {
      const AppResult<int> ok = Success(2);
      expect(ok.map((v) => v * 2).dataOrNull, 4);
      expect(ok.when(success: (v) => 'ok $v', failure: (_) => 'no'), 'ok 2');

      const AppResult<int> failed = Failure(AppException.offline());
      expect(failed.map((v) => v * 2).isFailure, isTrue);
      expect(() => failed.dataOrThrow, throwsA(isA<AppException>()));
    });
  });
}
