import 'dart:convert';
import 'dart:io';

import 'package:business_ledger/core/sync/outbox.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/core/sync/outbox_store.dart';
import 'package:business_ledger/core/sync/sync_directory.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sync_fakes.dart';

void main() {
  late Directory dir;
  late FileOutboxStore store;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('outbox_test');
    store = FileOutboxStore(SyncDirectory.at(dir));
  });

  tearDown(() => dir.delete(recursive: true));

  File file(String name) => File('${dir.path}/$name');

  List<String> backups() => [
    for (final item in dir.listSync())
      if (item.path.contains('outbox.corrupt-')) item.path,
  ];

  final full =
      entry(
        'r-edit-1',
        kind: OutboxKind.edit,
        baseVersion: 3,
        payload: {
          'expectedVersion': 3,
          'changes': {
            'description': 'Cement bags',
            'lineItems': [
              {'description': 'Bag', 'quantityMilli': 2000, 'rateMinor': 500},
            ],
          },
        },
      ).copyWith(
        status: OutboxStatus.failed,
        attempts: 2,
        lastError: () => const OutboxError(
          message: 'Overpayment',
          code: 'failed-precondition',
          violation: 'overpayment',
        ),
        chainedSuccesses: 1,
        nextAttemptAt: () => DateTime.utc(2026, 3, 14, 10),
      );

  test('round trip keeps every field and the order', () async {
    final second = entry('r-settle-2', payload: {'amountMinor': 120000});
    await store.write([full, second]);
    final read = await FileOutboxStore(SyncDirectory.at(dir)).read();
    expect(read, [full, second]);
    expect(read.first.replayPayload['expectedVersion'], 4);
  });

  test('no file is an empty queue', () async {
    expect(await store.read(), isEmpty);
  });

  test('writes atomically: through a temp file that is renamed', () async {
    await store.write([full]);
    expect(file('outbox.json').existsSync(), isTrue);
    expect(file('outbox.json.tmp').existsSync(), isFalse);

    // A crash after writing the temp file but before the rename leaves the
    // previous queue in place; the stray temp is never read.
    file('outbox.json.tmp').writeAsStringSync('{"entries": [garbage');
    expect(await store.read(), [full]);
    await store.write([]);
    expect(await store.read(), isEmpty);
    expect(file('outbox.json.tmp').existsSync(), isFalse);
  });

  test('later writes are never overtaken by earlier ones', () async {
    final writes = [
      for (var i = 0; i < 10; i++)
        store.write([for (var j = 0; j <= i; j++) entry('r-$j')]),
    ];
    await Future.wait(writes);
    expect(await store.read(), hasLength(10));
  });

  test('unreadable JSON: starts empty and keeps a backup', () async {
    file('outbox.json').writeAsStringSync('{"version": 1, "entries": [');
    expect(await store.read(), isEmpty);
    expect(backups(), hasLength(1));
    expect(
      File(backups().single).readAsStringSync(),
      '{"version": 1, "entries": [',
    );
    // The next write starts a fresh file.
    await store.write([full]);
    expect(await store.read(), [full]);
  });

  test('a wrong shape is treated as unreadable', () async {
    file('outbox.json').writeAsStringSync('[1, 2, 3]');
    expect(await store.read(), isEmpty);
    expect(backups(), hasLength(1));
  });

  test(
    'a malformed entry is skipped, the rest kept, the file backed up',
    () async {
      await store.write([full]);
      final json =
          jsonDecode(file('outbox.json').readAsStringSync())
              as Map<String, Object?>;
      (json['entries']! as List).add({'id': 'broken', 'kind': 'teleport'});
      file('outbox.json').writeAsStringSync(jsonEncode(json));

      expect(await store.read(), [full]);
      expect(backups(), hasLength(1));
    },
  );

  group('Outbox', () {
    test(
      'an entry left "syncing" by a crash is pending again on load',
      () async {
        final memory = MemoryOutboxStore([
          entry('r1').copyWith(status: OutboxStatus.syncing),
        ]);
        final outbox = Outbox(memory);
        await outbox.load();
        expect(outbox.entries.single.status, OutboxStatus.pending);
        await outbox.dispose();
      },
    );

    test('add ignores a second entry with the same id', () async {
      final memory = MemoryOutboxStore();
      final outbox = Outbox(memory);
      await outbox.add(entry('r1', payload: {'amountMinor': 1}));
      await outbox.add(entry('r1', payload: {'amountMinor': 2}));
      expect(outbox.entries.single.payload['amountMinor'], 1);
      expect(memory.saved, hasLength(1));
      await outbox.dispose();
    });

    test('every change is written through', () async {
      final memory = MemoryOutboxStore();
      final outbox = Outbox(memory);
      await outbox.add(entry('r1'));
      await outbox.add(entry('r2'));
      await outbox.remove(['r1']);
      expect(memory.saved.map((e) => e.id), ['r2']);
      await outbox.dispose();
    });
  });
}
