import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

/// Who is signed in, as far as the sync layer cares: a uid.
abstract class SyncIdentity {
  const SyncIdentity();

  String? get uid;

  /// The current uid first, then each change.
  Stream<String?> get uidChanges;
}

@LazySingleton(as: SyncIdentity)
class FirebaseSyncIdentity extends SyncIdentity {
  const FirebaseSyncIdentity(this._auth);

  final FirebaseAuth _auth;

  @override
  String? get uid => _auth.currentUser?.uid;

  @override
  Stream<String?> get uidChanges =>
      _auth.authStateChanges().map((user) => user?.uid).distinct();
}
