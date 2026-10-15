import 'package:bloc/bloc.dart';
import 'package:business_ledger/core/bloc/status.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/firebase/request_ids.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/features/business/domain/const/business_template.dart';
import 'package:business_ledger/features/business/domain/const/time_zones.dart';
import 'package:business_ledger/features/business/domain/models/create_business_request.dart';
import 'package:business_ledger/features/business/domain/repository/business_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'create_business_state.dart';

/// Drives the create-business form and the `createBusiness` call.
///
/// One `requestId` per intent: a retry of the same input (after a timeout,
/// say) reuses it, so the server returns the business it already created
/// instead of a second one. Changing any input starts a new intent.
@injectable
class CreateBusinessCubit extends Cubit<CreateBusinessState> {
  CreateBusinessCubit(this._repository)
    : super(CreateBusinessState(timezone: TimeZones.deviceDefault()));

  final BusinessRepository _repository;

  /// The last request that did not succeed, for reuse on retry.
  CreateBusinessRequest? _pending;

  static const int maxNameLength = 80;

  void currencyChanged(Currency currency) =>
      emit(state.copyWith(currency: currency));

  void timezoneChanged(String timezone) =>
      emit(state.copyWith(timezone: timezone));

  void templateChanged(BusinessTemplate template) =>
      emit(state.copyWith(template: template));

  Future<void> submit({required String name, String description = ''}) async {
    if (state.submitStatus.isLoading) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      emit(
        state.copyWith(
          submitStatus: const Status.failure(
            'Give the business a name.',
            errors: {
              'name': ['Give the business a name.'],
            },
          ),
        ),
      );
      return;
    }

    var request = CreateBusinessRequest(
      requestId: _pending?.requestId ?? RequestIds.next(),
      name: trimmed,
      description: description.trim(),
      currency: state.currency,
      timezone: state.timezone,
      template: state.template,
    );
    final previous = _pending;
    if (previous == null || !previous.sameInputAs(request)) {
      request = request.withRequestId(RequestIds.next());
    }
    _pending = request;

    emit(state.copyWith(submitStatus: const Status.loading()));
    final result = await _repository.createBusiness(request);
    switch (result) {
      case Success(:final data):
        _pending = null;
        emit(
          state.copyWith(
            submitStatus: const Status.success(),
            createdBusinessId: data,
          ),
        );
      case Failure(:final error):
        emit(state.copyWith(submitStatus: Status.fromException(error)));
    }
  }
}
