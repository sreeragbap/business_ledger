import 'dart:convert';
import 'dart:io';

import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/features/receipt_scan/domain/models/ocr_line.dart';
import 'package:business_ledger/features/receipt_scan/domain/models/receipt_scan.dart';
import 'package:business_ledger/features/receipt_scan/domain/repository/receipt_scanner_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

/// [ReceiptScannerRepository] over the app's own platform channel:
///
/// * iOS: VisionKit's document camera or the photo picker, then Vision text
///   recognition (`ios/Runner/ReceiptScanner.swift`).
/// * Android: ML Kit's document scanner or the photo picker, then ML Kit
///   text recognition (`MainActivity.kt` / `ReceiptScanner.kt`).
@LazySingleton(as: ReceiptScannerRepository)
class ReceiptScannerService implements ReceiptScannerRepository {
  ReceiptScannerService();

  static const MethodChannel _channel = MethodChannel(
    'business_ledger/receipt_scanner',
  );

  @override
  Future<bool> canUseCamera() async {
    try {
      final info = await _channel.invokeMapMethod<String, Object?>(
        'capabilities',
      );
      return info?['camera'] == true;
    } on Object {
      return false;
    }
  }

  @override
  Future<AppResult<String?>> capture(ReceiptSource source) async {
    try {
      final path = await _channel.invokeMethod<String>('capture', {
        'source': source.name,
      });
      return Success(path);
    } on PlatformException catch (error) {
      return Failure(_fromPlatform(error));
    } on MissingPluginException {
      return const Failure(_unavailable);
    }
  }

  @override
  Future<AppResult<List<OcrLine>>> recognize(String path) async {
    try {
      final lines = await _channel.invokeListMethod<Object?>('recognize', {
        'path': path,
      });
      final read = [
        for (final line in lines ?? const <Object?>[])
          if (line is Map) OcrLine.fromMap(line),
      ];
      if (kDebugMode) await _keepForDebugging(path, read);
      return Success(read);
    } on PlatformException catch (error) {
      return Failure(_fromPlatform(error));
    } on MissingPluginException {
      return const Failure(_unavailable);
    } finally {
      await _delete(path);
    }
  }

  /// Debug builds only: the last scan's recognised lines (text and boxes,
  /// never the image) beside it in the cache, as
  /// `last_scan_ocr.json`, so a receipt that reads wrongly can be replayed
  /// in a test.
  static Future<void> _keepForDebugging(
    String path,
    List<OcrLine> lines,
  ) async {
    try {
      final file = File('${File(path).parent.path}/last_scan_ocr.json');
      await file.writeAsString(
        jsonEncode([
          for (final line in lines)
            {
              'text': line.text,
              'left': line.left,
              'top': line.top,
              'right': line.right,
              'bottom': line.bottom,
            },
        ]),
      );
    } on Object {
      // Only a debugging aid.
    }
  }

  static Future<void> _delete(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } on Object {
      // A temp file the system clears anyway.
    }
  }

  static const AppException _unavailable = AppException(
    kind: AppErrorKind.unknown,
    message: "Scanning isn't available on this device. Choose a photo instead.",
    code: 'unavailable',
  );

  static AppException _fromPlatform(PlatformException error) =>
      switch (error.code) {
        'unavailable' => _unavailable,
        'busy' => const AppException(
          kind: AppErrorKind.unknown,
          message: 'A scan is already open.',
          code: 'busy',
        ),
        _ => AppException(
          kind: AppErrorKind.unknown,
          message: "Couldn't read the receipt. Please try again.",
          code: error.code,
          cause: error.message,
        ),
      };
}
