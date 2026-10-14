import 'package:business_ledger/app/bootstrap.dart';
import 'package:business_ledger/app/flavor.dart';

/// Entrypoint for the prod flavor.
///
/// Run with: `flutter run -t lib/main_prod.dart`
Future<void> main() => bootstrap(Flavor.prod);
