import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/features/receipt_scan/domain/models/receipt_scan.dart';
import 'package:business_ledger/features/receipt_scan/logic/receipt_scan_cubit/receipt_scan_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../transactions/stub_transaction_repository.dart';
import 'receipt_fakes.dart';

void main() {
  late FakeReceiptScanner scanner;
  late FakeReceiptAi ai;
  late FakeConnectivity cloud;
  late ReceiptScanCubit cubit;
  late List<ReceiptScanPhase> phases;

  setUp(() {
    scanner = FakeReceiptScanner();
    ai = FakeReceiptAi();
    cloud = FakeConnectivity();
    cubit = ReceiptScanCubit(
      scanner,
      ai,
      cloud.service,
      now: () => DateTime(2026, 10, 26, 12),
      minReading: Duration.zero,
    );
    phases = [];
    cubit.stream.listen((state) => phases.add(state.phase));
  });

  tearDown(() async {
    await cubit.close();
    await cloud.dispose();
  });

  /// Scans, then lets the stream deliver the last states.
  Future<void> scan() async {
    await cubit.scan(
      ReceiptSource.camera,
      currency: Currency.inr,
      categories: [],
    );
    await Future<void>.delayed(Duration.zero);
  }

  test('reads with AI and fills its gaps from the device reading', () async {
    await scan();
    expect(phases, [
      ReceiptScanPhase.capturing,
      ReceiptScanPhase.reading,
      ReceiptScanPhase.understanding,
      ReceiptScanPhase.done,
    ]);
    expect(ai.texts.single, 'Sunrise Bakery\nDate 24/10/2026\nTotal 120.00');
    final result = cubit.state.scan!;
    expect(result.reader, ReceiptReader.ai);
    expect(result.categoryId, 'cat-food');
    expect(result.totalMinor, 12000);
    // Not in the AI answer: taken from the on-device reading.
    expect(result.merchant, 'Sunrise Bakery');
    expect(result.date, '2026-10-24');
  });

  test('falls back to the device reading when AI fails', () async {
    ai.answer = const Failure(scanFailure);
    await scan();
    final result = cubit.state.scan!;
    expect(cubit.state.phase, ReceiptScanPhase.done);
    expect(result.reader, ReceiptReader.device);
    expect(result.totalMinor, 12000);
    expect(result.merchant, 'Sunrise Bakery');
  });

  test('offline it skips AI altogether', () async {
    cloud.isOnline = false;
    await scan();
    expect(ai.texts, isEmpty);
    expect(phases, isNot(contains(ReceiptScanPhase.understanding)));
    expect(cubit.state.scan!.reader, ReceiptReader.device);
  });

  test('backing out of the scanner returns to idle quietly', () async {
    scanner.captured = const Success(null);
    await scan();
    expect(phases, [ReceiptScanPhase.capturing, ReceiptScanPhase.idle]);
    expect(cubit.state.scan, isNull);
  });

  test('a scanner error fails with its message', () async {
    scanner.recognised = const Failure(scanFailure);
    await scan();
    expect(cubit.state.phase, ReceiptScanPhase.failed);
    expect(cubit.state.message, scanFailure.message);
    expect(ai.texts, isEmpty);
  });

  test('a second scan while one runs is ignored', () async {
    final first = scan();
    await scan();
    await first;
    expect(scanner.sources, hasLength(1));
  });

  test('init learns whether the camera works', () async {
    scanner.camera = false;
    await cubit.init();
    expect(cubit.state.cameraAvailable, isFalse);
  });

  test('reset clears the result', () async {
    await scan();
    cubit.reset();
    expect(cubit.state.phase, ReceiptScanPhase.idle);
    expect(cubit.state.scan, isNull);
  });
}
