import 'dart:async';

import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:rxdart/rxdart.dart';

/// Turns drift `watch()` streams into `Stream<AppResult<T>>`, so a cubit
/// gets errors as values instead of stream errors, matching the never-throw
/// repository contract.
abstract final class LocalStreams {
  /// Maps each emission with [convert]; a throw (a malformed row) or a
  /// stream error becomes a [Failure] without ending the stream.
  static Stream<AppResult<T>> watch<S, T>(
    Stream<S> source,
    T Function(S value) convert,
  ) => source.transform(
    StreamTransformer<S, AppResult<T>>.fromHandlers(
      handleData: (value, sink) {
        try {
          sink.add(Success(convert(value)));
        } catch (error) {
          sink.add(Failure(AppException.from(error)));
        }
      },
      handleError: (error, _, sink) =>
          sink.add(Failure(AppException.from(error))),
    ),
  );

  /// One row; `null` only once the store has been filled from the server
  /// ([pulled]): before the first pull a missing row is simply not known
  /// yet (a fresh sign-in on this device), and treating it as "gone" would,
  /// say, drop the user out of a business they still belong to.
  static Stream<AppResult<T?>> single<S, T>(
    Stream<S?> source,
    Stream<bool> pulled,
    T Function(S value) convert,
  ) => watch<(S?, bool), T?>(
    Rx.combineLatest2<S?, bool, (S?, bool)>(
      source,
      pulled,
      (row, done) => (row, done),
    ).where((pair) => pair.$1 != null || pair.$2),
    (pair) => pair.$1 == null ? null : convert(pair.$1 as S),
  );
}
