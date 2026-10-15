import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:business_ledger/core/bloc/status.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/features/parties/domain/const/party_kind.dart';
import 'package:business_ledger/features/parties/domain/models/party.dart';
import 'package:business_ledger/features/parties/domain/repository/party_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'parties_state.dart';

/// Customers and suppliers: a live list filtered on the device by search
/// text, kind and archived, plus create/edit/archive.
@injectable
class PartiesCubit extends Cubit<PartiesState> {
  PartiesCubit(this._repository) : super(const PartiesState());

  final PartyRepository _repository;
  StreamSubscription<AppResult<List<Party>>>? _subscription;
  String? _businessId;

  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Future<void> watch(String businessId) async {
    _businessId = businessId;
    await _subscription?.cancel();
    emit(state.copyWith(loadStatus: const Status.loading()));
    _subscription = _repository
        .watchParties(businessId)
        .listen(
          (result) => emit(
            result.when(
              success: (parties) => state.copyWith(
                parties: parties,
                loadStatus: const Status.success(),
              ),
              failure: (error) =>
                  state.copyWith(loadStatus: Status.fromException(error)),
            ),
          ),
        );
  }

  void search(String query) => emit(state.copyWith(query: query));

  /// `null` shows every kind.
  void filterKind(PartyKind? kind) =>
      emit(state.copyWith(kindFilter: () => kind));

  void toggleArchived() =>
      emit(state.copyWith(showArchived: !state.showArchived));

  static Map<String, List<String>> validate(Party party) {
    final name = party.name.trim();
    final email = party.email.trim();
    return {
      if (name.isEmpty)
        'name': ['Enter a name.']
      else if (name.length > Party.maxNameLength)
        'name': ['Keep the name under ${Party.maxNameLength} characters.'],
      if (email.isNotEmpty && !_email.hasMatch(email))
        'email': ['Enter a valid email address.'],
    };
  }

  /// Creates [party] when its id is empty, otherwise updates it. On a
  /// create, [PartiesState.savedId] carries the new id.
  Future<void> save(Party party) async {
    final businessId = _businessId;
    if (businessId == null) return;
    final errors = validate(party);
    if (errors.isNotEmpty) {
      emit(
        state.copyWith(
          actionStatus: Status.failure(
            errors.values.first.first,
            errors: errors,
          ),
        ),
      );
      return;
    }
    emit(state.copyWith(actionStatus: const Status.loading()));
    if (party.id.isEmpty) {
      final result = await _repository.create(businessId, party);
      emit(
        result.when(
          success: (id) => state.copyWith(
            savedId: id,
            actionStatus: Status.success(message: '${party.name} added.'),
          ),
          failure: (error) =>
              state.copyWith(actionStatus: Status.fromException(error)),
        ),
      );
      return;
    }
    final result = await _repository.update(businessId, party);
    emit(
      state.copyWith(
        savedId: party.id,
        actionStatus: result.when(
          success: (_) => const Status.success(message: 'Saved.'),
          failure: Status.fromException,
        ),
      ),
    );
  }

  Future<void> setArchived(Party party, {required bool archived}) async {
    final businessId = _businessId;
    if (businessId == null) return;
    emit(state.copyWith(actionStatus: const Status.loading()));
    final result = await _repository.setArchived(
      businessId,
      party.id,
      archived: archived,
    );
    emit(
      state.copyWith(
        actionStatus: result.when(
          success: (_) => Status.success(
            message: archived
                ? '${party.name} archived.'
                : '${party.name} restored.',
          ),
          failure: Status.fromException,
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
