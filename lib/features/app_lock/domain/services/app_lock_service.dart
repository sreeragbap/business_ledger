import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/features/app_lock/domain/repository/app_lock_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Concrete [AppLockRepository] over `local_auth` 3.x.
@LazySingleton(as: AppLockRepository)
class AppLockService implements AppLockRepository {
  AppLockService(this._localAuth, this._prefs);

  final LocalAuthentication _localAuth;
  final SharedPreferences _prefs;

  static const String enabledKey = 'app_lock.enabled';

  @override
  bool get isEnabled => _prefs.getBool(enabledKey) ?? false;

  @override
  Future<AppResult<void>> setEnabled({required bool enabled}) =>
      AppResult.guard(() => _prefs.setBool(enabledKey, enabled));

  @override
  Future<bool> isSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<AppResult<void>> authenticate({required String reason}) async {
    try {
      final passed = await _localAuth.authenticate(
        localizedReason: reason,
        // Device PIN / pattern / passcode is the fallback when biometrics
        // fail or are not enrolled; a lock the user cannot open is worse
        // than one opened with their passcode.
        // Survives the app going to the background while the prompt is up,
        // which is what happens on Android when the sensor sheet appears.
        persistAcrossBackgrounding: true,
      );
      return passed
          ? const Success(null)
          : const Failure(
              AppException(
                kind: AppErrorKind.permissionDenied,
                message: "That didn't match. Try again.",
              ),
            );
    } on LocalAuthException catch (error) {
      return Failure(_fromLocalAuth(error));
    } catch (error) {
      return Failure(AppException.unknown(error));
    }
  }

  static AppException _fromLocalAuth(LocalAuthException error) {
    final message = switch (error.code) {
      LocalAuthExceptionCode.userCanceled ||
      LocalAuthExceptionCode.systemCanceled ||
      LocalAuthExceptionCode.userRequestedFallback ||
      LocalAuthExceptionCode.authInProgress => null,
      LocalAuthExceptionCode.noCredentialsSet ||
      LocalAuthExceptionCode.noBiometricsEnrolled ||
      LocalAuthExceptionCode.noBiometricHardware =>
        'Set up a screen lock on this device to use app lock.',
      LocalAuthExceptionCode.temporaryLockout ||
      LocalAuthExceptionCode.biometricLockout =>
        'Too many attempts. Use your device passcode or try again later.',
      LocalAuthExceptionCode.timeout =>
        'The prompt timed out. Tap unlock to try again.',
      _ => 'Could not verify it is you. Please try again.',
    };
    if (message == null) return const AppException.cancelled();
    return AppException(
      kind: AppErrorKind.unknown,
      message: message,
      code: error.code.name,
      cause: error.description,
    );
  }
}
