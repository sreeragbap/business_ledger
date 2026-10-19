import 'dart:async';
import 'dart:developer' as developer;

import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/core/sync/outbox_store.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

/// The durable queue of actions waiting for the server, in FIFO order.
///
/// Held in memory and written through to [OutboxStore] on every change.
/// Entries of every user live here; readers filter by `uid`.
@lazySingleton
class Outbox {
  Outbox(this._store);

  final OutboxStore _store;
  final BehaviorSubject<List<OutboxEntry>> _entries =
      BehaviorSubject<List<OutboxEntry>>();
  Future<void>? _loaded;

  /// Reads the store once. Every other member awaits it.
  Future<void> load() => _loaded ??= _load();

  Future<void> _load() async {
    final stored = await _store.read();
    // `syncing` on disk means the app died mid-send. The outcome is unknown;
    // the requestId makes sending it again safe.
    _entries.add(
      List.unmodifiable([
        for (final entry in stored)
          if (entry.isSyncing)
            entry.copyWith(status: OutboxStatus.pending)
          else
            entry,
      ]),
    );
  }

  /// Every entry, oldest first. Empty until [load] completes.
  List<OutboxEntry> get entries => _entries.valueOrNull ?? const [];

  /// The current queue first (once loaded), then each change.
  Stream<List<OutboxEntry>> get changes {
    unawaited(load());
    return _entries.stream;
  }

  OutboxEntry? byId(String id) {
    for (final entry in entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  /// Appends [entry]; an entry with the same id (a retry of the same
  /// action) is left as it is.
  Future<void> add(OutboxEntry entry) async {
    await load();
    if (byId(entry.id) != null) return;
    await _set([...entries, entry]);
  }

  /// Replaces the entry with [entry]'s id, if it is still queued.
  Future<void> update(OutboxEntry entry) => updateWhere(
    (candidate) => candidate.id == entry.id,
    (_) => entry,
  );

  /// Applies [change] to every entry matching [test], in one write.
  Future<void> updateWhere(
    bool Function(OutboxEntry entry) test,
    OutboxEntry Function(OutboxEntry entry) change,
  ) async {
    await load();
    var changed = false;
    final next = <OutboxEntry>[];
    for (final entry in entries) {
      if (test(entry)) {
        changed = true;
        next.add(change(entry));
      } else {
        next.add(entry);
      }
    }
    if (changed) await _set(next);
  }

  Future<void> remove(Iterable<String> ids) async {
    await load();
    final drop = ids.toSet();
    final next = [
      for (final entry in entries)
        if (!drop.contains(entry.id)) entry,
    ];
    if (next.length != entries.length) await _set(next);
  }

  Future<void> _set(List<OutboxEntry> next) async {
    final list = List<OutboxEntry>.unmodifiable(next);
    _entries.add(list);
    try {
      await _store.write(list);
    } catch (error) {
      // The queue in memory is right; the next change writes it all again.
      developer.log('Could not persist the outbox', name: 'sync', error: error);
    }
  }

  @disposeMethod
  Future<void> dispose() => _entries.close();
}
