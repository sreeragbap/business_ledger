import 'dart:async';

import 'package:business_ledger/core/theme/app_motion.dart';
import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:business_ledger/features/receipt_scan/logic/receipt_scan_cubit/receipt_scan_cubit.dart';
import 'package:business_ledger/features/transactions/logic/transaction_form_cubit/transaction_form_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The app bar's "Scan receipt" action. Its icon morphs: scanner → spinner
/// while a scan runs → a check for a moment after it fills the form.
class ReceiptScanButton extends StatefulWidget {
  const ReceiptScanButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  State<ReceiptScanButton> createState() => _ReceiptScanButtonState();
}

class _ReceiptScanButtonState extends State<ReceiptScanButton> {
  static const Duration _checkFor = Duration(milliseconds: 1600);

  bool _justFilled = false;
  Timer? _timer;

  void _flashCheck() {
    _timer?.cancel();
    setState(() => _justFilled = true);
    _timer = Timer(_checkFor, () {
      if (mounted) setState(() => _justFilled = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.select<ReceiptScanCubit, bool>(
      (cubit) => cubit.state.isBusy,
    );
    final colors = context.colors;
    final icon = busy
        ? SizedBox.square(
            key: const ValueKey('busy'),
            dimension: 20.r,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.accent,
            ),
          )
        : _justFilled
        ? Icon(
            Icons.check_circle_rounded,
            key: const ValueKey('done'),
            color: colors.accent,
          )
        : const Icon(
            Icons.document_scanner_outlined,
            key: ValueKey('scan'),
          );

    return BlocListener<TransactionFormCubit, TransactionFormState>(
      listenWhen: (p, c) =>
          p.formRevision != c.formRevision && c.receiptFilled.isNotEmpty,
      listener: (_, _) => _flashCheck(),
      // Pops in when the form appears.
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.6, end: 1),
        duration: AppMotion.slow,
        curve: Curves.easeOutBack,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: IconButton(
          tooltip: 'Scan receipt',
          onPressed: busy ? null : widget.onPressed,
          icon: AnimatedSwitcher(
            duration: AppMotion.medium,
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: Tween<double>(begin: 0.5, end: 1).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: icon,
          ),
        ),
      ),
    );
  }
}
