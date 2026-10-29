import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/features/categories/domain/models/category.dart';
import 'package:business_ledger/features/receipt_scan/domain/models/ocr_line.dart';
import 'package:business_ledger/features/receipt_scan/domain/models/receipt_scan.dart';
import 'package:business_ledger/features/receipt_scan/domain/repository/receipt_ai_repository.dart';
import 'package:business_ledger/features/receipt_scan/domain/repository/receipt_scanner_repository.dart';

/// One OCR line per row, stacked top to bottom.
List<OcrLine> ocrRows(List<String> rows) => [
  for (final (i, row) in rows.indexed)
    OcrLine(text: row, left: 0, top: i * 10.0, right: 100, bottom: i * 10 + 8),
];

class FakeReceiptScanner implements ReceiptScannerRepository {
  bool camera = true;
  AppResult<String?> captured = const Success('/tmp/receipt.jpg');
  AppResult<List<OcrLine>> recognised = Success(
    ocrRows(['Sunrise Bakery', 'Date 24/10/2026', 'Total 120.00']),
  );
  final List<ReceiptSource> sources = [];

  @override
  Future<bool> canUseCamera() async => camera;

  @override
  Future<AppResult<String?>> capture(ReceiptSource source) async {
    sources.add(source);
    return captured;
  }

  @override
  Future<AppResult<List<OcrLine>>> recognize(String path) async => recognised;
}

class FakeReceiptAi implements ReceiptAiRepository {
  AppResult<ReceiptScan> answer = const Success(
    ReceiptScan(
      totalMinor: 12000,
      categoryId: 'cat-food',
      description: 'Bread and cakes',
      reader: ReceiptReader.ai,
    ),
  );
  final List<String> texts = [];

  @override
  Future<AppResult<ReceiptScan>> read({
    required String text,
    required Currency currency,
    required String today,
    required List<Category> categories,
  }) async {
    texts.add(text);
    return answer;
  }
}

const AppException scanFailure = AppException(
  kind: AppErrorKind.unknown,
  message: "Couldn't read the receipt. Please try again.",
);
