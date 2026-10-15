part of 'parties_cubit.dart';

class PartiesState extends Equatable {
  const PartiesState({
    this.parties,
    this.loadStatus = const Status.initial(),
    this.query = '',
    this.kindFilter,
    this.showArchived = false,
    this.actionStatus = const Status.initial(),
    this.savedId,
  });

  /// Every party, archived included, by name. `null` until loaded.
  final List<Party>? parties;
  final Status loadStatus;
  final String query;

  /// `null` for all kinds.
  final PartyKind? kindFilter;
  final bool showArchived;
  final Status actionStatus;

  /// The id of the party last saved, for a caller that wants to select it.
  final String? savedId;

  /// The list as filtered on screen; `null` until loaded.
  List<Party>? get visible => parties
      ?.where(
        (party) =>
            party.archived == showArchived &&
            (kindFilter == null || party.kind.matches(kindFilter!)) &&
            party.matchesQuery(query),
      )
      .toList(growable: false);

  int get archivedCount =>
      parties?.where((party) => party.archived).length ?? 0;

  bool get isFiltering => query.trim().isNotEmpty || kindFilter != null;

  PartiesState copyWith({
    List<Party>? parties,
    Status? loadStatus,
    String? query,
    PartyKind? Function()? kindFilter,
    bool? showArchived,
    Status? actionStatus,
    String? savedId,
  }) => PartiesState(
    parties: parties ?? this.parties,
    loadStatus: loadStatus ?? this.loadStatus,
    query: query ?? this.query,
    kindFilter: kindFilter == null ? this.kindFilter : kindFilter(),
    showArchived: showArchived ?? this.showArchived,
    actionStatus: actionStatus ?? this.actionStatus,
    savedId: savedId ?? this.savedId,
  );

  @override
  List<Object?> get props => [
    parties,
    loadStatus,
    query,
    kindFilter,
    showArchived,
    actionStatus,
    savedId,
  ];
}
