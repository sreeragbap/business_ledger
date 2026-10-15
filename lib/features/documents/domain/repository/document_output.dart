import 'dart:typed_data';

/// Hands a rendered PDF to the platform: the share sheet, or the print /
/// save dialog.
abstract class DocumentOutput {
  const DocumentOutput();

  /// `false` when the user dismissed the sheet.
  Future<bool> share(Uint8List bytes, {required String fileName});

  /// `false` when the user dismissed the dialog.
  Future<bool> printOrSave(Uint8List bytes, {required String name});
}
