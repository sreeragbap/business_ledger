import 'package:business_ledger/core/database/sync_table.dart';
import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:equatable/equatable.dart';

/// What a queued action does: a money action replays one RPC; a row write
/// replays a PostgREST upsert or update of rows written on this device.
enum OutboxKind {
  confirm('confirm', 'confirmTransaction'),
  settle('settle', 'recordSettlement'),
  edit('edit', 'editConfirmedTransaction'),
  cancel('cancel', 'cancelTransaction'),

  /// Insert-or-update of whole rows: `{table, rows: [row]}`. New drafts and
  /// new configuration rows (resending a row is harmless).
  upsert('upsert', ''),

  /// Column updates: `{table, updates: [{match, values}]}`. Draft edits and
  /// soft deletes, configuration edits, reorders and archives, business
  /// settings.
  update('update', '');

  const OutboxKind(this.key, this.callable);

  final String key;

  /// The action it replays (an `RpcClient` action name); empty for row
  /// writes.
  final String callable;

  /// A plain table write rather than a money action.
  bool get isRowWrite => this == upsert || this == update;

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

  /// For a money action: the RPC input as first built (camelCase,
  /// `requestId` included). For a row write: `{table, rows}` or
  /// `{table, updates}`.
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
  bool get isRowWrite => kind.isRowWrite;
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

  /// For a row write: the table it writes.
  SyncTable? get table => isRowWrite && payload['table'] is String
      ? SyncTable.byName(payload['table']! as String)
      : null;

  /// For an upsert: the rows, as sent.
  List<Map<String, dynamic>> get rows => [
    if (payload['rows'] case final List<Object?> list)
      for (final row in list)
        if (row is Map) row.map((key, value) => MapEntry('$key', value)),
  ];

  /// For an update: each `(match, values)` pair, as sent.
  List<RowUpdate> get updates => [
    if (payload['updates'] case final List<Object?> list)
      for (final item in list)
        if (item case {'match': final Map<Object?, Object?> match})
          RowUpdate(
            match.map((key, value) => MapEntry('$key', value!)),
            switch (item['values']) {
              final Map<Object?, Object?> values => values.map(
                (key, value) => MapEntry('$key', value),
              ),
              _ => const {},
            },
          ),
  ];

  /// For a row write: the primary keys of every row it touches.
  List<Map<String, Object?>> get rowKeys {
    final table = this.table;
    if (table == null) return const [];
    return [
      for (final row in rows) table.keyOf(row),
      for (final update in updates) update.match,
    ];
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

/// One `update` of a row write: set [values] where [match] (primary key).
class RowUpdate extends Equatable {
  const RowUpdate(this.match, this.values);

  final Map<String, Object> match;
  final Map<String, Object?> values;

  Map<String, Object?> toJson() => {'match': match, 'values': values};

  @override
  List<Object?> get props => [match, values];
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
