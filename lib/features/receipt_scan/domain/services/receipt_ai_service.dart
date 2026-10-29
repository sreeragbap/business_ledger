import 'dart:async';

import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/features/categories/domain/models/category.dart';
import 'package:business_ledger/features/receipt_scan/domain/models/receipt_scan.dart';
import 'package:business_ledger/features/receipt_scan/domain/repository/receipt_ai_repository.dart';
import 'package:business_ledger/features/receipt_scan/domain/services/receipt_ai_mapper.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// [ReceiptAiRepository] over the `scan-receipt` Edge Function
/// (`supabase/functions/scan-receipt`). The Supabase client sends the
/// Firebase ID token, which the function verifies.
@LazySingleton(as: ReceiptAiRepository)
class ReceiptAiService implements ReceiptAiRepository {
  ReceiptAiService(this._supabase);

  final SupabaseClient _supabase;

  /// The function gives Claude 15 s; past this the phone stops waiting and
  /// uses its own reading.
  static const Duration timeout = Duration(seconds: 18);

  @override
  Future<AppResult<ReceiptScan>> read({
    required String text,
    required Currency currency,
    required String today,
    required List<Category> categories,
  }) async {
    try {
      final response = await _supabase.functions
          .invoke(
            'scan-receipt',
            body: {
              'text': text,
              'currency': currency.code,
              'today': today,
              'categories': [
                for (final category in categories)
                  {'id': category.id, 'name': category.name},
              ],
            },
          )
          .timeout(timeout);
      final data = response.data;
      if (data is! Map) {
        return const Failure(
          AppException(
            kind: AppErrorKind.unknown,
            message: 'The receipt reader gave no answer.',
          ),
        );
      }
      return Success(
        ReceiptAiMapper.toScan(data.cast<String, dynamic>(), currency),
      );
    } on FunctionException catch (error) {
      return Failure(
        AppException(
          kind: error.status == 401
              ? AppErrorKind.unauthenticated
              : AppErrorKind.unknown,
          message: "Couldn't read the receipt with AI.",
          code: 'scan-${error.status}',
          cause: error.details?.toString(),
        ),
      );
    } on TimeoutException {
      return const Failure(
        AppException(
          kind: AppErrorKind.timeout,
          message: 'The receipt reader took too long.',
        ),
      );
    } on Object catch (error) {
      return Failure(AppException.from(error));
    }
  }
}
