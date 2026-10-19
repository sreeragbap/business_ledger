import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:business_ledger/core/bloc/status.dart';
import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/ledger/ledger_math.dart';
import 'package:business_ledger/core/sync/sync_error_policy.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

/// What PostgREST hands the client for `app.fail(...)`: SQLSTATE `PTnnn`,
/// the user-safe MESSAGE and DETAIL as a JSON string
/// (`supabase/README.md`, Error contract).
PostgrestException _rpcError(
  String sqlState,
  Map<String, Object?> detail, {
  String message = 'msg',
}) => PostgrestException(
  message: message,
  code: sqlState,
  details: jsonEncode(detail),
);

void main() {
  group('AppException.fromPostgrest: the error contract', () {
    test('each PTnnn maps to its kind (and transient vs definitive)', () {
      final cases = <(String, Map<String, Object?>), AppErrorKind>{
        ('PT400', {'code': 'invalid-argument', 'reason': 'validation'}):
            AppErrorKind.validation,
        ('PT401', {'code': 'unauthenticated', 'reason': 'unauthenticated'}):
            AppErrorKind.unauthenticated,
        ('PT403', {'code': 'permission-denied', 'reason': 'notMember'}):
            AppErrorKind.permissionDenied,
        (
          'PT403',
          {
            'code': 'permission-denied',
            'reason': 'role',
            'required': 'admin',
          },
        ): AppErrorKind.permissionDenied,
        (
          'PT403',
          {
            'code': 'permission-denied',
            'reason': 'immutable',
            'field': 'business_id',
          },
        ): AppErrorKind.permissionDenied,
        ('PT404', {'code': 'not-found', 'reason': 'notFound'}):
            AppErrorKind.notFound,
        ('PT409', {'code': 'aborted', 'reason': 'conflict'}):
            AppErrorKind.conflict,
        (
          'PT412',
          {
            'code': 'failed-precondition',
            'reason': 'violation',
            'violation': 'overpayment',
          },
        ): AppErrorKind.violation,
        ('PT412', {'code': 'failed-precondition', 'reason': 'inUse'}):
            AppErrorKind.inUse,
        ('PT412', {'code': 'failed-precondition', 'reason': 'role'}):
            AppErrorKind.permissionDenied,
        ('PT422', {'code': 'already-exists', 'reason': 'requestReused'}):
            AppErrorKind.requestReused,
        ('PT422', {'code': 'already-exists', 'reason': 'validation'}):
            AppErrorKind.alreadyExists,
      };
      for (final MapEntry(key: (state, detail), value: kind) in cases.entries) {
        final error = AppException.fromPostgrest(_rpcError(state, detail));
        expect(error.kind, kind, reason: '$state $detail');
        expect(error.code, detail['code'], reason: '$state $detail');
        expect(
          SyncErrorPolicy.isTransient(error),
          isFalse,
          reason: 'a deliberate refusal is definitive: $state',
        );
      }
    });

    test('violation carries the ledger rule and its message', () {
      final error = AppException.fromPostgrest(
        _rpcError('PT412', {
          'code': 'failed-precondition',
          'reason': 'violation',
          'violation': 'overpayment',
        }, message: 'That is more than the outstanding balance.'),
      );
      expect(error.kind, AppErrorKind.violation);
      expect(error.reason, AppErrorReason.violation);
      expect(error.violation, LedgerViolation.overpayment);
      expect(error.message, LedgerViolation.overpayment.message);
    });

    test('conflict is one the client reloads on, with the server copy', () {
      final error = AppException.fromPostgrest(
        _rpcError('PT409', {
          'code': 'aborted',
          'reason': 'conflict',
        }, message: 'This record was changed by someone else.'),
      );
      expect(error.isConflict, isTrue);
      expect(error.message, 'This record was changed by someone else.');
    });

    test('validation exposes the rejected field', () {
      final error = AppException.fromPostgrest(
        _rpcError('PT400', {
          'code': 'invalid-argument',
          'reason': 'validation',
          'field': 'changes.date',
        }, message: 'Use a yyyy-MM-dd date'),
      );
      expect(error.kind, AppErrorKind.validation);
      expect(error.field, 'changes.date');
      expect(
        Status.fromException(error).errorFor('changes.date'),
        'Use a yyyy-MM-dd date',
      );
    });

    test('an unknown violation key is ignored, not a crash', () {
      final error = AppException.fromPostgrest(
        _rpcError('PT412', {
          'code': 'failed-precondition',
          'reason': 'violation',
          'violation': 'brandNewRule',
        }, message: 'Something new.'),
      );
      expect(error.kind, AppErrorKind.violation);
      expect(error.violation, isNull);
      expect(error.message, 'Something new.');
    });

    test('details already decoded as a map are read the same', () {
      final error = AppException.fromPostgrest(
        const PostgrestException(
          message: 'm',
          code: 'PT404',
          details: {'code': 'not-found', 'reason': 'notFound'},
        ),
      );
      expect(error.kind, AppErrorKind.notFound);
    });
  });

  group('AppException.fromPostgrest: outside the contract', () {
    test('RLS / privileges (42501) is permission denied', () {
      final error = AppException.fromPostgrest(
        const PostgrestException(
          message:
              'new row violates row-level security policy for table '
              '"categories"',
          code: '42501',
        ),
      );
      expect(error.kind, AppErrorKind.permissionDenied);
      expect(error.code, 'permission-denied');
      expect(error.message, isNot(contains('row-level')));
      expect(SyncErrorPolicy.isTransient(error), isFalse);
    });

    test('a CHECK violation is a definitive validation failure', () {
      final error = AppException.fromPostgrest(
        const PostgrestException(message: 'check', code: '23514'),
      );
      expect(error.kind, AppErrorKind.validation);
      expect(SyncErrorPolicy.isTransient(error), isFalse);
    });

    test('a rejected or expired token is unauthenticated', () {
      for (final code in ['PGRST301', 'PGRST303', '401']) {
        final error = AppException.fromPostgrest(
          PostgrestException(message: 'JWT expired', code: code),
        );
        expect(error.kind, AppErrorKind.unauthenticated, reason: code);
      }
    });

    test('a PTnnn without the JSON detail falls back to its status', () {
      final error = AppException.fromPostgrest(
        const PostgrestException(message: 'x', code: 'PT409'),
      );
      expect(error.kind, AppErrorKind.conflict);
    });

    test('deadlock, timeouts and gateway errors are transient; their text '
        'never shows', () {
      for (final code in ['40P01', '57014', '503', '502', 'XX000']) {
        final error = AppException.fromPostgrest(
          PostgrestException(message: 'internal detail $code', code: code),
        );
        expect(SyncErrorPolicy.isTransient(error), isTrue, reason: code);
        expect(error.message, isNot(contains('internal detail')));
        expect(error.cause, contains('internal detail'));
      }
    });
  });

  group('AppException.from: no answer from the network', () {
    test('socket, HTTP client and timeout errors are offline / timeout', () {
      expect(
        AppException.from(const SocketException('no route')).kind,
        AppErrorKind.offline,
      );
      expect(
        AppException.from(http.ClientException('Connection closed')).kind,
        AppErrorKind.offline,
      );
      expect(
        AppException.from(TimeoutException('slow')).kind,
        AppErrorKind.timeout,
      );
      expect(
        SyncErrorPolicy.isNetworkDown(
          AppException.from(const SocketException('x')),
        ),
        isTrue,
      );
    });
  });

  group('AppException.fromFirebase', () {
    test('Firebase codes map to kinds', () {
      const expected = {
        'permission-denied': AppErrorKind.permissionDenied,
        'unavailable': AppErrorKind.offline,
        'not-found': AppErrorKind.notFound,
        'aborted': AppErrorKind.conflict,
        'auth/unauthenticated': AppErrorKind.unauthenticated,
        'something-else': AppErrorKind.unknown,
      };
      for (final MapEntry(key: code, value: kind) in expected.entries) {
        final error = AppException.fromFirebase(
          FirebaseException(plugin: 'firebase_core', code: code),
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
        AppException.from(
          _rpcError('PT409', {'code': 'aborted', 'reason': 'conflict'}),
        ).kind,
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
        () async => throw const SocketException('down'),
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
