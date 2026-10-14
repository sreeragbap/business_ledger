import 'package:business_ledger/app/bootstrap.dart';
import 'package:business_ledger/app/flavor.dart';

/// Entrypoint for the dev flavor.
///
/// Run with: `flutter run -t lib/main_dev.dart`
/// Against the local emulators: add `--dart-define=USE_EMULATOR=true`.
Future<void> main() => bootstrap(Flavor.dev);
