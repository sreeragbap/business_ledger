import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:flutter/foundation.dart' show immutable;

/// Outcome of a repository call. Repositories return this and never throw.
///
/// Same shape as the reference's `ApiResult`: sealed, so the data exists only
/// on [Success] and a forgotten [Failure] branch is a compile error rather
/// than a crash.
@immutable
sealed class AppResult<T> {
  const AppResult();

  const factory AppResult.success(T data) = Success<T>;

  const factory AppResult.failure(AppException error) = Failure<T>;

  /// Runs [body] and turns anything it throws into a [Failure], via
  /// [AppException.from]. The one place a service needs a `try`.
  static Future<AppResult<T>> guard<T>(Future<T> Function() body) async {
    try {
      return Success<T>(await body());
    } catch (error) {
      return Failure<T>(AppException.from(error));
    }
  }

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  /// Data when successful, otherwise `null`.
  T? get dataOrNull => switch (this) {
    Success<T>(:final data) => data,
    Failure<T>() => null,
  };

  /// Error when failed, otherwise `null`.
  AppException? get errorOrNull => switch (this) {
    Success<T>() => null,
    Failure<T>(:final error) => error,
  };

  /// Returns the data, or **throws** the [AppException]. Only for code with a
  /// genuine enclosing `try`; prefer [when].
  T get dataOrThrow => switch (this) {
    Success<T>(:final data) => data,
    Failure<T>(:final error) => throw error,
  };

  /// Collapses both branches into a single value.
  R when<R>({
    required R Function(T data) success,
    required R Function(AppException error) failure,
  }) => switch (this) {
    Success<T>(:final data) => success(data),
    Failure<T>(:final error) => failure(error),
  };

  /// Transforms the success value, leaving a failure untouched.
  AppResult<R> map<R>(R Function(T data) transform) => switch (this) {
    Success<T>(:final data) => Success<R>(transform(data)),
    Failure<T>(:final error) => Failure<R>(error),
  };
}

final class Success<T> extends AppResult<T> {
  const Success(this.data);

  final T data;

  @override
  bool operator ==(Object other) => other is Success<T> && other.data == data;

  @override
  int get hashCode => Object.hash(Success, data);

  @override
  String toString() => 'Success<$T>($data)';
}

final class Failure<T> extends AppResult<T> {
  const Failure(this.error);

  final AppException error;

  @override
  bool operator ==(Object other) => other is Failure<T> && other.error == error;

  @override
  int get hashCode => Object.hash(Failure, error);

  @override
  String toString() => 'Failure<$T>($error)';
}
