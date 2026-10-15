import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:business_ledger/core/di/injection.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_button.dart';
import 'package:business_ledger/core/widgets/app_section.dart';
import 'package:business_ledger/core/widgets/app_snack_bar.dart';
import 'package:business_ledger/core/widgets/app_text_field.dart';
import 'package:business_ledger/features/business/domain/const/business_template.dart';
import 'package:business_ledger/features/business/domain/const/time_zones.dart';
import 'package:business_ledger/features/business/logic/create_business_cubit/create_business_cubit.dart';
import 'package:business_ledger/features/business/widgets/business_switcher.dart';
import 'package:business_ledger/features/business/widgets/template_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Creates a business through the `createBusiness` callable, which seeds
/// the chosen template's categories and fields and makes the caller owner.
/// Needs a connection; the offline refusal is shown like any other error.
@RoutePage()
class CreateBusinessScreen extends StatefulWidget implements AutoRouteWrapper {
  const CreateBusinessScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) =>
      BlocProvider<CreateBusinessCubit>(
        create: (_) => getIt<CreateBusinessCubit>(),
        child: this,
      );

  @override
  State<CreateBusinessScreen> createState() => _CreateBusinessScreenState();
}

class _CreateBusinessScreenState extends State<CreateBusinessScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    unawaited(
      context.read<CreateBusinessCubit>().submit(
        name: _name.text,
        description: _description.text,
      ),
    );
  }

  void _onState(BuildContext context, CreateBusinessState state) {
    final status = state.submitStatus;
    if (status.isFailure && status.errors.isEmpty) {
      showAppSnackBar(context, status.message, kind: AppSnackBarKind.error);
    }
    final id = state.createdBusinessId;
    if (status.isSuccess && id != null) {
      showAppSnackBar(
        context,
        'Business created.',
        kind: AppSnackBarKind.success,
      );
      unawaited(openBusiness(context, id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return BlocListener<CreateBusinessCubit, CreateBusinessState>(
      listenWhen: (p, c) => p.submitStatus != c.submitStatus,
      listener: _onState,
      child: Scaffold(
        appBar: AppBar(title: const Text('New business')),
        body: BlocBuilder<CreateBusinessCubit, CreateBusinessState>(
          builder: (context, state) {
            final cubit = context.read<CreateBusinessCubit>();
            final loading = state.submitStatus.isLoading;
            return ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal.w,
                AppSpacing.sm.h,
                AppSpacing.screenHorizontal.w,
                AppSpacing.huge.h,
              ),
              children: [
                AppTextField(
                  controller: _name,
                  label: 'Business name',
                  hint: 'e.g. Rao Constructions',
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  maxLength: CreateBusinessCubit.maxNameLength,
                  enabled: !loading,
                  errorText: state.submitStatus.errorFor('name'),
                ),
                SizedBox(height: AppSpacing.lg.h),
                AppTextField(
                  controller: _description,
                  label: 'Description (optional)',
                  hint: 'What the business does',
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                  maxLength: 200,
                  enabled: !loading,
                ),
                SizedBox(height: AppSpacing.xxl.h),
                const AppSectionLabel('Currency'),
                Wrap(
                  spacing: AppSpacing.sm.w,
                  runSpacing: AppSpacing.sm.h,
                  children: [
                    for (final currency in Currency.supported)
                      ChoiceChip(
                        label: Text(
                          '${currency.code} ${currency.symbol.trim()}',
                        ),
                        selected: currency == state.currency,
                        onSelected: loading
                            ? null
                            : (_) => cubit.currencyChanged(currency),
                      ),
                  ],
                ),
                SizedBox(height: AppSpacing.xs.h),
                Text(
                  'Fixed once the business is created: every amount is '
                  'stored in this currency.',
                  style: textTheme.bodySmall,
                ),
                SizedBox(height: AppSpacing.xxl.h),
                const AppSectionLabel('Time zone'),
                TimeZoneField(
                  value: state.timezone,
                  enabled: !loading,
                  onChanged: cubit.timezoneChanged,
                ),
                SizedBox(height: AppSpacing.xxl.h),
                const AppSectionLabel('Start from'),
                for (final template in BusinessTemplate.values) ...[
                  TemplateCard(
                    template: template,
                    selected: template == state.template,
                    onTap: () {
                      if (!loading) cubit.templateChanged(template);
                    },
                  ),
                  SizedBox(height: AppSpacing.md.h),
                ],
                SizedBox(height: AppSpacing.lg.h),
                AppButton(
                  label: 'Create business',
                  isLoading: loading,
                  onPressed: _submit,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A dropdown over [TimeZones], always including [value].
class TimeZoneField extends StatelessWidget {
  const TimeZoneField({
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(),
      items: [
        for (final name in TimeZones.optionsIncluding(value))
          DropdownMenuItem(value: name, child: Text(TimeZones.label(name))),
      ],
      onChanged: enabled
          ? (zone) {
              if (zone != null) onChanged(zone);
            }
          : null,
    );
  }
}
