import 'dart:async';

import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/firebase/firestore_refs.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Turns Firestore listeners into `Stream<AppResult<T>>`, so a cubit gets
/// errors (rules, a revoked membership) as values instead of stream errors,
/// matching the never-throw repository contract.
abstract final class FirestoreStreams {
  static Stream<AppResult<List<T>>> list<T>(
    Query<JsonMap> query,
    T Function(DocumentSnapshot<JsonMap> doc) fromDoc,
  ) => query
      .snapshots()
      .map<AppResult<List<T>>>(
        (snapshot) => Success(
          List<T>.unmodifiable(snapshot.docs.map(fromDoc)),
        ),
      )
      .transform(_errorsAsFailures<List<T>>());

  /// One document; `null` once the server says it does not exist.
  ///
  /// A "missing" answer that comes only from the local cache is skipped: on a
  /// cold, offline start the cache simply has not seen the document yet, and
  /// treating that as "deleted" would, say, sign the user out of a business
  /// they still belong to.
  static Stream<AppResult<T?>> doc<T>(
    DocRef ref,
    T Function(DocumentSnapshot<JsonMap> doc) fromDoc,
  ) => ref
      .snapshots()
      .where((snapshot) => snapshot.exists || !snapshot.metadata.isFromCache)
      .map<AppResult<T?>>(
        (snapshot) => Success(snapshot.exists ? fromDoc(snapshot) : null),
      )
      .transform(_errorsAsFailures<T?>());

  static StreamTransformer<AppResult<T>, AppResult<T>> _errorsAsFailures<T>() =>
      StreamTransformer<AppResult<T>, AppResult<T>>.fromHandlers(
        handleError: (error, stack, sink) =>
            sink.add(Failure<T>(AppException.from(error))),
      );
}
