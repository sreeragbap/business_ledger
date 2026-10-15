import 'dart:typed_data';

import 'package:business_ledger/features/documents/domain/repository/document_output.dart';
import 'package:injectable/injectable.dart';
import 'package:printing/printing.dart';

/// [DocumentOutput] over the `printing` plugin: the native share sheet and
/// the system print dialog (which also offers "Save as PDF").
@LazySingleton(as: DocumentOutput)
class PrintingDocumentOutput implements DocumentOutput {
  const PrintingDocumentOutput();

  @override
  Future<bool> share(Uint8List bytes, {required String fileName}) =>
      Printing.sharePdf(bytes: bytes, filename: fileName);

  @override
  Future<bool> printOrSave(Uint8List bytes, {required String name}) =>
      Printing.layoutPdf(onLayout: (_) async => bytes, name: name);
}
