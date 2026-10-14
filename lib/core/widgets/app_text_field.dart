import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A labelled text input. The label sits above the field (not floating
/// inside it), which reads better in long forms and on a dark surface.
class AppTextField extends StatelessWidget {
  const AppTextField({
    this.label,
    this.hint,
    this.controller,
    this.initialValue,
    this.errorText,
    this.helperText,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.autofillHints,
    this.prefixIcon,
    this.prefixText,
    this.suffix,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.focusNode,
    this.onTap,
    this.textAlign = TextAlign.start,
    this.style,
    super.key,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? initialValue;
  final String? errorText;
  final String? helperText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final IconData? prefixIcon;
  final String? prefixText;
  final Widget? suffix;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final FocusNode? focusNode;
  final VoidCallback? onTap;
  final TextAlign textAlign;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final field = TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      enabled: enabled,
      readOnly: readOnly,
      obscureText: obscureText,
      autofocus: autofocus,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      maxLength: maxLength,
      focusNode: focusNode,
      onTap: onTap,
      textAlign: textAlign,
      style: style ?? textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        helperText: helperText,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20.r),
        prefixText: prefixText,
        prefixStyle: style ?? textTheme.bodyLarge,
        suffixIcon: suffix,
        counterText: '',
      ),
    );

    if (label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label!, style: textTheme.labelMedium),
        SizedBox(height: AppSpacing.sm.h),
        field,
      ],
    );
  }
}
