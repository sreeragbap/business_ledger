part of 'business_list_cubit.dart';

class BusinessListState extends Equatable {
  const BusinessListState({
    this.businesses,
    this.loadStatus = const Status.initial(),
    this.showArchived = false,
  });

  /// `null` until the first snapshot.
  final List<Business>? businesses;
  final Status loadStatus;
  final bool showArchived;

  List<Business>? get visible => businesses
      ?.where((business) => showArchived || !business.archived)
      .toList(growable: false);

  int get archivedCount =>
      businesses?.where((business) => business.archived).length ?? 0;

  BusinessListState copyWith({
    List<Business>? businesses,
    Status? loadStatus,
    bool? showArchived,
  }) => BusinessListState(
    businesses: businesses ?? this.businesses,
    loadStatus: loadStatus ?? this.loadStatus,
    showArchived: showArchived ?? this.showArchived,
  );

  @override
  List<Object?> get props => [businesses, loadStatus, showArchived];
}
