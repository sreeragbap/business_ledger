import 'dart:async';

import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/widgets/app_error_state.dart';
import 'package:business_ledger/core/widgets/app_loader.dart';
import 'package:business_ledger/core/widgets/app_snack_bar.dart';
import 'package:business_ledger/features/documents/logic/document_cubit/document_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';

/// Previews the document held by [DocumentCubit], with share and print/save
/// actions. The PDF is rendered on the device; nothing is stored.
///
/// Takes its cubit from the tree. Open it after `open`/`issue`/`openById` has
/// been called on the cubit:
///
/// ```dart
/// BlocProvider.value(value: cubit, child: const DocumentPreviewScreen())
/// ```
///
/// The chrome is dark; the page itself stays white because it is what gets
/// printed.
class DocumentPreviewScreen extends StatelessWidget {
  const DocumentPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<DocumentCubit, DocumentState>(
      listenWhen: (previous, current) =>
          previous.shareStatus != current.shareStatus ||
          previous.printStatus != current.printStatus,
      listener: (context, state) {
        for (final status in [state.shareStatus, state.printStatus]) {
          if (status.isFailure && !(status.error?.isCancelled ?? false)) {
            showAppSnackBar(
              context,
              status.message,
              kind: AppSnackBarKind.error,
            );
          } else if (status.isSuccess && status.message.isNotEmpty) {
            showAppSnackBar(
              context,
              status.message,
              kind: AppSnackBarKind.success,
            );
          }
        }
      },
      child: BlocBuilder<DocumentCubit, DocumentState>(
        builder: (context, state) {
          final document = state.document;
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(document?.type.label ?? 'Document'),
                  if (document != null)
                    Text(
                      document.voided
                          ? '${document.number} · Void'
                          : document.number,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Print or save as PDF',
                  icon: const Icon(Icons.print_outlined),
                  onPressed: state.hasPdf && !state.isBusy
                      ? () => unawaited(
                          context.read<DocumentCubit>().printOrSave(),
                        )
                      : null,
                ),
                IconButton(
                  tooltip: 'Share',
                  icon: const Icon(Icons.ios_share_rounded),
                  onPressed: state.hasPdf && !state.isBusy
                      ? () => unawaited(context.read<DocumentCubit>().share())
                      : null,
                ),
              ],
            ),
            body: _Body(state: state),
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final DocumentState state;

  @override
  Widget build(BuildContext context) {
    final pdf = state.pdf;
    final document = state.document;
    final failure = [
      state.issueStatus,
      state.renderStatus,
    ].where((status) => status.isFailure).firstOrNull;

    if (pdf == null || document == null) {
      if (failure != null) {
        return AppErrorState(
          title: "Couldn't prepare this document",
          message: failure.message,
          onRetry: document == null
              ? null
              : () => unawaited(context.read<DocumentCubit>().open(document)),
        );
      }
      return const AppLoader();
    }

    return PdfPreview(
      key: ValueKey('${document.id}-${pdf.length}'),
      build: (_) async => pdf,
      useActions: false,
      canChangeOrientation: false,
      canChangePageFormat: false,
      canDebug: false,
      pdfFileName: document.fileName,
      scrollViewDecoration: const BoxDecoration(color: AppColors.background),
      pdfPreviewPageDecoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: [BoxShadow(color: AppColors.scrim, blurRadius: 12)],
      ),
      loadingWidget: const AppLoader(),
      onError: (context, error) => const AppErrorState(
        title: "Couldn't show the preview",
        message: 'Share or print still work.',
      ),
    );
  }
}
