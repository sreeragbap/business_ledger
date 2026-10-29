import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:business_ledger/core/theme/app_radius.dart';
import 'package:business_ledger/features/transactions/logic/transaction_form_cubit/transaction_form_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Makes a form field glow briefly after a receipt scan filled it. Fields
/// light up one after another, top to bottom, then fade.
class ReceiptFillHighlight extends StatelessWidget {
  const ReceiptFillHighlight({
    required this.field,
    required this.child,
    super.key,
  });

  /// The field's key in `TransactionFormState.receiptFilled`.
  final String field;
  final Widget child;

  /// Top-to-bottom order on the form, for the cascade.
  static const List<String> _order = [
    'totalMinor',
    'receiptDate',
    'categoryId',
    'partyId',
    'description',
    'reference',
    'paymentMethod',
    'notes',
  ];
  static const int _stepMs = 110;
  static const int _glowMs = 1800;

  @override
  Widget build(BuildContext context) {
    final (filled, revision) = context
        .select<TransactionFormCubit, (bool, int)>(
          (cubit) => (
            cubit.state.receiptFilled.contains(field),
            cubit.state.formRevision,
          ),
        );
    if (!filled) return child;

    final delay = _order.indexOf(field).clamp(0, _order.length) * _stepMs;
    final total = delay + _glowMs;
    final accent = context.colors.accent;
    final radius = BorderRadius.circular(AppRadius.md.r);
    return TweenAnimationBuilder<double>(
      key: ValueKey(revision),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      builder: (context, progress, child) {
        // 0 until its turn, a quick rise, then a slow fade.
        final local = ((progress * total - delay) / _glowMs).clamp(0.0, 1.0);
        final glow = local < 0.15
            ? Curves.easeOut.transform(local / 0.15)
            : 1 - Curves.easeInCubic.transform((local - 0.15) / 0.85);
        return DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: accent.withValues(alpha: glow),
              width: 1.5,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.3 * glow),
                  blurRadius: 18 * glow,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
