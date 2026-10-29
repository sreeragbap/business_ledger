import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/features/receipt_scan/domain/models/ocr_line.dart';
import 'package:business_ledger/features/receipt_scan/domain/models/receipt_scan.dart';

/// The platform's receipt scanner and text recogniser, on the device (no
/// network, no stored files).
abstract class ReceiptScannerRepository {
  /// Whether [ReceiptSource.camera] works here (not on the iOS simulator).
  Future<bool> canUseCamera();

  /// Opens the system document scanner or photo picker and returns the
  /// path of a temporary image, or `Success(null)` when the user backs out.
  Future<AppResult<String?>> capture(ReceiptSource source);

  /// The text lines in the image at [path]. The image is deleted afterwards,
  /// read or not.
  Future<AppResult<List<OcrLine>>> recognize(String path);
}
