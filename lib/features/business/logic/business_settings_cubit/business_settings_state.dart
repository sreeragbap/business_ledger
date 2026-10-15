part of 'business_settings_cubit.dart';

class BusinessSettingsState extends Equatable {
  const BusinessSettingsState({
    this.saveStatus = const Status.initial(),
    this.archiveStatus = const Status.initial(),
  });

  final Status saveStatus;
  final Status archiveStatus;

  BusinessSettingsState copyWith({Status? saveStatus, Status? archiveStatus}) =>
      BusinessSettingsState(
        saveStatus: saveStatus ?? this.saveStatus,
        archiveStatus: archiveStatus ?? this.archiveStatus,
      );

  @override
  List<Object?> get props => [saveStatus, archiveStatus];
}
