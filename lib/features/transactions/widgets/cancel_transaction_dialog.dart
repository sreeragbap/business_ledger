import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_button.dart';
import 'package:business_ledger/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Asks for confirmation (and an optional reason) before voiding a
/// transaction. Resolves the reason (possibly empty) on confirm, `null`
/// when dismissed.
Future<String?> showCancelTransactionDialog(BuildContext context) =>
    showDialog<String>(
      context: context,
      builder: (_) => const CancelTransactionDialog(),
    );

class CancelTransactionDialog extends StatefulWidget {
  const CancelTransactionDialog({super.key});

  /// `text(500)` in the functions schema.
  static const int maxReasonLength = 500;

  @override
  State<CancelTransactionDialog> createState() =>
      _CancelTransactionDialogState();
}

class _CancelTransactionDialogState extends State<CancelTransactionDialog> {
  final TextEditingController _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('Cancel this transaction?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'It stays in the history marked VOID, drops out of every '
              'report and balance, and any invoice, bill or receipt issued '
              'for it is voided too. This cannot be undone.',
              style: textTheme.bodyMedium,
            ),
            SizedBox(height: AppSpacing.lg.h),
            AppTextField(
              controller: _reason,
              label: 'Reason (optional)',
              hint: 'Entered twice, wrong customer…',
              maxLines: 3,
              minLines: 1,
              maxLength: CancelTransactionDialog.maxReasonLength,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
      actionsPadding: EdgeInsets.fromLTRB(
        AppSpacing.lg.w,
        0,
        AppSpacing.lg.w,
        AppSpacing.lg.h,
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: AppButton.secondary(
                label: 'Keep it',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            SizedBox(width: AppSpacing.md.w),
            Expanded(
              child: AppButton(
                label: 'Cancel it',
                destructive: true,
                icon: Icons.block_rounded,
                onPressed: () => Navigator.of(context).pop(_reason.text.trim()),
              ),
            ),
          ],
        ),
      ],
      iconColor: AppColors.error,
      icon: const Icon(Icons.warning_amber_rounded),
    );
  }
}
