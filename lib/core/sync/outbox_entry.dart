import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:equatable/equatable.dart';

/// What a queued action does: each kind replays one callable.
enum OutboxKind {
  confirm('confirm', 'confirmTransaction'),
  settle('settle', 'recordSettlement'),
  edit('edit', 'editConfirmedTransaction'),
  cancel('cancel', 'cancelTransaction');

  const OutboxKind(this.key, this.callable);

  final String key;

  /// The Cloud Function it replays.
  final String callable;

  /// Unknown kinds (e.g. an `upload` entry left by an older build) throw,
  /// and the store skips the record.
  static OutboxKind fromKey(Object? key) => values.firstWhere(
    (kind) => kind.key == key,
    orElse: () => throw FormatException('Unknown outbox kind: $key'),
  );
}

enum OutboxStatus {
  /// Waiting its turn (or a backoff).
  pending,

  /// Being sent right now.
  syncing,

  /// The server refused it; the user decides (retry or discard).
  failed;

  static OutboxStatus fromKey(Object? key) => values.firstWhere(
    (status) => status.name == key,
    orElse: () => pending,
  );
}

/// Why the last attempt failed, as stored with the entry.
class OutboxError extends Equatable {
  const OutboxError({required this.message, this.code, this.violation});

  factory OutboxError.from(AppException error) => OutboxError(
    message: error.message,
    code: error.code ?? error.kind.name,
    violation: error.violation?.name,
  );

  factory OutboxError.fromJson(Map<String, Object?> json) => OutboxError(
    message: json['message'] as String? ?? '',
    code: json['code'] as String?,
    violation: json['violation'] as String?,
  );

  /// User-safe text.
  final String message;

  /// The normalised Firebase code, or the `AppErrorKind` name.
  final String? code;

  /// The `LedgerViolation` key, when a ledger rule refused it.
  final String? violation;

  Map<String, Object?> toJson() => {
    'message': message,
    'code': ?code,
    'violation': ?violation,
  };

  @override
  List<Object?> get props => [message, code, violation];
}

/// One action waiting in the outbox (ARCHITECTURE §2, Offline behaviour).
///
/// [id] is the action's `requestId`, also inside [payload]: replaying the
/// entry any number of times applies it at most once.
class OutboxEntry extends Equatable {
  const OutboxEntry({
    required this.id,
    required this.uid,
    required this.businessId,
    required this.kind,
    required this.payload,
    required this.label,
    required this.createdAt,
    this.transactionId,
    this.status = OutboxStatus.pending,
    this.attempts = 0,
    this.lastError,
    this.baseVersion,
    this.chainedSuccesses = 0,
    this.nextAttemptAt,
  });

  /// Throws [FormatException] (or a `TypeError`) on a malformed record; the
  /// store skips those.
  factory OutboxEntry.fromJson(Map<String, Object?> json) {
    final payload = json['payload'];
    final error = json['lastError'];
    final created = DateTime.parse(json['createdAt']! as String);
    final next = json['nextAttemptAt'] as String?;
    return OutboxEntry(
      id: json['id']! as String,
      uid: json['uid']! as String,
      businessId: json['businessId']! as String,
      kind: OutboxKind.fromKey(json['kind']),
      payload: payload is Map
          ? payload.map((key, value) => MapEntry('$key', value))
          : throw const FormatException('Outbox payload is not a map'),
      label: json['label'] as String? ?? '',
      createdAt: created,
      transactionId: json['transactionId'] as String?,
      status: OutboxStatus.fromKey(json['status']),
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      lastError: error is Map
          ? OutboxError.fromJson(
              error.map((key, value) => MapEntry('$key', value)),
            )
          : null,
      baseVersion: (json['baseVersion'] as num?)?.toInt(),
      chainedSuccesses: (json['chainedSuccesses'] as num?)?.toInt() ?? 0,
      nextAttemptAt: next == null ? null : DateTime.parse(next),
    );
  }

  /// The `requestId`.
  final String id;

  /// Whose action it is. Only the signed-in user's entries are replayed:
  /// the server's idempotency record is per user.
  final String uid;
  final String businessId;
  final OutboxKind kind;

  /// The callable's input as first built, `requestId` included.
  final Map<String, Object?> payload;

  /// The transaction it acts on.
  final String? transactionId;

  /// How the action is listed, e.g. "Payment ₹1,200.00 · Cement bags".
  final String label;
  final DateTime createdAt;
  final OutboxStatus status;

  /// Attempts made so far.
  final int attempts;
  final OutboxError? lastError;

  /// For an edit: the transaction version on screen when it was queued.
  final int? baseVersion;

  /// Earlier queued actions on the same transaction that the server has
  /// applied since this one was queued. Each bumped the version by one.
  final int chainedSuccesses;

  /// Backoff: not before this time.
  final DateTime? nextAttemptAt;

  String get callable => kind.callable;
  bool get isPending => status == OutboxStatus.pending;
  bool get isSyncing => status == OutboxStatus.syncing;
  bool get isFailed => status == OutboxStatus.failed;

  /// What is sent on replay. `expectedVersion` would be stale by now, so it
  /// is left out where the schema allows (confirm, settle, cancel); an edit
  /// requires it, so it is chained: the version the user saw plus every
  /// earlier queued action since applied.
  Map<String, Object?> get replayPayload {
    final data = Map<String, Object?>.of(payload)..remove('expectedVersion');
    if (kind == OutboxKind.edit) {
      data['expectedVersion'] = (baseVersion ?? 0) + chainedSuccesses;
    }
    return data;
  }

  OutboxEntry copyWith({
    OutboxStatus? status,
    int? attempts,
    OutboxError? Function()? lastError,
    int? chainedSuccesses,
    DateTime? Function()? nextAttemptAt,
  }) => OutboxEntry(
    id: id,
    uid: uid,
    businessId: businessId,
    kind: kind,
    payload: payload,
    label: label,
    createdAt: createdAt,
    transactionId: transactionId,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    lastError: lastError == null ? this.lastError : lastError(),
    baseVersion: baseVersion,
    chainedSuccesses: chainedSuccesses ?? this.chainedSuccesses,
    nextAttemptAt: nextAttemptAt == null ? this.nextAttemptAt : nextAttemptAt(),
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'uid': uid,
    'businessId': businessId,
    'kind': kind.key,
    'callable': callable,
    'payload': payload,
    'transactionId': ?transactionId,
    'label': label,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'status': status.name,
    'attempts': attempts,
    if (lastError case final error?) 'lastError': error.toJson(),
    'baseVersion': ?baseVersion,
    'chainedSuccesses': chainedSuccesses,
    if (nextAttemptAt case final next?)
      'nextAttemptAt': next.toUtc().toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    uid,
    businessId,
    kind,
    payload,
    transactionId,
    label,
    createdAt,
    status,
    attempts,
    lastError,
    baseVersion,
    chainedSuccesses,
    nextAttemptAt,
  ];
}

/// How a transaction's queued actions show in lists.
enum SyncMark {
  none,

  /// Waiting to be sent.
  pending,

  /// The server refused one; it needs the user.
  failed;

  /// The mark for one transaction's [entries] (failed wins).
  static SyncMark of(Iterable<OutboxEntry> entries) {
    var mark = none;
    for (final entry in entries) {
      if (entry.isFailed) return failed;
      mark = pending;
    }
    return mark;
  }

  /// Per transaction id.
  static Map<String, SyncMark> byTransaction(Iterable<OutboxEntry> entries) {
    final grouped = <String, List<OutboxEntry>>{};
    for (final entry in entries) {
      final id = entry.transactionId;
      if (id != null) (grouped[id] ??= []).add(entry);
    }
    return grouped.map((id, list) => MapEntry(id, of(list)));
  }
}
