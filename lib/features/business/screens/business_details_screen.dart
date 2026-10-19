import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:business_ledger/core/di/injection.dart';
import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_button.dart';
import 'package:business_ledger/core/widgets/app_card.dart';
import 'package:business_ledger/core/widgets/app_confirm_dialog.dart';
import 'package:business_ledger/core/widgets/app_empty_state.dart';
import 'package:business_ledger/core/widgets/app_section.dart';
import 'package:business_ledger/core/widgets/app_snack_bar.dart';
import 'package:business_ledger/core/widgets/app_text_field.dart';
import 'package:business_ledger/features/business/domain/const/role.dart';
import 'package:business_ledger/features/business/domain/const/standard_field.dart';
import 'package:business_ledger/features/business/domain/models/business.dart';
import 'package:business_ledger/features/business/logic/business_scope_cubit/business_scope_cubit.dart';
import 'package:business_ledger/features/business/logic/business_settings_cubit/business_settings_cubit.dart';
import 'package:business_ledger/features/business/screens/create_business_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Business details and settings: name, description, time zone, which
/// standard sections the transaction form shows, document number prefixes,
/// and the contact details printed on documents. Admins edit; everyone else
/// sees the same screen read-only. The owner can archive the business.
///
/// Saving is local-first (queued in the outbox) and works offline.
@RoutePage()
class BusinessDetailsScreen extends StatelessWidget
    implements AutoRouteWrapper {
  const BusinessDetailsScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) =>
      BlocProvider<BusinessSettingsCubit>(
        create: (_) => getIt<BusinessSettingsCubit>(),
        child: this,
      );

  @override
  Widget build(BuildContext context) {
    final scope = context.watch<BusinessScopeCubit>().state;
    final business = scope.business;
    return Scaffold(
      appBar: AppBar(title: const Text('Business details')),
      body: business == null
          ? const AppEmptyState(title: 'No business selected')
          : _DetailsForm(
              // A different business (switched elsewhere) starts a new form.
              key: ValueKey(business.id),
              business: business,
              role: scope.role,
            ),
    );
  }
}

class _DetailsForm extends StatefulWidget {
  const _DetailsForm({required this.business, required this.role, super.key});

  final Business business;
  final Role role;

  @override
  State<_DetailsForm> createState() => _DetailsFormState();
}

class _DetailsFormState extends State<_DetailsForm> {
  late final Business _initial = widget.business;
  late final _name = TextEditingController(text: _initial.name);
  late final _description = TextEditingController(
    text: _initial.description,
  );
  late final _invoicePrefix = TextEditingController(
    text: _initial.settings.invoicePrefix,
  );
  late final _billPrefix = TextEditingController(
    text: _initial.settings.billPrefix,
  );
  late final _receiptPrefix = TextEditingController(
    text: _initial.settings.receiptPrefix,
  );
  late final _address = TextEditingController(text: _initial.settings.address);
  late final _phone = TextEditingController(text: _initial.settings.phone);
  late final _email = TextEditingController(text: _initial.settings.email);
  late final _taxId = TextEditingController(text: _initial.settings.taxId);
  late String _timezone = _initial.timezone;
  late List<String> _enabledKeys = _initial.settings.enabledStandardFieldKeys;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _description,
      _invoicePrefix,
      _billPrefix,
      _receiptPrefix,
      _address,
      _phone,
      _email,
      _taxId,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  BusinessSettings get _settings => widget.business.settings.copyWith(
    enabledStandardFieldKeys: _enabledKeys,
    invoicePrefix: _invoicePrefix.text,
    billPrefix: _billPrefix.text,
    receiptPrefix: _receiptPrefix.text,
    address: _address.text,
    phone: _phone.text,
    email: _email.text,
    taxId: _taxId.text,
  );

  void _toggleField(StandardField field, {required bool enabled}) {
    setState(() {
      _enabledKeys = BusinessSettings(
        enabledStandardFieldKeys: _enabledKeys,
      ).toggle(field, enabled: enabled).enabledStandardFieldKeys;
    });
  }

  void _save() {
    FocusScope.of(context).unfocus();
    unawaited(
      context.read<BusinessSettingsCubit>().save(
        widget.business.id,
        name: _name.text,
        description: _description.text,
        timezone: _timezone,
        settings: _settings,
      ),
    );
  }

  Future<void> _toggleArchive() async {
    final cubit = context.read<BusinessSettingsCubit>();
    final archiving = !widget.business.archived;
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: archiving ? 'Archive this business?' : 'Restore this business?',
      message: archiving
          ? 'It is hidden from your business list (you can still show '
                'archived ones) and nothing is deleted. You can restore it '
                'at any time.'
          : 'It shows in everyone’s business list again.',
      confirmLabel: archiving ? 'Archive' : 'Restore',
      destructive: archiving,
    );
    if (confirmed) {
      await cubit.setArchived(widget.business.id, archived: archiving);
    }
  }

  void _onState(BuildContext context, BusinessSettingsState state) {
    for (final status in [state.saveStatus, state.archiveStatus]) {
      if (status.isFailure && status.errors.isEmpty) {
        showAppSnackBar(context, status.message, kind: AppSnackBarKind.error);
      } else if (status.isSuccess) {
        showAppSnackBar(
          context,
          status.message,
          kind: AppSnackBarKind.success,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final canEdit = widget.role.canEditBusiness;
    final business = widget.business;
    return BlocConsumer<BusinessSettingsCubit, BusinessSettingsState>(
      listenWhen: (p, c) =>
          p.saveStatus != c.saveStatus || p.archiveStatus != c.archiveStatus,
      listener: _onState,
      builder: (context, state) {
        final errors = state.saveStatus;
        final enabled = canEdit && !state.saveStatus.isLoading;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal.w,
            AppSpacing.sm.h,
            AppSpacing.screenHorizontal.w,
            AppSpacing.huge.h,
          ),
          children: [
            if (!canEdit) ...[
              AppCard(
                child: Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 20.r),
                    SizedBox(width: AppSpacing.md.w),
                    Expanded(
                      child: Text(
                        'Only admins and the owner can change these.',
                        style: textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xxl.h),
            ],
            const AppSectionLabel('Details'),
            AppTextField(
              controller: _name,
              label: 'Name',
              enabled: enabled,
              maxLength: BusinessSettingsCubit.maxNameLength,
              textCapitalization: TextCapitalization.words,
              errorText: errors.errorFor('name'),
            ),
            SizedBox(height: AppSpacing.lg.h),
            AppTextField(
              controller: _description,
              label: 'Description',
              enabled: enabled,
              maxLines: 2,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
            ),
            SizedBox(height: AppSpacing.lg.h),
            Text('Time zone', style: textTheme.labelMedium),
            SizedBox(height: AppSpacing.sm.h),
            TimeZoneField(
              value: _timezone,
              enabled: enabled,
              onChanged: (zone) => setState(() => _timezone = zone),
            ),
            SizedBox(height: AppSpacing.md.h),
            Text(
              'Currency: ${business.currency.code} (fixed) · '
              'Started from: ${business.template.label}',
              style: textTheme.bodySmall,
            ),
            SizedBox(height: AppSpacing.xxl.h),
            const AppSectionLabel('Transaction form'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final field in StandardField.values)
                    SwitchListTile(
                      secondary: Icon(field.icon),
                      title: Text(field.label),
                      subtitle: Text(field.description),
                      value: _enabledKeys.contains(field.key),
                      onChanged: enabled
                          ? (on) => _toggleField(field, enabled: on)
                          : null,
                    ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.xxl.h),
            const AppSectionLabel('Document numbers'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (index, (label, controller, key)) in [
                  ('Invoice', _invoicePrefix, 'invoicePrefix'),
                  ('Bill', _billPrefix, 'billPrefix'),
                  ('Receipt', _receiptPrefix, 'receiptPrefix'),
                ].indexed) ...[
                  if (index > 0) SizedBox(width: AppSpacing.md.w),
                  Expanded(
                    child: AppTextField(
                      controller: controller,
                      label: label,
                      enabled: enabled,
                      maxLength: BusinessSettingsCubit.maxPrefixLength,
                      textCapitalization: TextCapitalization.characters,
                      errorText: errors.errorFor(key),
                      // Keeps the example number below in step.
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: AppSpacing.xs.h),
            Text(
              'Numbers look like ${_invoicePrefix.text.trim()}-2026-0001 and '
              'never repeat or skip.',
              style: textTheme.bodySmall,
            ),
            SizedBox(height: AppSpacing.xxl.h),
            const AppSectionLabel('On invoices and receipts'),
            AppTextField(
              controller: _address,
              label: 'Address',
              enabled: enabled,
              maxLines: 3,
              minLines: 2,
              maxLength: 300,
            ),
            SizedBox(height: AppSpacing.lg.h),
            AppTextField(
              controller: _phone,
              label: 'Phone',
              enabled: enabled,
              keyboardType: TextInputType.phone,
              maxLength: 30,
            ),
            SizedBox(height: AppSpacing.lg.h),
            AppTextField(
              controller: _email,
              label: 'Email',
              enabled: enabled,
              keyboardType: TextInputType.emailAddress,
              maxLength: 120,
            ),
            SizedBox(height: AppSpacing.lg.h),
            AppTextField(
              controller: _taxId,
              label: 'Tax ID (GSTIN, VAT no.)',
              enabled: enabled,
              textCapitalization: TextCapitalization.characters,
              maxLength: 40,
            ),
            if (canEdit) ...[
              SizedBox(height: AppSpacing.xxl.h),
              AppButton(
                label: 'Save changes',
                isLoading: state.saveStatus.isLoading,
                onPressed: _save,
              ),
            ],
            if (widget.role.canArchiveBusiness) ...[
              SizedBox(height: AppSpacing.huge.h),
              const AppSectionLabel('Danger zone'),
              AppCard(
                borderColor: AppColors.error.withValues(alpha: 0.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      business.archived
                          ? 'This business is archived.'
                          : 'Archive this business',
                      style: textTheme.titleSmall,
                    ),
                    SizedBox(height: AppSpacing.xs.h),
                    Text(
                      'Archiving hides it from business lists. Its records '
                      'stay intact and members keep access.',
                      style: textTheme.bodyMedium,
                    ),
                    SizedBox(height: AppSpacing.md.h),
                    AppButton.secondary(
                      label: business.archived ? 'Restore' : 'Archive',
                      destructive: !business.archived,
                      isLoading: state.archiveStatus.isLoading,
                      onPressed: () => unawaited(_toggleArchive()),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
