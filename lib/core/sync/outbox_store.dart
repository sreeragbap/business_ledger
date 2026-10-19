import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/core/sync/sync_directory.dart';
import 'package:injectable/injectable.dart';

/// Durable storage for the outbox: the whole queue, read once at start and
/// rewritten on every change.
abstract class OutboxStore {
  const OutboxStore();

  Future<List<OutboxEntry>> read();

  Future<void> write(List<OutboxEntry> entries);
}

/// [OutboxStore] as one JSON file, `<app support>/sync/outbox.json`.
///
/// A JSON file rather than sqflite: the queue is small (tens of entries),
/// always read whole and kept in memory, and needs no queries; a file adds
/// no native plugin and no schema migrations. Durability comes from the
/// write path: each write goes to a temp file which is flushed and then
/// renamed over the real one (`rename` is atomic on iOS and Android), so a
/// crash mid-write leaves the previous queue intact.
///
/// Reading never throws: an unreadable file is moved aside as
/// `outbox.corrupt-<millis>.json` (kept for diagnosis) and the queue starts
/// empty; a single malformed entry is skipped the same way.
@LazySingleton(as: OutboxStore)
class FileOutboxStore extends OutboxStore {
  FileOutboxStore(this._directory);

  final SyncDirectory _directory;
  Future<void> _writes = Future<void>.value();

  static const String fileName = 'outbox.json';
  static const int formatVersion = 1;

  Future<File> get _file async =>
      File('${(await _directory.root).path}/$fileName');

  @override
  Future<List<OutboxEntry>> read() async {
    await _writes;
    final file = await _file;
    if (!file.existsSync()) return const [];
    Object? decoded;
    try {
      decoded = jsonDecode(await file.readAsString());
    } catch (error) {
      await _backUp(file, error);
      return const [];
    }
    final list = decoded is Map ? decoded['entries'] : null;
    if (list is! List) {
      await _backUp(file, 'no entries list');
      return const [];
    }
    final entries = <OutboxEntry>[];
    Object? skipped;
    for (final item in list) {
      try {
        entries.add(
          OutboxEntry.fromJson(
            (item as Map).map((key, value) => MapEntry('$key', value)),
          ),
        );
      } catch (error) {
        skipped = error;
      }
    }
    if (skipped != null) await _backUp(file, skipped, keep: true);
    return entries;
  }

  @override
  Future<void> write(List<OutboxEntry> entries) {
    final snapshot = List<OutboxEntry>.of(entries);
    // Serialised: a later write must never be overtaken by an earlier one.
    return _writes = _writes.then(
      (_) => _write(snapshot),
      onError: (_) {
        return _write(snapshot);
      },
    );
  }

  Future<void> _write(List<OutboxEntry> entries) async {
    final file = await _file;
    final temp = File('${file.path}.tmp');
    final json = jsonEncode({
      'version': formatVersion,
      'entries': [for (final entry in entries) entry.toJson()],
    });
    await temp.writeAsString(json, flush: true);
    await temp.rename(file.path);
  }

  /// Keeps the unreadable file for diagnosis. With [keep] the original
  /// stays too (the readable entries are still in it until the next write).
  Future<void> _backUp(File file, Object error, {bool keep = false}) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final backup = '${file.parent.path}/outbox.corrupt-$stamp.json';
    developer.log(
      'Outbox file unreadable; kept as $backup',
      name: 'sync',
      error: error,
    );
    try {
      if (keep) {
        await file.copy(backup);
      } else {
        await file.rename(backup);
      }
    } catch (_) {
      // Nothing more to do: the queue starts from what could be read.
    }
  }
}
