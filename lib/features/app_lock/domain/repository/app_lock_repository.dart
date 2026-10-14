import 'package:business_ledger/core/domain/app_result.dart';

/// Contract for the biometric app lock. `AppLockService` implements it over
/// `local_auth` and `shared_preferences`; tests stub it.
abstract class AppLockRepository {
  const AppLockRepository();

  /// The user's saved choice. Synchronous: preferences are loaded at startup.
  bool get isEnabled;

  Future<AppResult<void>> setEnabled({required bool enabled});

  /// Whether the device can authenticate the user at all (biometrics or a
  /// passcode/pattern/PIN).
  Future<bool> isSupported();

  /// Shows the system prompt. Biometrics first, with the device credential
  /// as the fallback. A dismissed prompt is a [Failure] whose error
  /// `isCancelled`.
  Future<AppResult<void>> authenticate({required String reason});
}
