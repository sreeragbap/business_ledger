part of 'business_scope_cubit.dart';

enum ScopeStatus {
  /// Nothing resolved yet (cold start, or signed out).
  initial,

  /// A business is chosen; its documents are on their way.
  loading,

  /// [BusinessScopeState.business] and [BusinessScopeState.member] are set.
  ready,

  /// No business selected: show the picker.
  none,
}

class BusinessScopeState extends Equatable {
  const BusinessScopeState({
    this.status = ScopeStatus.initial,
    this.businessId,
    this.business,
    this.member,
    this.loadStatus = const Status.initial(),
    this.lostMessage,
  });

  final ScopeStatus status;
  final String? businessId;
  final Business? business;

  /// The signed-in user's own membership.
  final Member? member;

  /// The listeners' health. A failure here keeps the last good data.
  final Status loadStatus;

  /// Why the selection was dropped (removed, business deleted), for the
  /// picker to explain. `null` when the user simply has none yet.
  final String? lostMessage;

  bool get isReady => status == ScopeStatus.ready;

  /// The least privilege until the membership has loaded.
  Role get role => member?.role ?? Role.viewer;

  BusinessScopeState copyWith({
    ScopeStatus? status,
    Business? business,
    Member? member,
    Status? loadStatus,
  }) => BusinessScopeState(
    status: status ?? this.status,
    businessId: businessId,
    business: business ?? this.business,
    member: member ?? this.member,
    loadStatus: loadStatus ?? this.loadStatus,
    lostMessage: lostMessage,
  );

  @override
  List<Object?> get props => [
    status,
    businessId,
    business,
    member,
    loadStatus,
    lostMessage,
  ];
}
