import 'dart:async';

import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/firebase/connectivity_service.dart';
import 'package:business_ledger/core/firebase/local_first_writer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Connectivity extends Mock implements ConnectivityService {}

void main() {
  late _Connectivity connectivity;
  late LocalFirstWriter writer;

  setUp(() {
    connectivity = _Connectivity();
    writer = LocalFirstWriter(connectivity);
  });

  tearDown(() => writer.dispose());

  final denied = FirebaseException(
    plugin: 'cloud_firestore',
    code: 'permission-denied',
  );

  test('online: waits for the server and reports a rejection inline', () async {
    when(() => connectivity.isOnline).thenReturn(true);
    final result = await writer.commit(() => Future.error(denied));
    expect(result.errorOrNull?.kind, AppErrorKind.permissionDenied);
  });

  test('online: success once the server acknowledges', () async {
    when(() => connectivity.isOnline).thenReturn(true);
    final result = await writer.commit(() async {});
    expect(result.isSuccess, isTrue);
  });

  test('offline: succeeds at once, a later rejection is published', () async {
    when(() => connectivity.isOnline).thenReturn(false);
    final ack = Completer<void>();
    final late = writer.lateFailures.first;

    final result = await writer.commit(() => ack.future);
    expect(result.isSuccess, isTrue);

    ack.completeError(denied);
    expect((await late).kind, AppErrorKind.permissionDenied);
  });

  test('a synchronous throw is a failure, never queued', () async {
    when(() => connectivity.isOnline).thenReturn(false);
    final result = await writer.commit(() => throw ArgumentError('bad path'));
    expect(result.isFailure, isTrue);
  });
}
