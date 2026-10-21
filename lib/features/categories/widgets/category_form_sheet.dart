import 'package:business_ledger/core/theme/app_motion.dart';
import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_bottom_sheet.dart';
import 'package:business_ledger/core/widgets/app_button.dart';
import 'package:business_ledger/core/widgets/app_text_field.dart';
import 'package:business_ledger/features/categories/domain/const/category_kind.dart';
import 'package:business_ledger/features/categories/domain/const/category_style.dart';
import 'package:business_ledger/features/categories/domain/models/category.dart';
import 'package:business_ledger/features/categories/domain/models/custom_field.dart';
import 'package:business_ledger/features/categories/widgets/category_icon_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Opens the category form. Resolves the edited category (with an empty id
/// for a new one), or `null` when dismissed.
Future<Category?> showCategoryForm(
  BuildContext context, {
  required List<CustomField> fields,
  Category? category,
}) => showAppBottomSheet<Category>(
  context: context,
  title: category == null ? 'New category' : 'Edit category',
  child: CategoryForm(category: category, fields: fields),
);

class CategoryForm extends StatefulWidget {
  const CategoryForm({required this.fields, this.category, super.key});

  final Category? category;

  /// Every custom field. Only active ones are offered; archived ones already
  /// attached are kept as they are.
  final List<CustomField> fields;

  @override
  State<CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<CategoryForm> {
  late final Category _initial =
      widget.category ?? const Category(id: '', name: '');
  late final _name = TextEditingController(text: _initial.name);
  late CategoryKind _kind = widget.category?.kind ?? CategoryKind.expense;
  late CategoryIcon _icon = _initial.icon;
  late CategoryColour _colour = _initial.colour;
  late List<String> _fieldIds = [..._initial.fieldIds];
  String? _nameError;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _toggleField(String id, {required bool on}) => setState(() {
    _fieldIds = [..._fieldIds]..remove(id);
    if (on) _fieldIds.add(id);
  });

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty || name.length > Category.maxNameLength) {
      setState(
        () => _nameError = name.isEmpty
            ? 'Give the category a name.'
            : 'Keep it under ${Category.maxNameLength} characters.',
      );
      return;
    }
    Navigator.of(context).pop(
      _initial.copyWith(
        name: name,
        kind: _kind,
        icon: _icon,
        colour: _colour,
        fieldIds: _fieldIds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final active = widget.fields.where((field) => !field.archived).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AnimatedSwitcher(
              duration: AppMotion.fast,
              child: CategoryIconBadge(
                key: ValueKey('${_icon.key}${_colour.key}'),
                icon: _icon,
                colour: _colour,
                size: 48,
              ),
            ),
            SizedBox(width: AppSpacing.md.w),
            Expanded(
              child: AppTextField(
                controller: _name,
                label: 'Name',
                hint: 'e.g. Fuel',
                autofocus: widget.category == null,
                textCapitalization: TextCapitalization.sentences,
                maxLength: Category.maxNameLength,
                errorText: _nameError,
                onChanged: (_) {
                  if (_nameError != null) setState(() => _nameError = null);
                },
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.lg.h),
        Text('Used for', style: textTheme.labelMedium),
        SizedBox(height: AppSpacing.sm.h),
        SegmentedButton<CategoryKind>(
          segments: [
            for (final kind in CategoryKind.values)
              ButtonSegment(value: kind, label: Text(kind.label)),
          ],
          selected: {_kind},
          showSelectedIcon: false,
          onSelectionChanged: (selection) =>
              setState(() => _kind = selection.first),
        ),
        SizedBox(height: AppSpacing.lg.h),
        Text('Icon', style: textTheme.labelMedium),
        SizedBox(height: AppSpacing.sm.h),
        Wrap(
          spacing: AppSpacing.sm.w,
          runSpacing: AppSpacing.sm.h,
          children: [
            for (final icon in CategoryIcon.values)
              _Selectable(
                selected: icon == _icon,
                label: icon.key,
                onTap: () => setState(() => _icon = icon),
                child: Icon(
                  icon.icon,
                  size: 20.r,
                  color: icon == _icon ? _colour.colorIn(context.colors) : null,
                ),
              ),
          ],
        ),
        SizedBox(height: AppSpacing.lg.h),
        Text('Colour', style: textTheme.labelMedium),
        SizedBox(height: AppSpacing.sm.h),
        Wrap(
          spacing: AppSpacing.sm.w,
          runSpacing: AppSpacing.sm.h,
          children: [
            for (final colour in CategoryColour.values)
              _Selectable(
                selected: colour == _colour,
                label: colour.label,
                onTap: () => setState(() => _colour = colour),
                child: Container(
                  width: 20.r,
                  height: 20.r,
                  decoration: BoxDecoration(
                    color: colour.colorIn(context.colors),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: AppSpacing.lg.h),
        Text('Extra fields on the form', style: textTheme.labelMedium),
        SizedBox(height: AppSpacing.sm.h),
        if (active.isEmpty)
          Text(
            'No custom fields yet. Add them under Settings › Custom fields.',
            style: textTheme.bodySmall,
          )
        else
          Wrap(
            spacing: AppSpacing.sm.w,
            runSpacing: AppSpacing.sm.h,
            children: [
              for (final field in active)
                FilterChip(
                  label: Text(field.label),
                  avatar: Icon(field.type.icon, size: 16.r),
                  selected: _fieldIds.contains(field.id),
                  onSelected: (on) => _toggleField(field.id, on: on),
                ),
            ],
          ),
        SizedBox(height: AppSpacing.xxl.h),
        AppButton(
          label: widget.category == null ? 'Add category' : 'Save',
          onPressed: _submit,
        ),
      ],
    );
  }
}

/// A round, selectable swatch for the icon and colour pickers.
class _Selectable extends StatelessWidget {
  const _Selectable({
    required this.selected,
    required this.onTap,
    required this.child,
    required this.label,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 24.r,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          width: 40.r,
          height: 40.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.colors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? context.colors.accent : context.colors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
