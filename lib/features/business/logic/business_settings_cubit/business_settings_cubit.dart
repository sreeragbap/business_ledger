import 'package:bloc/bloc.dart';
import 'package:business_ledger/core/bloc/status.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/features/business/domain/models/business.dart';
import 'package:business_ledger/features/business/domain/repository/business_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'business_settings_state.dart';

/// Saves a business's details and settings, and archives it.
///
/// The business itself is read from `BusinessScopeCubit` (it is already
/// streamed there); this cubit only owns the two write operations.
@injectable
class BusinessSettingsCubit extends Cubit<BusinessSettingsState> {
  BusinessSettingsCubit(this._repository)
    : super(const BusinessSettingsState());

  final BusinessRepository _repository;

  static const int maxNameLength = 80;
  static const int maxPrefixLength = 10;
  static final RegExp prefixPattern = RegExp(r'^[A-Za-z0-9-]{1,10}$');

  Future<void> save(
    String businessId, {
    required String name,
    required String description,
    required String timezone,
    required BusinessSettings settings,
  }) async {
    if (state.saveStatus.isLoading) return;
    final errors = validate(name: name, settings: settings);
    if (errors.isNotEmpty) {
      emit(
        state.copyWith(
          saveStatus: Status.failure(
            errors.values.first.first,
            errors: errors,
          ),
        ),
      );
      return;
    }
    emit(state.copyWith(saveStatus: const Status.loading()));
    final result = await _repository.updateDetails(
      businessId,
      name: name,
      description: description,
      timezone: timezone,
      settings: settings,
    );
    emit(
      state.copyWith(
        saveStatus: result.when(
          success: (_) => const Status.success(message: 'Saved.'),
          failure: Status.fromException,
        ),
      ),
    );
  }

  Future<void> setArchived(String businessId, {required bool archived}) async {
    if (state.archiveStatus.isLoading) return;
    emit(state.copyWith(archiveStatus: const Status.loading()));
    final result = await _repository.setArchived(
      businessId,
      archived: archived,
    );
    emit(
      state.copyWith(
        archiveStatus: switch (result) {
          Success() => Status.success(
            message: archived ? 'Business archived.' : 'Business restored.',
          ),
          Failure(:final error) => Status.fromException(error),
        },
      ),
    );
  }

  /// Field errors keyed by form field, mirroring the rules' limits.
  static Map<String, List<String>> validate({
    required String name,
    required BusinessSettings settings,
  }) {
    final trimmed = name.trim();
    return {
      if (trimmed.isEmpty)
        'name': ['Give the business a name.']
      else if (trimmed.length > maxNameLength)
        'name': ['Keep the name under $maxNameLength characters.'],
      for (final (key, value) in [
        ('invoicePrefix', settings.invoicePrefix),
        ('billPrefix', settings.billPrefix),
        ('receiptPrefix', settings.receiptPrefix),
      ])
        if (!prefixPattern.hasMatch(value.trim()))
          key: ['Use 1–10 letters, digits or dashes.'],
    };
  }
}
