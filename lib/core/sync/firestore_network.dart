import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

/// The few Firestore network controls the sync layer needs, behind an
/// interface so settings and the sync engine are testable without Firebase.
abstract class FirestoreNetwork {
  const FirestoreNetwork();

  /// Resumes talking to the backend; queued writes start uploading.
  Future<void> enable();

  /// Stops talking to the backend. Reads come from the cache and writes
  /// queue locally, exactly as when the device is offline.
  Future<void> disable();

  /// Completes once every write issued so far has been acknowledged by the
  /// server. Never completes while the network is disabled or offline, so
  /// callers always put a timeout on it.
  Future<void> waitForPendingWrites();
}

@LazySingleton(as: FirestoreNetwork)
class FirebaseFirestoreNetwork extends FirestoreNetwork {
  const FirebaseFirestoreNetwork(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<void> enable() => _firestore.enableNetwork();

  @override
  Future<void> disable() => _firestore.disableNetwork();

  @override
  Future<void> waitForPendingWrites() => _firestore.waitForPendingWrites();
}
