import 'dart:typed_data';

import 'package:business_ledger/features/documents/domain/models/document_layout_data.dart';
import 'package:business_ledger/features/documents/domain/models/issued_document.dart';
import 'package:business_ledger/features/documents/domain/pdf/document_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Draws an invoice, bill or receipt.
///
/// Pure: takes the [DocumentLayoutData] (every figure already formatted) and
/// the fonts, returns PDF bytes. Light and printable on purpose: documents
/// leave the app, the dark theme does not.
class DocumentPdfBuilder {
  const DocumentPdfBuilder({
    this.pageFormat = PdfPageFormat.a4,
    this.compress = true,
  });

  final PdfPageFormat pageFormat;

  /// Deflate page content. Off only in tests, to inspect the drawn text.
  final bool compress;

  static const PdfColor _ink = PdfColor.fromInt(0xFF1F2328);
  static const PdfColor _muted = PdfColor.fromInt(0xFF5F6670);
  static const PdfColor _line = PdfColor.fromInt(0xFFD8DCE1);
  static const PdfColor _band = PdfColor.fromInt(0xFFF3F5F7);
  static const PdfColor _accent = PdfColor.fromInt(0xFF0F766E);
  static const PdfColor _void = PdfColor.fromInt(0x33D92D20);

  /// Lays out [document] and renders it with [fonts].
  Future<Uint8List> buildDocument(
    IssuedDocument document, {
    required DocumentFonts fonts,
    DateTime? today,
  }) => build(
    DocumentLayoutData.from(
      document,
      canRender: fonts.canRender,
      today: today,
    ),
    fonts: fonts,
  );

  Future<Uint8List> build(
    DocumentLayoutData data, {
    required DocumentFonts fonts,
  }) {
    final s = fonts.sanitise;
    final pdf = pw.Document(
      title: s('${data.title} ${data.number}'),
      author: s(data.businessName),
      creator: 'Business Ledger',
      compress: compress,
    );

    final theme = pw.ThemeData.withFont(
      base: fonts.regular,
      bold: fonts.bold,
      fontFallback: fonts.fallback,
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.fromLTRB(40, 40, 40, 32),
          theme: theme.copyWith(
            defaultTextStyle: pw.TextStyle(
              font: fonts.regular,
              fontBold: fonts.bold,
              fontFallback: fonts.fallback,
              fontSize: 10,
              color: _ink,
              lineSpacing: 1.5,
            ),
          ),
          buildForeground: data.voided
              ? (context) => pw.Center(
                  child: pw.Transform.rotate(
                    angle: 0.6,
                    child: pw.Text(
                      'VOID',
                      style: pw.TextStyle(
                        font: fonts.bold,
                        fontSize: 140,
                        color: _void,
                        letterSpacing: 12,
                      ),
                    ),
                  ),
                )
              : null,
        ),
        footer: (context) => _footer(context, data, s),
        build: (context) => [
          _header(data, s),
          pw.SizedBox(height: 24),
          _parties(data, s),
          pw.SizedBox(height: 24),
          if (data.isReceipt) ...[
            _receipt(data, s),
            pw.SizedBox(height: 20),
            pw.Text(
              s('FOR'),
              style: const pw.TextStyle(color: _muted, fontSize: 8),
            ),
            pw.SizedBox(height: 6),
          ],
          _lineItems(data, s),
          pw.SizedBox(height: 12),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(width: 240, child: _rows(data.totals, s)),
          ),
          if (data.notes.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            pw.Text(
              'NOTES',
              style: const pw.TextStyle(color: _muted, fontSize: 8),
            ),
            pw.SizedBox(height: 4),
            pw.Text(s(data.notes)),
          ],
        ],
      ),
    );
    return pdf.save();
  }

  pw.Widget _header(DocumentLayoutData data, String Function(String) s) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                s(data.businessName),
                style: const pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              for (final line in data.businessLines)
                pw.Text(
                  s(line),
                  style: const pw.TextStyle(color: _muted, fontSize: 9),
                ),
            ],
          ),
        ),
        pw.SizedBox(width: 24),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              s(data.title),
              style: const pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: _accent,
                letterSpacing: 2,
              ),
            ),
            pw.SizedBox(height: 8),
            for (final row in data.details)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(
                      s(row.label),
                      style: const pw.TextStyle(color: _muted, fontSize: 9),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Text(
                      s(row.value),
                      style: const pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  pw.Widget _parties(DocumentLayoutData data, String Function(String) s) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(
        color: _band,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            s(data.partyHeading.toUpperCase()),
            style: const pw.TextStyle(color: _muted, fontSize: 8),
          ),
          pw.SizedBox(height: 4),
          if (data.partyLines.isEmpty)
            pw.Text('-', style: const pw.TextStyle(color: _muted))
          else ...[
            pw.Text(
              s(data.partyLines.first),
              style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            for (final line in data.partyLines.skip(1))
              pw.Text(
                s(line),
                style: const pw.TextStyle(color: _muted, fontSize: 9),
              ),
          ],
        ],
      ),
    );
  }

  pw.Widget _receipt(DocumentLayoutData data, String Function(String) s) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _accent),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: _rows(data.receipt, s),
    );
  }

  pw.Widget _lineItems(DocumentLayoutData data, String Function(String) s) {
    const header = pw.TextStyle(color: _muted, fontSize: 8);
    pw.Widget cell(
      String text, {
      pw.TextStyle? style,
      pw.Alignment align = pw.Alignment.centerLeft,
    }) => pw.Container(
      alignment: align,
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Text(s(text), style: style),
    );

    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(5),
        1: pw.FlexColumnWidth(1.2),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2.2),
      },
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _line, width: 0.5),
        bottom: pw.BorderSide(color: _line, width: 0.5),
      ),
      children: [
        pw.TableRow(
          repeat: true,
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _ink)),
          ),
          children: [
            cell('DESCRIPTION', style: header),
            cell('QTY', style: header, align: pw.Alignment.centerRight),
            cell('RATE', style: header, align: pw.Alignment.centerRight),
            cell('AMOUNT', style: header, align: pw.Alignment.centerRight),
          ],
        ),
        for (final line in data.lines)
          pw.TableRow(
            children: [
              cell(line.description),
              cell(line.quantity, align: pw.Alignment.centerRight),
              cell(line.rate, align: pw.Alignment.centerRight),
              cell(line.amount, align: pw.Alignment.centerRight),
            ],
          ),
      ],
    );
  }

  pw.Widget _rows(List<LayoutRow> rows, String Function(String) s) {
    return pw.Column(
      children: [
        for (final row in rows)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 3),
            decoration: row.emphasis
                ? const pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(color: _ink)),
                  )
                : null,
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Text(
                    s(row.label),
                    style: row.emphasis
                        ? const pw.TextStyle(fontWeight: pw.FontWeight.bold)
                        : const pw.TextStyle(color: _muted),
                  ),
                ),
                pw.Text(
                  s(row.value),
                  style: row.emphasis
                      ? const pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        )
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  pw.Widget _footer(
    pw.Context context,
    DocumentLayoutData data,
    String Function(String) s,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _line, width: 0.5)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              s(data.voided ? 'This document is void.' : data.footer),
              style: const pw.TextStyle(color: _muted, fontSize: 8),
            ),
          ),
          pw.Text(
            s(
              '${data.number}  ·  Page ${context.pageNumber} of '
              '${context.pagesCount}',
            ),
            style: const pw.TextStyle(color: _muted, fontSize: 8),
          ),
        ],
      ),
    );
  }
}
