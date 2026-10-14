import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

typedef JsonMap = Map<String, dynamic>;
typedef CollectionRef = CollectionReference<JsonMap>;
typedef DocRef = DocumentReference<JsonMap>;

/// Every Firestore path in the app, per `docs/ARCHITECTURE.md` §3.
///
/// Nothing else spells a collection name. Services ask this for a reference
/// and attach their model's converter (`withConverter`) at the call site.
@lazySingleton
class FirestoreRefs {
  FirestoreRefs(this._db);

  final FirebaseFirestore _db;

  // --- Collection names (shared with rules and functions) -----------------
  static const String usersPath = 'users';
  static const String businessesPath = 'businesses';
  static const String membersPath = 'members';
  static const String categoriesPath = 'categories';
  static const String fieldsPath = 'fields';
  static const String partiesPath = 'parties';
  static const String projectsPath = 'projects';
  static const String transactionsPath = 'transactions';
  static const String settlementsPath = 'settlements';
  static const String documentsPath = 'documents';
  static const String auditPath = 'audit';
  static const String statsPath = 'stats';
  static const String countersPath = 'counters';

  // --- Users ---------------------------------------------------------------
  CollectionRef get users => _db.collection(usersPath);
  DocRef user(String uid) => users.doc(uid);

  // --- Businesses ----------------------------------------------------------
  CollectionRef get businesses => _db.collection(businessesPath);
  DocRef business(String businessId) => businesses.doc(businessId);

  CollectionRef members(String businessId) =>
      business(businessId).collection(membersPath);
  DocRef member(String businessId, String uid) => members(businessId).doc(uid);

  CollectionRef categories(String businessId) =>
      business(businessId).collection(categoriesPath);
  DocRef category(String businessId, String categoryId) =>
      categories(businessId).doc(categoryId);

  CollectionRef fields(String businessId) =>
      business(businessId).collection(fieldsPath);
  DocRef field(String businessId, String fieldId) =>
      fields(businessId).doc(fieldId);

  CollectionRef parties(String businessId) =>
      business(businessId).collection(partiesPath);
  DocRef party(String businessId, String partyId) =>
      parties(businessId).doc(partyId);

  CollectionRef projects(String businessId) =>
      business(businessId).collection(projectsPath);
  DocRef project(String businessId, String projectId) =>
      projects(businessId).doc(projectId);

  CollectionRef transactions(String businessId) =>
      business(businessId).collection(transactionsPath);
  DocRef transaction(String businessId, String transactionId) =>
      transactions(businessId).doc(transactionId);

  CollectionRef settlements(String businessId, String transactionId) =>
      transaction(businessId, transactionId).collection(settlementsPath);

  CollectionRef documents(String businessId) =>
      business(businessId).collection(documentsPath);
  DocRef document(String businessId, String documentId) =>
      documents(businessId).doc(documentId);

  CollectionRef audit(String businessId) =>
      business(businessId).collection(auditPath);

  /// Daily aggregates, keyed `yyyy-MM-dd`.
  CollectionRef stats(String businessId) =>
      business(businessId).collection(statsPath);
  DocRef statsDay(String businessId, String day) => stats(businessId).doc(day);

  /// Storage path prefix for a business's files; mirrors `storage.rules`.
  static String storagePrefix(String businessId) =>
      '$businessesPath/$businessId';
}
