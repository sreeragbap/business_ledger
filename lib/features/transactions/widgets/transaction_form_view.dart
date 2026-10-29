import 'dart:async';

import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/money/money.dart';
import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_motion.dart';
import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:business_ledger/core/theme/app_radius.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/theme/app_text_styles.dart';
import 'package:business_ledger/core/widgets/app_button.dart';
import 'package:business_ledger/core/widgets/app_card.dart';
import 'package:business_ledger/core/widgets/app_discard_guard.dart';
import 'package:business_ledger/core/widgets/app_error_state.dart';
import 'package:business_ledger/core/widgets/app_loader.dart';
import 'package:business_ledger/core/widgets/app_money_field.dart';
import 'package:business_ledger/core/widgets/app_section.dart';
import 'package:business_ledger/core/widgets/app_snack_bar.dart';
import 'package:business_ledger/core/widgets/app_text_field.dart';
import 'package:business_ledger/features/business/domain/const/standard_field.dart';
import 'package:business_ledger/features/parties/domain/const/party_kind.dart';
import 'package:business_ledger/features/parties/widgets/party_form_sheet.dart';
import 'package:business_ledger/features/receipt_scan/widgets/receipt_fill_highlight.dart';
import 'package:business_ledger/features/receipt_scan/widgets/receipt_scan_button.dart';
import 'package:business_ledger/features/receipt_scan/widgets/receipt_scan_scope.dart';
import 'package:business_ledger/features/transactions/domain/const/transaction_filters.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_draft.dart';
import 'package:business_ledger/features/transactions/logic/transaction_form_cubit/transaction_form_cubit.dart';
import 'package:business_ledger/features/transactions/widgets/ledger_date_field.dart';
import 'package:business_ledger/features/transactions/widgets/option_sheet.dart';
import 'package:business_ledger/features/transactions/widgets/transaction_form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The create / edit form body over [TransactionFormCubit]. The caller
/// decides where to go when it finishes ([onDone]).
class TransactionFormView extends StatelessWidget {
  const TransactionFormView({
    required this.onDone,
    super.key,
  });

  final void Function(TransactionFormOutcome outcome, String transactionId)
  onDone;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<TransactionFormCubit, TransactionFormState>(
          listenWhen: (p, c) => p.outcome != c.outcome && c.outcome != null,
          listener: (context, state) => onDone(state.outcome!, state.draft!.id),
        ),
        BlocListener<TransactionFormCubit, TransactionFormState>(
          listenWhen: (p, c) =>
              p.saveStatus != c.saveStatus &&
              c.saveStatus.isFailure &&
              !c.hasConflict,
          listener: (context, state) => showAppSnackBar(
            context,
            state.saveStatus.message,
            kind: AppSnackBarKind.error,
          ),
        ),
      ],
      // Leaving with unsaved changes asks first. Mode is selected too: an
      // edit is still "create" until the stored entry has loaded.
      child:
          BlocSelector<
            TransactionFormCubit,
            TransactionFormState,
            (bool, TransactionFormMode)
          >(
            selector: (state) => (state.hasUnsavedChanges, state.mode),
            builder: (context, selected) => AppDiscardGuard(
              hasChanges: selected.$1,
              hasChangesNow: () =>
                  context.read<TransactionFormCubit>().state.hasUnsavedChanges,
              title: selected.$2 == TransactionFormMode.create
                  ? 'Discard this transaction?'
                  : 'Discard your changes?',
              message: selected.$2 == TransactionFormMode.create
                  ? 'What you entered will be lost.'
                  : 'Your edits will be lost.',
              child: BlocBuilder<TransactionFormCubit, TransactionFormState>(
                buildWhen: (p, c) =>
                    p.mode != c.mode ||
                    p.loadStatus != c.loadStatus ||
                    (p.draft == null) != (c.draft == null),
                builder: (context, state) {
                  final title = switch (state.mode) {
                    TransactionFormMode.create => 'New transaction',
                    TransactionFormMode.editDraft => 'Edit draft',
                    TransactionFormMode.editConfirmed => 'Edit transaction',
                  };
                  // A receipt can fill a new entry or a draft; a confirmed
                  // one changes field by field.
                  final canScan = state.draft != null && !state.isConfirmedEdit;
                  return ReceiptScanScope(
                    child: Scaffold(
                      appBar: AppBar(
                        title: Text(title),
                        actions: [
                          if (canScan)
                            ReceiptScanButton(
                              onPressed: () =>
                                  unawaited(startReceiptScan(context)),
                            ),
                        ],
                      ),
                      body: state.draft != null
                          ? const _Form()
                          : state.loadStatus.isFailure
                          ? AppErrorState(message: state.loadStatus.message)
                          : const AppLoader(),
                      bottomNavigationBar: state.draft == null
                          ? null
                          : const _ActionBar(),
                    ),
                  );
                },
              ),
            ),
          ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TransactionFormCubit>();
    return BlocBuilder<TransactionFormCubit, TransactionFormState>(
      builder: (context, state) {
        final draft = state.draft!;
        final errors = state.errors;
        final gap = SizedBox(height: AppSpacing.lg.h);
        final sectionGap = SizedBox(height: AppSpacing.xxl.h);
        final locked = state.isConfirmedEdit;
        final type = draft.type;
        final direction = draft.resolvedDirection;
        final category = state.selectedCategory;
        final partyKind = direction == Direction.outflow
            ? PartyKind.supplier
            : PartyKind.customer;

        return ListView(
          // Rebuilt from scratch when a reload brings a new version, or a
          // receipt fills the fields from outside.
          key: ValueKey(
            'form-${draft.id}-${state.original?.version}-'
            '${state.formRevision}',
          ),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal.w,
            AppSpacing.sm.h,
            AppSpacing.screenHorizontal.w,
            AppSpacing.huge.h,
          ),
          children: [
            if (state.hasConflict) ...[
              _ConflictCard(onReload: () => unawaited(cubit.reload())),
              gap,
            ],
            const AppSectionLabel('Type'),
            TransactionTypePicker(
              selected: type,
              enabled: !locked,
              onChanged: cubit.setType,
            ),
            if (locked)
              Padding(
                padding: EdgeInsets.only(top: AppSpacing.xs.h),
                child: Text(
                  'Type and direction are fixed once confirmed.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (type.fixedDirection == null) ...[
              gap,
              SegmentedButton<Direction>(
                segments: [
                  ButtonSegment(
                    value: Direction.inflow,
                    label: const Text('Money in'),
                    icon: Icon(Icons.south_west_rounded, size: 18.r),
                  ),
                  ButtonSegment(
                    value: Direction.outflow,
                    label: const Text('Money out'),
                    icon: Icon(Icons.north_east_rounded, size: 18.r),
                  ),
                ],
                emptySelectionAllowed: true,
                showSelectedIcon: false,
                selected: {?direction},
                onSelectionChanged: locked
                    ? null
                    : (selection) {
                        if (selection.isNotEmpty) {
                          cubit.setDirection(selection.first);
                        }
                      },
              ),
              if (errors['direction'] case final error?) _ErrorText(error),
            ],
            sectionGap,
            const AppSectionLabel('Amount'),
            const ReceiptFillHighlight(
              field: 'totalMinor',
              child: _AmountSection(),
            ),
            sectionGap,
            const AppSectionLabel('When'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ReceiptFillHighlight(
                    field: 'date',
                    child: LedgerDateField(
                      label: 'Date',
                      value: draft.date,
                      errorText: errors['date'],
                      onChanged: (day) {
                        if (day != null) cubit.setDate(day);
                      },
                    ),
                  ),
                ),
                if (state.showsDueDate) ...[
                  SizedBox(width: AppSpacing.md.w),
                  Expanded(
                    child: LedgerDateField(
                      label: 'Due date',
                      hint: 'Optional',
                      value: draft.dueDate,
                      first: draft.date,
                      clearable: true,
                      errorText: errors['dueDate'],
                      onChanged: cubit.setDueDate,
                    ),
                  ),
                ],
              ],
            ),
            // Only once a scan found it: the date printed on the receipt,
            // beside the day the entry is made.
            if (draft.receiptDate != null) ...[
              gap,
              ReceiptFillHighlight(
                field: 'receiptDate',
                child: LedgerDateField(
                  label: 'Receipt date',
                  value: draft.receiptDate,
                  first: '2000-01-01',
                  clearable: true,
                  helperText: 'As printed on the scanned receipt',
                  onChanged: cubit.setReceiptDate,
                ),
              ),
            ],
            sectionGap,
            const AppSectionLabel('Details'),
            ReceiptFillHighlight(
              field: 'categoryId',
              child: PickerField(
                label: type == TransactionType.payment
                    ? 'Category (optional)'
                    : 'Category',
                value: category?.name ?? draft.categoryName,
                hint: direction == null
                    ? 'Choose money in or out first'
                    : 'Choose a category',
                icon: Icons.category_outlined,
                errorText: errors['categoryId'],
                onClear: () => cubit.setCategory(null),
                onTap: () => unawaited(_pickCategory(context, state)),
              ),
            ),
            if (state.isEnabled(StandardField.party)) ...[
              gap,
              ReceiptFillHighlight(
                field: 'partyId',
                child: PickerField(
                  label: partyKind == PartyKind.supplier
                      ? 'Supplier'
                      : 'Customer',
                  value: draft.partyName,
                  hint: 'Optional',
                  icon: Icons.person_outline_rounded,
                  onClear: () => cubit.setParty(null),
                  onTap: () => unawaited(_pickParty(context, state, partyKind)),
                ),
              ),
            ],
            if (state.isEnabled(StandardField.project)) ...[
              gap,
              PickerField(
                label: 'Project',
                value: draft.projectName,
                hint: 'Optional',
                icon: Icons.work_outline_rounded,
                onClear: () => cubit.setProject(null),
                onTap: () => unawaited(_pickProject(context, state)),
              ),
            ],
            gap,
            ReceiptFillHighlight(
              field: 'description',
              child: AppTextField(
                label: 'Description',
                hint: 'What was it for?',
                initialValue: draft.description,
                maxLength: TransactionDraft.maxDescriptionLength,
                textCapitalization: TextCapitalization.sentences,
                errorText: errors['description'],
                onChanged: cubit.setDescription,
              ),
            ),
            if (state.isEnabled(StandardField.reference)) ...[
              gap,
              ReceiptFillHighlight(
                field: 'reference',
                child: AppTextField(
                  label: 'Reference',
                  hint: 'Bill no., PO, cheque no.',
                  initialValue: draft.reference,
                  maxLength: TransactionDraft.maxReferenceLength,
                  errorText: errors['reference'],
                  onChanged: cubit.setReference,
                ),
              ),
            ],
            if (state.isEnabled(StandardField.paymentMethod)) ...[
              gap,
              ReceiptFillHighlight(
                field: 'paymentMethod',
                child: _PaymentMethodField(value: draft.paymentMethod),
              ),
            ],
            if (state.isEnabled(StandardField.notes)) ...[
              gap,
              ReceiptFillHighlight(
                field: 'notes',
                child: AppTextField(
                  label: 'Notes',
                  initialValue: draft.notes,
                  maxLines: 4,
                  minLines: 2,
                  maxLength: TransactionDraft.maxNotesLength,
                  textCapitalization: TextCapitalization.sentences,
                  errorText: errors['notes'],
                  onChanged: cubit.setNotes,
                ),
              ),
            ],
            if (state.categoryFields.isNotEmpty) ...[
              sectionGap,
              AppSectionLabel('${category?.name ?? 'Category'} fields'),
              for (final field in state.categoryFields) ...[
                CustomFieldInput(
                  key: ValueKey('field-${field.id}'),
                  field: field,
                  value: draft.customFields[field.id],
                  errorText: errors['customFields.${field.id}'],
                  onChanged: (value) => cubit.setCustomField(field.id, value),
                ),
                gap,
              ],
            ],
          ],
        );
      },
    );
  }

  static Future<void> _pickCategory(
    BuildContext context,
    TransactionFormState state,
  ) async {
    final cubit = context.read<TransactionFormCubit>();
    final options = state.availableCategories;
    final picked = await showOptionSheet<String>(
      context: context,
      title: 'Category',
      selected: state.draft?.categoryId,
      searchable: options.length > 8,
      options: [
        for (final category in options)
          OptionItem(
            value: category.id,
            label: category.name,
            subtitle: category.kind.description,
            icon: category.icon.icon,
            iconColour: category.colour.colorIn(context.colors),
          ),
      ],
    );
    final id = picked?.value;
    if (id == null) return;
    cubit.setCategory(options.firstWhere((c) => c.id == id));
  }

  static Future<void> _pickParty(
    BuildContext context,
    TransactionFormState state,
    PartyKind kind,
  ) async {
    final cubit = context.read<TransactionFormCubit>();
    final parties = [
      for (final party in state.activeParties)
        if (party.kind.matches(kind) || party.id == state.draft?.partyId) party,
    ];
    var wantsNew = false;
    final picked = await showOptionSheet<String>(
      context: context,
      title: kind == PartyKind.supplier ? 'Supplier' : 'Customer',
      selected: state.draft?.partyId,
      searchable: parties.length > 8,
      options: [
        for (final party in parties)
          OptionItem(
            value: party.id,
            label: party.name,
            subtitle: party.phone.isEmpty ? party.kind.label : party.phone,
            icon: party.kind.icon,
          ),
      ],
      footer: Builder(
        builder: (sheet) => AppButton.secondary(
          label: 'New ${kind.label.toLowerCase()}',
          icon: Icons.person_add_alt_rounded,
          onPressed: () {
            wantsNew = true;
            Navigator.of(sheet).pop();
          },
        ),
      ),
    );
    if (!context.mounted) return;
    if (wantsNew) {
      final party = await showPartyForm(context, initialKind: kind);
      if (party != null) await cubit.createParty(party);
      return;
    }
    final id = picked?.value;
    if (id == null) return;
    cubit.setParty(parties.firstWhere((p) => p.id == id));
  }

  static Future<void> _pickProject(
    BuildContext context,
    TransactionFormState state,
  ) async {
    final cubit = context.read<TransactionFormCubit>();
    final projects = state.activeProjects;
    final picked = await showOptionSheet<String>(
      context: context,
      title: 'Project',
      selected: state.draft?.projectId,
      searchable: projects.length > 8,
      options: [
        for (final project in projects)
          OptionItem(value: project.id, label: project.displayName),
      ],
    );
    final id = picked?.value;
    if (id == null) return;
    cubit.setProject(projects.firstWhere((p) => p.id == id));
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: AppSpacing.xs.h),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: context.colors.error),
    ),
  );
}

class _AmountSection extends StatelessWidget {
  const _AmountSection();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TransactionFormCubit>();
    final state = context.watch<TransactionFormCubit>().state;
    final draft = state.draft!;
    final textTheme = Theme.of(context).textTheme;
    final lineItemsOn =
        state.isEnabled(StandardField.lineItems) || draft.useLineItems;
    final paymentLocked =
        state.isConfirmedEdit && draft.type == TransactionType.payment;
    final original = state.original;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (lineItemsOn && !paymentLocked)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Itemise'),
              subtitle: const Text('Quantity × rate for each line'),
              value: draft.useLineItems,
              onChanged: (value) => cubit.setUseLineItems(value: value),
            ),
          AnimatedSize(
            duration: AppMotion.medium,
            curve: AppMotion.standard,
            alignment: Alignment.topCenter,
            child: draft.useLineItems
                ? LineItemsEditor(
                    lines: draft.lineItems,
                    keys: state.lineKeys,
                    currency: state.currency,
                    errorText: state.errors['lineItems'],
                    onChanged: cubit.updateLine,
                    onAdd: cubit.addLine,
                    onRemove: cubit.removeLine,
                  )
                : AppMoneyField(
                    key: const ValueKey('total'),
                    label: 'Amount',
                    currency: state.currency,
                    initialMinor: draft.totalMinor,
                    enabled: !paymentLocked,
                    errorText: state.errors['totalMinor'],
                    helperText: paymentLocked
                        ? "A payment's amount cannot change. Cancel it and "
                              'record a new one.'
                        : null,
                    onChanged: cubit.setTotal,
                  ),
          ),
          SizedBox(height: AppSpacing.md.h),
          Container(
            padding: EdgeInsets.all(AppSpacing.md.r),
            decoration: BoxDecoration(
              color: context.colors.surfaceHigh,
              borderRadius: BorderRadius.circular(AppRadius.md.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    draft.useLineItems
                        ? 'Total · ${draft.lineItems.length} '
                              'line${draft.lineItems.length == 1 ? '' : 's'}'
                        : 'Total',
                    style: textTheme.labelMedium,
                  ),
                ),
                AnimatedSwitcher(
                  duration: AppMotion.fast,
                  child: Text(
                    Money.format(state.total, state.currency),
                    key: ValueKey(state.total),
                    style: AppTextStyles.tabular(textTheme.titleLarge!),
                  ),
                ),
              ],
            ),
          ),
          if (draft.useLineItems && state.errors['totalMinor'] != null)
            _ErrorText(state.errors['totalMinor']!),
          if (original != null &&
              state.isConfirmedEdit &&
              original.paidMinor + original.creditedMinor > 0)
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.sm.h),
              child: Text(
                'Already settled: ${Money.format(
                  original.paidMinor + original.creditedMinor,
                  state.currency,
                )}. The total cannot go below it.',
                style: textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentMethodField extends StatefulWidget {
  const _PaymentMethodField({required this.value});

  final String value;

  @override
  State<_PaymentMethodField> createState() => _PaymentMethodFieldState();
}

class _PaymentMethodFieldState extends State<_PaymentMethodField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(covariant _PaymentMethodField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A chip filled it: show the new value without fighting the typing.
    if (widget.value != _controller.text) _controller.text = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TransactionFormCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: _controller,
          label: 'Payment method',
          hint: 'Cash, UPI, bank transfer…',
          maxLength: PaymentMethods.maxLength,
          onChanged: cubit.setPaymentMethod,
        ),
        SizedBox(height: AppSpacing.xs.h),
        Wrap(
          spacing: AppSpacing.sm.w,
          children: [
            for (final method in PaymentMethods.common)
              ChoiceChip(
                label: Text(method),
                selected: widget.value == method,
                onSelected: (_) => cubit.setPaymentMethod(method),
              ),
          ],
        ),
      ],
    );
  }
}

class _ConflictCard extends StatelessWidget {
  const _ConflictCard({required this.onReload});

  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.tint(context.colors.warning),
    borderColor: context.colors.warning,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.sync_problem_rounded, color: context.colors.warning),
            SizedBox(width: AppSpacing.sm.w),
            Expanded(
              child: Text(
                'Someone else changed this transaction',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xs.h),
        Text(
          'Reload to see the latest version. Your edits here will be '
          'discarded.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(height: AppSpacing.sm.h),
        AppButton(
          label: 'Reload',
          icon: Icons.refresh_rounded,
          expand: false,
          onPressed: onReload,
        ),
      ],
    ),
  );
}

class _ActionBar extends StatelessWidget {
  const _ActionBar();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TransactionFormCubit>();
    return BlocBuilder<TransactionFormCubit, TransactionFormState>(
      builder: (context, state) {
        final loading = state.saveStatus.isLoading;
        final buttons = <Widget>[];
        String? note;
        if (state.isConfirmedEdit) {
          note = state.editBlockedReason ?? state.queueNote;
          buttons.add(
            AppButton(
              label: 'Save changes',
              icon: Icons.check_rounded,
              isLoading: loading,
              onPressed: state.editBlockedReason == null && !state.isBusy
                  ? () => unawaited(cubit.saveConfirmedChanges())
                  : null,
            ),
          );
        } else {
          if (state.canSaveDraft) {
            buttons.add(
              AppButton.secondary(
                label: 'Save draft',
                isLoading: loading && !state.canConfirm,
                onPressed: state.isBusy
                    ? null
                    : () => unawaited(cubit.saveDraft()),
              ),
            );
          }
          if (state.role.canDoFinancial) {
            buttons.add(
              AppButton(
                label: 'Save & confirm',
                icon: Icons.check_circle_outline_rounded,
                isLoading: loading && state.canConfirm,
                onPressed: state.canConfirm && !state.isBusy
                    ? () => unawaited(cubit.saveAndConfirm())
                    : null,
              ),
            );
          }
          note = state.role.canDoFinancial
              ? state.confirmBlockedReason ?? state.queueNote
              : state.role.canEditConfig
              ? 'An admin or owner confirms drafts.'
              : 'Viewers cannot record transactions.';
        }
        return DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.surface,
            border: Border(top: BorderSide(color: context.colors.divider)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal.w,
                AppSpacing.md.h,
                AppSpacing.screenHorizontal.w,
                AppSpacing.md.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (note != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
                      child: Text(
                        note,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  Row(
                    children: [
                      for (final (index, button) in buttons.indexed) ...[
                        if (index > 0) SizedBox(width: AppSpacing.md.w),
                        Expanded(child: button),
                      ],
                    ],
                  ),
                  if (state.canSettleNow)
                    TextButton.icon(
                      onPressed: state.isBusy
                          ? null
                          : () => unawaited(
                              cubit.saveAndConfirm(settleNow: true),
                            ),
                      icon: const Icon(Icons.price_check_rounded),
                      label: Text(
                        state.direction == Direction.outflow
                            ? 'Save, confirm & mark paid'
                            : 'Save, confirm & mark received',
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
