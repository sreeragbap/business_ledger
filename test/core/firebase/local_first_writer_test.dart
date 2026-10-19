import 'dart:async';

import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/firebase/local_first_writer.dart';
import 'package:business_ledger/core/sync/cloud_availability.dart';
import 'package:business_ledger/core/sync/pending_writes_tracker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Online and Cloud sync on, as the test sets it.
class _Connectivity extends Mock implements CloudAvailability {}

void main() {
  late _Connectivity connectivity;
  late PendingWritesTracker tracker;
  late LocalFirstWriter writer;

  setUp(() {
    connectivity = _Connectivity();
    tracker = PendingWritesTracker();
    writer = LocalFirstWriter(connectivity, tracker);
  });

  tearDown(() async {
    await writer.dispose();
    await tracker.dispose();
  });

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

    expect(tracker.count, 1, reason: 'handed off, not acknowledged yet');

    ack.completeError(denied);
    expect((await late).kind, AppErrorKind.permissionDenied);
    expect(tracker.count, 0);
  });

  test('sync off counts as offline: success at once, tracked until the '
      'server acknowledges', () async {
    when(() => connectivity.isOnline).thenReturn(false);
    final ack = Completer<void>();
    final result = await writer.commit(() => ack.future);
    expect(result.isSuccess, isTrue);
    expect(tracker.hasPending, isTrue);
    ack.complete();
    await Future<void>.delayed(Duration.zero);
    expect(tracker.hasPending, isFalse);
  });

  test('an acknowledged online write is never counted as pending', () async {
    when(() => connectivity.isOnline).thenReturn(true);
    await writer.commit(() async {});
    expect(tracker.count, 0);
  });

  test('a synchronous throw is a failure, never queued', () async {
    when(() => connectivity.isOnline).thenReturn(false);
    final result = await writer.commit(() => throw ArgumentError('bad path'));
    expect(result.isFailure, isTrue);
  });
}
