import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

/// Where the outbox lives: `<app support>/sync`.
///
/// App support rather than documents (not user-visible, backed up on iOS)
/// or cache (the OS may purge it, and losing the outbox loses actions).
@lazySingleton
class SyncDirectory {
  SyncDirectory() : _resolve = _appSupport;

  /// A fixed directory, for tests.
  SyncDirectory.at(Directory directory) : _resolve = (() async => directory);

  final Future<Directory> Function() _resolve;
  Future<Directory>? _root;

  static Future<Directory> _appSupport() async =>
      Directory('${(await getApplicationSupportDirectory()).path}/sync');

  /// Created on first use.
  Future<Directory> get root => _root ??= () async {
    final directory = await _resolve();
    await directory.create(recursive: true);
    return directory;
  }();
}
