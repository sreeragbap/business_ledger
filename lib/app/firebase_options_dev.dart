// Placeholder for the dev flavor's Firebase options.
//
// Replace this whole file with the output of:
//
//   flutterfire configure --project=busineedger-ab7a1 \
//     --out=lib/app/firebase_options_dev.dart \
//     --platforms=android,ios \
//     --android-package-name=com.iocod.business_ledger \
//     --ios-bundle-id=com.iocod.businessLedger
//
// The generated file declares the same `DefaultFirebaseOptions` class with a
// `currentPlatform` getter, so `AppConfig` needs no change when it lands.
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnimplementedError(
    'Firebase is not configured for the dev flavor yet. Run '
    '`flutterfire configure --out=lib/app/firebase_options_dev.dart` '
    '(see the header of this file).',
  );
}
