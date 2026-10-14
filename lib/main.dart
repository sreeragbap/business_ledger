/// This app is flavored. There is no unflavored entrypoint.
///
/// Use one of these instead:
///   flutter run -t lib/main_dev.dart
///   flutter run -t lib/main_prod.dart
///   flutter run -t lib/main_dev.dart --dart-define=USE_EMULATOR=true
///
/// This file exists only so an accidental `flutter run` fails with a message
/// that says what to do, rather than booting with no flavor set.
void main() {
  throw UnsupportedError(
    'business_ledger has no default entrypoint. Run a flavor explicitly, '
    'e.g.\n  flutter run -t lib/main_dev.dart',
  );
}
