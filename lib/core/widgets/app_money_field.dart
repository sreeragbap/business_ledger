import 'dart:async';

import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/core/money/money.dart';
import 'package:business_ledger/core/theme/app_text_styles.dart';
import 'package:business_ledger/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// An amount input that yields **integer minor units**, never a double.
///
/// What the user types is parsed with [Money.parse] for [currency], so a
/// 2-decimal currency accepts `1,250.50` (→ `125050`) and refuses a third
/// decimal; a 0-decimal currency refuses the point altogether. The
/// [MoneyInputFormatter] blocks impossible keystrokes as they are typed, and
/// the value is re-grouped (`1250.5` → `1,250.50`) when the field loses focus.
class AppMoneyField extends StatefulWidget {
  const AppMoneyField({
    required this.currency,
    required this.onChanged,
    this.initialMinor,
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.enabled = true,
    this.autofocus = false,
    this.allowZero = false,
    this.isRequired = true,
    this.textInputAction,
    this.onSubmitted,
    this.focusNode,
    super.key,
  });

  final Currency currency;

  /// The parsed amount in minor units, or `null` when empty or invalid.
  final ValueChanged<int?> onChanged;

  final int? initialMinor;
  final String? label;
  final String? hint;

  /// An error from outside (a server field error, a ledger violation). Takes
  /// precedence over the field's own parse error.
  final String? errorText;
  final String? helperText;
  final bool enabled;
  final bool autofocus;

  /// Whether `0` is an acceptable amount. Off by default: ledger amounts are
  /// positive (`LedgerViolation.nonPositiveAmount`).
  final bool allowZero;

  /// Used by the [Form] validator: an empty field fails when set.
  final bool isRequired;

  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  @override
  State<AppMoneyField> createState() => _AppMoneyFieldState();
}

class _AppMoneyFieldState extends State<AppMoneyField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialMinor == null
        ? ''
        : Money.plain(widget.initialMinor!, widget.currency),
  );
  late FocusNode _focusNode = widget.focusNode ?? FocusNode();
  String? _parseError;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(AppMoneyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_onFocusChange);
      if (oldWidget.focusNode == null) _focusNode.dispose();
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Normalises the text to the currency's grouping once editing ends.
  void _onFocusChange() {
    if (_focusNode.hasFocus) return;
    final minor = Money.parse(_controller.text, widget.currency);
    if (minor == null) return;
    final formatted = Money.plain(minor, widget.currency);
    if (formatted != _controller.text) _controller.text = formatted;
  }

  void _onChanged(String text) {
    final minor = Money.parse(text, widget.currency);
    final error = _errorFor(text, minor);
    if (error != _parseError) setState(() => _parseError = error);
    widget.onChanged(error == null ? minor : null);
  }

  String? _errorFor(String text, int? minor) {
    if (text.trim().isEmpty) return null;
    if (minor == null) {
      // The formatter blocks malformed input, so a null here is a value
      // beyond Money.maxMinor.
      return 'That amount is too large.';
    }
    if (minor == 0 && !widget.allowZero) {
      return 'Enter an amount greater than zero.';
    }
    return null;
  }

  String? _validate(String? text) {
    final value = text ?? '';
    if (value.trim().isEmpty) {
      return widget.isRequired ? 'Enter an amount.' : null;
    }
    return _errorFor(value, Money.parse(value, widget.currency));
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium;
    return AppTextField(
      controller: _controller,
      focusNode: _focusNode,
      label: widget.label,
      hint: widget.hint ?? Money.plain(0, widget.currency),
      errorText: widget.errorText ?? _parseError,
      helperText: widget.helperText,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      prefixText: widget.currency.symbol,
      style: style == null ? null : AppTextStyles.tabular(style),
      keyboardType: TextInputType.numberWithOptions(
        decimal: widget.currency.decimals > 0,
      ),
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      inputFormatters: [MoneyInputFormatter(widget.currency)],
      onChanged: _onChanged,
      validator: _validate,
    );
  }
}

/// Rejects keystrokes that can never become a valid amount for [currency]:
/// letters, a second point, a point in a 0-decimal currency, or more fraction
/// digits than the currency has. Grouping commas and spaces are allowed
/// (`Money.parse` ignores them).
class MoneyInputFormatter extends TextInputFormatter {
  MoneyInputFormatter(this.currency)
    : _pattern = RegExp(
        currency.decimals == 0
            ? r'^[\d, ]*$'
            : '^[\\d, ]*(\\.\\d{0,${currency.decimals}})?\$',
      );

  final Currency currency;
  final RegExp _pattern;

  /// Digits only, ignoring grouping: far above `Money.maxMinor`'s 14 digits so
  /// a "too large" error can be shown rather than silently refusing input.
  static const int _maxDigits = 18;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Some keyboards (and locales) type a comma for the decimal point; accept
    // it only when it is clearly the point: the last character, and the
    // field has no point yet.
    var text = newValue.text;
    if (currency.decimals > 0 &&
        text.endsWith(',') &&
        !text.contains('.') &&
        oldValue.text.length + 1 == text.length &&
        _endsAfterGroupDigits(oldValue.text)) {
      text = '${text.substring(0, text.length - 1)}.';
    }
    if (!_pattern.hasMatch(text)) return oldValue;
    if (text.replaceAll(RegExp(r'\D'), '').length > _maxDigits) return oldValue;
    if (text == newValue.text) return newValue;
    return newValue.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// A comma typed after fewer than three digits since the last comma cannot
  /// be a grouping separator, so it is a decimal point.
  static bool _endsAfterGroupDigits(String text) {
    final tail = text.split(',').last;
    return tail.isNotEmpty && tail.length < 3;
  }
}

/// Keeps the import of `dart:async` honest for `unawaited` users downstream.
@visibleForTesting
void ignoreFuture(Future<void> future) => unawaited(future);
