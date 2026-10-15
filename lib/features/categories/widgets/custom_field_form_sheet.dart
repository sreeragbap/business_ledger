import 'package:business_ledger/core/theme/app_motion.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_bottom_sheet.dart';
import 'package:business_ledger/core/widgets/app_button.dart';
import 'package:business_ledger/core/widgets/app_text_field.dart';
import 'package:business_ledger/features/categories/domain/const/field_type.dart';
import 'package:business_ledger/features/categories/domain/models/custom_field.dart';
import 'package:business_ledger/features/categories/logic/custom_fields_cubit/custom_fields_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Opens the custom field form. Resolves the edited field (with an empty id
/// for a new one), or `null` when dismissed.
Future<CustomField?> showCustomFieldForm(
  BuildContext context, {
  CustomField? field,
}) => showAppBottomSheet<CustomField>(
  context: context,
  title: field == null ? 'New field' : 'Edit field',
  child: CustomFieldForm(field: field),
);

class CustomFieldForm extends StatefulWidget {
  const CustomFieldForm({this.field, super.key});

  final CustomField? field;

  @override
  State<CustomFieldForm> createState() => _CustomFieldFormState();
}

class _CustomFieldFormState extends State<CustomFieldForm> {
  late final CustomField _initial =
      widget.field ?? const CustomField(id: '', label: '');
  late final _label = TextEditingController(text: _initial.label);
  final _option = TextEditingController();
  late FieldType _type = _initial.type;
  late List<String> _options = [..._initial.options];
  late bool _required = _initial.required;
  Map<String, List<String>> _errors = const {};

  /// Past entries store values in the type's shape; changing it would
  /// orphan them, so the type is fixed once the field exists.
  bool get _typeLocked => widget.field != null;

  @override
  void dispose() {
    _label.dispose();
    _option.dispose();
    super.dispose();
  }

  void _addOption() {
    final value = _option.text.trim();
    if (value.isEmpty) return;
    setState(() {
      if (!_options.contains(value)) _options = [..._options, value];
      _option.clear();
      _errors = const {};
    });
  }

  void _submit() {
    _addOption();
    final field = _initial.copyWith(
      label: _label.text,
      type: _type,
      options: _options,
      required: _required,
    );
    final errors = CustomFieldsCubit.validate(field);
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      return;
    }
    Navigator.of(context).pop(field);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: _label,
          label: 'Label',
          hint: 'e.g. Vehicle no.',
          autofocus: widget.field == null,
          textCapitalization: TextCapitalization.sentences,
          maxLength: CustomField.maxLabelLength,
          errorText: _errors['label']?.first,
        ),
        SizedBox(height: AppSpacing.lg.h),
        Text('Type', style: textTheme.labelMedium),
        SizedBox(height: AppSpacing.sm.h),
        Wrap(
          spacing: AppSpacing.sm.w,
          runSpacing: AppSpacing.sm.h,
          children: [
            for (final type in FieldType.values)
              ChoiceChip(
                avatar: Icon(type.icon, size: 16.r),
                label: Text(type.label),
                selected: type == _type,
                onSelected: _typeLocked && type != _type
                    ? null
                    : (_) => setState(() => _type = type),
              ),
          ],
        ),
        if (_typeLocked) ...[
          SizedBox(height: AppSpacing.xs.h),
          Text(
            'The type is fixed once a field exists, so past values stay '
            'readable.',
            style: textTheme.bodySmall,
          ),
        ],
        AnimatedSize(
          duration: AppMotion.medium,
          curve: AppMotion.standard,
          alignment: Alignment.topCenter,
          child: _type.hasOptions
              ? Padding(
                  padding: EdgeInsets.only(top: AppSpacing.lg.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        controller: _option,
                        label: 'Choices',
                        hint: 'Type a choice and press add',
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addOption(),
                        errorText: _errors['options']?.first,
                        suffix: IconButton(
                          tooltip: 'Add choice',
                          icon: const Icon(Icons.add_rounded),
                          onPressed: _addOption,
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm.h),
                      Wrap(
                        spacing: AppSpacing.sm.w,
                        runSpacing: AppSpacing.sm.h,
                        children: [
                          for (final option in _options)
                            InputChip(
                              label: Text(option),
                              onDeleted: () => setState(
                                () => _options = [..._options]..remove(option),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        SizedBox(height: AppSpacing.sm.h),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Required'),
          subtitle: const Text('A transaction cannot be confirmed without it.'),
          value: _required,
          onChanged: (value) => setState(() => _required = value),
        ),
        SizedBox(height: AppSpacing.lg.h),
        AppButton(
          label: widget.field == null ? 'Add field' : 'Save',
          onPressed: _submit,
        ),
      ],
    );
  }
}
