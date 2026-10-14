import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:equatable/equatable.dart';

/// Which phase of an async operation a [Status] represents.
enum StatusType {
  /// Nothing has been attempted yet. The resting state.
  initial,

  /// A request is in flight.
  loading,

  success,

  failure,
}

/// The outcome of one async operation, as held in a BLoC state.
///
/// The message travels with the status, so a success can never be holding the
/// previous failure's text.
///
/// A state may hold several of these when it drives several independent
/// operations:
///
/// ```dart
/// class TransactionState extends Equatable {
///   const TransactionState({
///     this.loadStatus = const Status.initial(),
///     this.confirmStatus = const Status.initial(),
///   });
///
///   final Status loadStatus;
///   final Status confirmStatus;
/// }
/// ```
///
/// [message], [errors] and [error] participate in equality on purpose. Two
/// consecutive failures with different messages are *not* equal, so
/// `listenWhen` fires again and the second message is actually shown.
class Status extends Equatable {
  /// Private so the named constructors below are the only way in. That keeps
  /// invalid combinations (a `loading` carrying field errors, say)
  /// unrepresentable.
  const Status._({
    required this.type,
    this.message = '',
    this.errors = const {},
    this.error,
  });

  const Status.initial() : this._(type: StatusType.initial);

  const Status.loading() : this._(type: StatusType.loading);

  /// [message] is empty by default: a success usually needs no announcement,
  /// and wording belongs to the UI rather than to core.
  const Status.success({String message = ''})
    : this._(type: StatusType.success, message: message);

  const Status.failure(
    String message, {
    Map<String, List<String>> errors = const {},
    AppException? error,
  }) : this._(
         type: StatusType.failure,
         message: message,
         errors: errors,
         error: error,
       );

  /// Builds a failure from an [AppException], carrying its user-safe message
  /// and, when the server named the offending input, a field error for it.
  factory Status.fromException(AppException error) => Status.failure(
    error.message,
    errors: error.field == null
        ? const {}
        : {
            error.field!: [error.message],
          },
    error: error,
  );

  final StatusType type;

  /// Human-readable text for this outcome. Empty unless one was supplied.
  final String message;

  /// Per-field validation errors, e.g. `{'amountMinor': ['Too large']}`.
  /// Always empty unless [isFailure].
  final Map<String, List<String>> errors;

  /// The failure behind this status, when it came from one. Lets a listener
  /// branch on [AppException.kind] (reload on conflict, stay quiet on cancel).
  final AppException? error;

  bool get isInitial => type == StatusType.initial;
  bool get isLoading => type == StatusType.loading;
  bool get isSuccess => type == StatusType.success;
  bool get isFailure => type == StatusType.failure;

  /// The first validation error for [field], or `null` if it has none.
  /// Intended for `TextFormField.errorText`.
  String? errorFor(String field) {
    final messages = errors[field];
    return (messages == null || messages.isEmpty) ? null : messages.first;
  }

  @override
  List<Object?> get props => [type, message, errors, error];

  @override
  String toString() {
    final detail = message.isEmpty ? '' : ': $message';
    return 'Status(${type.name}$detail)';
  }
}
