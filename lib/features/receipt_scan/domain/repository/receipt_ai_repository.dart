import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/features/categories/domain/models/category.dart';
import 'package:business_ledger/features/receipt_scan/domain/models/receipt_scan.dart';

/// Understands receipt text with AI (Claude, through the `scan-receipt`
/// Edge Function). Only the recognised text is sent, never the image.
// ignore: one_member_abstracts
abstract class ReceiptAiRepository {
  /// [text] is the receipt, one printed row per line. [categories] are the
  /// ones the entry may use; the answer picks from them or none.
  Future<AppResult<ReceiptScan>> read({
    required String text,
    required Currency currency,
    required String today,
    required List<Category> categories,
  });
}
