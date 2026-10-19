import 'dart:async';

import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/firebase/connectivity_service.dart';
import 'package:business_ledger/core/sync/firestore_network.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/core/sync/outbox_executor.dart';
import 'package:business_ledger/core/sync/outbox_store.dart';
import 'package:business_ledger/core/sync/sync_identity.dart';

/// Lets queued microtasks and zero-delay timers run.
Future<void> settle([int turns = 30]) async {
  for (var i = 0; i < turns; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class MemoryOutboxStore extends OutboxStore {
  MemoryOutboxStore([List<OutboxEntry> initial = const []])
    : saved = List.of(initial);

  List<OutboxEntry> saved;
  int writes = 0;

  @override
  Future<List<OutboxEntry>> read() async => List.of(saved);

  @override
  Future<void> write(List<OutboxEntry> entries) async {
    writes++;
    saved = List.of(entries);
  }
}

class FakeNetwork extends FirestoreNetwork {
  int enables = 0;
  int disables = 0;
  int waits = 0;

  /// What `waitForPendingWrites` returns; done at once when `null`.
  Completer<void>? pendingWrites;

  @override
  Future<void> enable() async => enables++;

  @override
  Future<void> disable() async => disables++;

  @override
  Future<void> waitForPendingWrites() {
    waits++;
    return pendingWrites?.future ?? Future<void>.value();
  }
}

/// A device network the test switches.
class FakeConnectivityService implements ConnectivityService {
  FakeConnectivityService({this.isOnline = true});

  final StreamController<bool> _changes = StreamController<bool>.broadcast();

  @override
  bool isOnline;

  bool get online => isOnline;

  /// Changes the state and announces it.
  set online(bool value) {
    isOnline = value;
    _changes.add(value);
  }

  @override
  Stream<bool> get onlineChanges async* {
    yield isOnline;
    yield* _changes.stream;
  }

  @override
  Future<bool> refresh() async => isOnline;

  @override
  Future<void> dispose() => _changes.close();
}

class FakeIdentity extends SyncIdentity {
  FakeIdentity([this._uid = 'u1']);

  final StreamController<String?> _changes =
      StreamController<String?>.broadcast();
  String? _uid;

  String? get current => _uid;

  set current(String? uid) {
    _uid = uid;
    _changes.add(uid);
  }

  @override
  String? get uid => _uid;

  @override
  Stream<String?> get uidChanges async* {
    yield _uid;
    yield* _changes.stream;
  }

  Future<void> dispose() => _changes.close();
}

/// Records what it sends; answers from [results] (per entry id, in order),
/// success otherwise.
class FakeExecutor extends OutboxExecutor {
  final List<OutboxEntry> sent = [];
  final Map<String, List<AppResult<void>>> results = {};

  void answer(String id, List<AppResult<void>> answers) =>
      results[id] = answers;

  List<String> get sentIds => [for (final entry in sent) entry.id];

  @override
  Future<AppResult<void>> run(OutboxEntry entry) async {
    sent.add(entry);
    final queue = results[entry.id];
    if (queue == null || queue.isEmpty) return const Success(null);
    return queue.removeAt(0);
  }
}

/// Timers the test fires by hand.
class FakeTimers {
  final List<FakeTimer> created = [];

  Timer call(Duration delay, void Function() run) {
    final timer = FakeTimer(delay, run);
    created.add(timer);
    return timer;
  }

  List<Duration> get delays => [for (final t in created) t.delay];

  FakeTimer? get active => created.where((t) => t.isActive).lastOrNull;

  /// Fires the active timer, if any.
  void fire() => active?.fire();
}

class FakeTimer implements Timer {
  FakeTimer(this.delay, this._run);

  final Duration delay;
  final void Function() _run;
  bool _active = true;

  void fire() {
    if (!_active) return;
    _active = false;
    _run();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}

int _seq = 0;

/// A queued entry for user [uid], each a second after the last.
OutboxEntry entry(
  String id, {
  OutboxKind kind = OutboxKind.settle,
  String? tx = 't1',
  String uid = 'u1',
  int? baseVersion,
  Map<String, Object?> payload = const {},
  OutboxStatus status = OutboxStatus.pending,
}) => OutboxEntry(
  id: id,
  uid: uid,
  businessId: 'b1',
  kind: kind,
  payload: {
    'businessId': 'b1',
    'transactionId': ?tx,
    'requestId': id,
    ...payload,
  },
  transactionId: tx,
  label: '${kind.key} $id',
  createdAt: DateTime.utc(2026, 3, 14, 9, 0, _seq++ % 60),
  baseVersion: baseVersion,
  status: status,
);

AppException serverError(String code, AppErrorKind kind, [String? message]) =>
    AppException(kind: kind, code: code, message: message ?? 'Refused: $code');
