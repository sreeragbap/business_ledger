part of 'receipt_scan_cubit.dart';

enum ReceiptScanPhase {
  idle,

  /// The system scanner or photo picker is open.
  capturing,

  /// Recognising text on the device: the form shows the reading animation.
  reading,

  /// Claude is reading the text into fields.
  understanding,

  /// [ReceiptScanState.scan] is ready for review.
  done,
  failed,
}

class ReceiptScanState extends Equatable {
  const ReceiptScanState({
    this.phase = ReceiptScanPhase.idle,
    this.scan,
    this.message = '',
    this.cameraAvailable = true,
  });

  final ReceiptScanPhase phase;
  final ReceiptScan? scan;

  /// Why the last scan failed.
  final String message;

  /// The camera scanner works here (the iOS simulator has none).
  final bool cameraAvailable;

  bool get isBusy => phase == ReceiptScanPhase.capturing || isReading;

  /// The reading animation is up.
  bool get isReading =>
      phase == ReceiptScanPhase.reading ||
      phase == ReceiptScanPhase.understanding;

  ReceiptScanState copyWith({
    ReceiptScanPhase? phase,
    ReceiptScan? Function()? scan,
    String? message,
    bool? cameraAvailable,
  }) => ReceiptScanState(
    phase: phase ?? this.phase,
    scan: scan == null ? this.scan : scan(),
    message: message ?? this.message,
    cameraAvailable: cameraAvailable ?? this.cameraAvailable,
  );

  @override
  List<Object?> get props => [phase, scan, message, cameraAvailable];
}
