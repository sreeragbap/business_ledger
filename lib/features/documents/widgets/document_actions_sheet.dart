import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_radius.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_bottom_sheet.dart';
import 'package:business_ledger/core/widgets/app_card.dart';
import 'package:business_ledger/features/documents/domain/models/document_action.dart';
import 'package:business_ledger/features/documents/domain/models/issued_document.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shows [DocumentActionsSheet] and returns the action picked, if any.
Future<DocumentAction?> showDocumentActionsSheet({
  required BuildContext context,
  required DocumentSubject subject,
  required List<IssuedDocument> issued,
  required bool online,
}) => showAppBottomSheet<DocumentAction>(
  context: context,
  title: 'Documents',
  child: DocumentActionsSheet(
    subject: subject,
    issued: issued,
    online: online,
    onSelected: (action) => Navigator.of(context).pop(action),
  ),
);

/// The documents available for one transaction: its invoice or bill, and a
/// receipt per recorded payment. Unavailable ones stay visible, disabled,
/// with the reason, so the user knows what to do next.
class DocumentActionsSheet extends StatelessWidget {
  const DocumentActionsSheet({
    required this.subject,
    required this.issued,
    required this.online,
    required this.onSelected,
    super.key,
  });

  final DocumentSubject subject;
  final List<IssuedDocument> issued;
  final bool online;
  final ValueChanged<DocumentAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final actions = DocumentActions.forSubject(
      subject,
      issued: issued,
      online: online,
    );
    final textTheme = Theme.of(context).textTheme;

    if (actions.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg.h),
        child: Text(
          DocumentActions.emptyMessage(subject),
          style: textTheme.bodyMedium,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final action in actions) ...[
          _ActionTile(action: action, onTap: () => onSelected(action)),
          SizedBox(height: AppSpacing.sm.h),
        ],
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action, required this.onTap});

  final DocumentAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final enabled = action.enabled;
    final voided = action.existing?.voided ?? false;
    final colour = !enabled
        ? AppColors.textDisabled
        : voided
        ? AppColors.error
        : AppColors.accent;
    final icon = switch (action.type) {
      DocumentType.invoice => Icons.request_quote_outlined,
      DocumentType.bill => Icons.receipt_long_outlined,
      DocumentType.receipt => Icons.task_alt_rounded,
    };

    return Semantics(
      button: true,
      enabled: enabled,
      label: [
        action.title,
        action.subtitle,
        if (action.disabledReason != null) action.disabledReason!,
      ].join('. '),
      excludeSemantics: true,
      child: AppCard(
        onTap: enabled ? onTap : null,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md.w,
          vertical: AppSpacing.md.h,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.sm.r),
              decoration: BoxDecoration(
                color: AppColors.tint(colour),
                borderRadius: BorderRadius.circular(AppRadius.sm.r),
              ),
              child: Icon(icon, color: colour, size: 20.r),
            ),
            SizedBox(width: AppSpacing.md.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.title,
                    style: textTheme.titleSmall?.copyWith(
                      color: enabled ? null : AppColors.textDisabled,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxs.h),
                  Text(
                    action.disabledReason ?? action.subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: action.disabledReason != null
                          ? AppColors.warning
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              action.isIssued
                  ? Icons.chevron_right_rounded
                  : Icons.add_circle_outline_rounded,
              color: enabled ? AppColors.textSecondary : AppColors.textDisabled,
            ),
          ],
        ),
      ),
    );
  }
}
