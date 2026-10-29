import 'dart:async';

import 'package:business_ledger/core/widgets/app_snack_bar.dart';
import 'package:business_ledger/features/receipt_scan/domain/models/receipt_scan.dart';
import 'package:business_ledger/features/receipt_scan/logic/receipt_scan_cubit/receipt_scan_cubit.dart';
import 'package:business_ledger/features/receipt_scan/widgets/receipt_reading_overlay.dart';
import 'package:business_ledger/features/receipt_scan/widgets/receipt_source_sheet.dart';
import 'package:business_ledger/features/transactions/logic/transaction_form_cubit/transaction_form_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Asks for the receipt's source and starts the scan. The result lands in
/// [ReceiptScanScope], which fills the form.
Future<void> startReceiptScan(BuildContext context) async {
  final scanner = context.read<ReceiptScanCubit>();
  final form = context.read<TransactionFormCubit>();
  if (scanner.state.isBusy) return;
  final source = await showReceiptSourceSheet(
    context,
    cameraAvailable: scanner.state.cameraAvailable,
  );
  if (source == null) return;
  FocusManager.instance.primaryFocus?.unfocus();
  await scanner.scan(
    source,
    currency: form.state.currency,
    categories: form.state.availableCategories,
  );
}

/// Wraps the transaction form: shows the reading overlay over it while a
/// receipt is read, then fills the form at once.
class ReceiptScanScope extends StatelessWidget {
  const ReceiptScanScope({required this.child, super.key});

  final Widget child;

  static const String _nothingFound =
      "Couldn't find any details on that receipt. Try again with the whole "
      'receipt in view and good light.';

  Future<void> _onResult(BuildContext context, ReceiptScanState state) async {
    final scanner = context.read<ReceiptScanCubit>();
    final form = context.read<TransactionFormCubit>();
    switch (state.phase) {
      case ReceiptScanPhase.done:
        final scan = state.scan;
        scanner.reset();
        final result = scan == null
            ? (filled: 0, addedSupplier: null)
            : await form.applyReceipt(scan);
        if (!context.mounted) return;
        final count = result.filled;
        if (count == 0) {
          showAppSnackBar(
            context,
            _nothingFound,
            icon: Icons.receipt_long_outlined,
          );
          return;
        }
        unawaited(HapticFeedback.lightImpact());
        final ai = scan!.reader == ReceiptReader.ai;
        showAppSnackBar(
          context,
          'Filled $count detail${count == 1 ? '' : 's'} from the receipt'
          '${ai ? ' with AI' : ''}'
          '${result.addedSupplier == null ? '' : ' and added '
                    '${result.addedSupplier} as a supplier'}'
          '. Check them before saving.',
          kind: AppSnackBarKind.success,
          icon: ai ? Icons.auto_awesome_rounded : null,
          duration: const Duration(seconds: 6),
        );
      case ReceiptScanPhase.failed:
        scanner.reset();
        showAppSnackBar(context, state.message, kind: AppSnackBarKind.error);
      case ReceiptScanPhase.idle ||
          ReceiptScanPhase.capturing ||
          ReceiptScanPhase.reading ||
          ReceiptScanPhase.understanding:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReceiptScanCubit, ReceiptScanState>(
      listenWhen: (p, c) =>
          p.phase != c.phase &&
          (c.phase == ReceiptScanPhase.done ||
              c.phase == ReceiptScanPhase.failed),
      listener: (context, state) => unawaited(_onResult(context, state)),
      child: Stack(
        children: [
          child,
          Positioned.fill(
            child:
                BlocSelector<
                  ReceiptScanCubit,
                  ReceiptScanState,
                  ReceiptScanPhase
                >(
                  selector: (state) => state.phase,
                  builder: (context, phase) =>
                      ReceiptReadingOverlay(phase: phase),
                ),
          ),
        ],
      ),
    );
  }
}
