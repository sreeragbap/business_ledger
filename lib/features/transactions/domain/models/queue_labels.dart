import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/core/money/money.dart';

/// How a queued money action is listed in the outbox and on the
/// transaction ("Payment ₹1,200.00 · Cement bags").
abstract final class QueueLabels {
  static String settlement(
    SettlementKind kind,
    int amountMinor,
    Currency currency,
    String title,
  ) => _join('${kind.label} ${Money.format(amountMinor, currency)}', title);

  static String confirm(
    int totalMinor,
    Currency currency,
    String title, {
    bool settleNow = false,
  }) => _join(
    '${settleNow ? 'Confirm as paid' : 'Confirm'} '
    '${Money.format(totalMinor, currency)}',
    title,
  );

  static String edit(String title) => _join('Edit', title);

  static String cancel(String title) => _join('Cancel', title);

  static String _join(String action, String title) =>
      title.trim().isEmpty ? action : '$action · ${title.trim()}';

  /// Shown after an action was queued rather than applied.
  static const String queuedMessage =
      'Saved on this device. It will be applied when synced.';
}
