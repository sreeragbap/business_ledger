import 'dart:typed_data';

import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/widgets/app_error_state.dart';
import 'package:business_ledger/core/widgets/app_loader.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_results.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

/// Opens a stored attachment full screen: images zoomable, PDFs in the
/// same viewer the documents use (with share and print).
Future<void> showAttachmentPreview(
  BuildContext context, {
  required String path,
  required Future<AppResult<Uint8List>> Function() load,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (_) => AttachmentPreviewPage(path: path, load: load),
  ),
);

class AttachmentPreviewPage extends StatefulWidget {
  const AttachmentPreviewPage({
    required this.path,
    required this.load,
    super.key,
  });

  final String path;
  final Future<AppResult<Uint8List>> Function() load;

  @override
  State<AttachmentPreviewPage> createState() => _AttachmentPreviewPageState();
}

class _AttachmentPreviewPageState extends State<AttachmentPreviewPage> {
  late Future<AppResult<Uint8List>> _bytes = widget.load();

  @override
  Widget build(BuildContext context) {
    final name = PickedAttachment.displayName(widget.path);
    final isPdf = PickedAttachment.pathIsPdf(widget.path);
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: FutureBuilder<AppResult<Uint8List>>(
        future: _bytes,
        builder: (context, snapshot) {
          final result = snapshot.data;
          if (result == null) return const AppLoader();
          return result.when(
            failure: (error) => AppErrorState(
              message: error.message,
              onRetry: () => setState(() => _bytes = widget.load()),
            ),
            success: (bytes) => isPdf
                ? PdfPreview(
                    build: (_) => bytes,
                    canChangePageFormat: false,
                    canChangeOrientation: false,
                    canDebug: false,
                    pdfFileName: name,
                  )
                : InteractiveViewer(
                    maxScale: 5,
                    child: Center(
                      child: Image.memory(
                        bytes,
                        semanticLabel: name,
                        errorBuilder: (_, _, _) => const AppErrorState(
                          message: "This image can't be shown.",
                        ),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}
