import 'dart:async';

import 'package:business_ledger/features/documents/domain/models/issued_document.dart';
import 'package:business_ledger/features/documents/domain/pdf/document_fonts.dart';
import 'package:business_ledger/features/documents/domain/pdf/document_pdf_builder.dart';
import 'package:business_ledger/features/documents/domain/repository/document_renderer.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:printing/printing.dart';

/// Loads the document fonts once per process.
///
/// Noto Sans (via `PdfGoogleFonts`, cached on device after the first
/// download) draws ₹ € £ ¥. When it cannot be fetched (first run offline)
/// the built-in Helvetica is used and amounts carry the currency code.
@lazySingleton
class DocumentFontsLoader {
  /// Long enough for a slow connection, short enough not to stall a render.
  static const Duration timeout = Duration(seconds: 8);

  Future<DocumentFonts>? _unicode;

  Future<DocumentFonts> load() async {
    try {
      return await (_unicode ??= _loadUnicode());
    } catch (error) {
      // Retry the download next time rather than caching the failure.
      _unicode = null;
      debugPrint('Document fonts unavailable, using Helvetica: $error');
      return DocumentFonts.builtIn();
    }
  }

  static Future<DocumentFonts> _loadUnicode() async {
    final fonts = await Future.wait([
      PdfGoogleFonts.notoSansRegular(),
      PdfGoogleFonts.notoSansBold(),
    ]).timeout(timeout);
    return DocumentFonts.unicode(regular: fonts[0], bold: fonts[1]);
  }
}

@LazySingleton(as: DocumentRenderer)
class PdfDocumentRenderer implements DocumentRenderer {
  PdfDocumentRenderer(this._fonts);

  final DocumentFontsLoader _fonts;
  static const DocumentPdfBuilder _builder = DocumentPdfBuilder();

  @override
  Future<Uint8List> render(IssuedDocument document) async =>
      _builder.buildDocument(document, fonts: await _fonts.load());
}
