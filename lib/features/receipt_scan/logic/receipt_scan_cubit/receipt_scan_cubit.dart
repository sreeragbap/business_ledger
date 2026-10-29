import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:business_ledger/core/bloc/close_guard.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/core/sync/cloud_availability.dart';
import 'package:business_ledger/features/categories/domain/models/category.dart';
import 'package:business_ledger/features/receipt_scan/domain/models/ocr_line.dart';
import 'package:business_ledger/features/receipt_scan/domain/models/receipt_scan.dart';
import 'package:business_ledger/features/receipt_scan/domain/repository/receipt_ai_repository.dart';
import 'package:business_ledger/features/receipt_scan/domain/repository/receipt_scanner_repository.dart';
import 'package:business_ledger/features/receipt_scan/domain/services/receipt_parser.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_dates.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'receipt_scan_state.dart';

/// Scan a receipt:
///
/// 1. the system document scanner or photo picker ([ReceiptScannerRepository]);
/// 2. on-device text recognition (fast, offline);
/// 3. Claude reads the text into fields and picks a category
///    ([ReceiptAiRepository]) when the cloud is reachable; the on-device
///    [ReceiptParser] fills what it leaves out, and stands in for it
///    offline or when it fails.
///
/// The form fills itself from [ReceiptScanState.scan].
@injectable
class ReceiptScanCubit extends Cubit<ReceiptScanState>
    with CloseGuard<ReceiptScanState> {
  ReceiptScanCubit(
    this._scanner,
    this._ai,
    this._cloud, {
    @ignoreParam DateTime Function()? now,
    @ignoreParam Duration? minReading,
  }) : _now = now ?? DateTime.now,
       _minReading = minReading ?? const Duration(milliseconds: 900),
       super(const ReceiptScanState());

  final ReceiptScannerRepository _scanner;
  final ReceiptAiRepository _ai;
  final CloudAvailability _cloud;
  final DateTime Function() _now;

  /// The reading animation stays up at least this long, so a fast device
  /// shows a calm transition instead of a flash.
  final Duration _minReading;

  /// Checks once whether the camera scanner works on this device.
  Future<void> init() async {
    final camera = await _scanner.canUseCamera();
    emit(state.copyWith(cameraAvailable: camera));
  }

  /// [categories] are the ones the entry may use.
  Future<void> scan(
    ReceiptSource source, {
    required Currency currency,
    required List<Category> categories,
  }) async {
    if (state.isBusy) return;
    emit(state.copyWith(phase: ReceiptScanPhase.capturing, message: ''));

    final captured = await _scanner.capture(source);
    final path = switch (captured) {
      Success(:final data) => data,
      Failure(:final error) => _fail(error.message),
    };
    if (path == null) {
      if (state.phase == ReceiptScanPhase.capturing) {
        emit(state.copyWith(phase: ReceiptScanPhase.idle));
      }
      return;
    }

    emit(state.copyWith(phase: ReceiptScanPhase.reading));
    final shownSince = _now();
    final List<OcrLine> lines;
    switch (await _scanner.recognize(path)) {
      case Failure(:final error):
        await _holdReading(shownSince);
        _fail(error.message);
        return;
      case Success(:final data):
        lines = data;
    }
    final now = _now();
    final onDevice = ReceiptParser.parse(lines, currency: currency, now: now);
    final rows = ReceiptParser.groupRows(lines);

    var scan = onDevice;
    if (rows.isNotEmpty && _cloud.isOnline) {
      emit(state.copyWith(phase: ReceiptScanPhase.understanding));
      final understood = await _ai.read(
        text: rows.join('\n'),
        currency: currency,
        today: LedgerDates.today(now),
        categories: categories,
      );
      if (understood case Success(:final data)) scan = data.orElse(onDevice);
    }
    await _holdReading(shownSince);
    emit(state.copyWith(phase: ReceiptScanPhase.done, scan: () => scan));
  }

  Future<void> _holdReading(DateTime since) async {
    final left = _minReading - _now().difference(since);
    if (left > Duration.zero) await Future<void>.delayed(left);
  }

  /// Back to idle once the form has used the result.
  void reset() => emit(
    state.copyWith(phase: ReceiptScanPhase.idle, scan: () => null, message: ''),
  );

  Null _fail(String message) {
    emit(state.copyWith(phase: ReceiptScanPhase.failed, message: message));
    return null;
  }

  @override
  Future<void> close() {
    beginClose();
    return super.close();
  }
}
