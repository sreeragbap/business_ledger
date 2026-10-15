import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:business_ledger/core/bloc/status.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/features/business/domain/models/business.dart';
import 'package:business_ledger/features/business/domain/repository/business_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'business_list_state.dart';

/// The businesses the user belongs to, for the picker and the quick
/// switcher. Archived ones are hidden behind [toggleArchived].
@injectable
class BusinessListCubit extends Cubit<BusinessListState> {
  BusinessListCubit(this._repository) : super(const BusinessListState());

  final BusinessRepository _repository;
  StreamSubscription<AppResult<List<Business>>>? _subscription;

  Future<void> watch(String uid) async {
    await _subscription?.cancel();
    emit(state.copyWith(loadStatus: const Status.loading()));
    _subscription = _repository.watchMyBusinesses(uid).listen((result) {
      emit(
        result.when(
          success: (businesses) => state.copyWith(
            businesses: businesses,
            loadStatus: const Status.success(),
          ),
          failure: (error) =>
              state.copyWith(loadStatus: Status.fromException(error)),
        ),
      );
    });
  }

  void toggleArchived() =>
      emit(state.copyWith(showArchived: !state.showArchived));

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
