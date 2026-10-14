import 'package:business_ledger/core/di/injection.config.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final GetIt getIt = GetIt.instance;

/// Wires up the object graph. Called once from `bootstrap()` before `runApp`,
/// after Firebase is initialised (the module below reads its instances).
@InjectableInit()
Future<void> configureDependencies() => getIt.init();

/// Clears every registration. Test-only; production never tears down the graph.
Future<void> resetDependencies() => getIt.reset();
