part of 'create_business_cubit.dart';

class CreateBusinessState extends Equatable {
  const CreateBusinessState({
    this.currency = Currency.inr,
    this.timezone = TimeZones.fallback,
    this.template = BusinessTemplate.general,
    this.submitStatus = const Status.initial(),
    this.createdBusinessId,
  });

  final Currency currency;
  final String timezone;
  final BusinessTemplate template;
  final Status submitStatus;

  /// Set once [submitStatus] succeeds.
  final String? createdBusinessId;

  CreateBusinessState copyWith({
    Currency? currency,
    String? timezone,
    BusinessTemplate? template,
    Status? submitStatus,
    String? createdBusinessId,
  }) => CreateBusinessState(
    currency: currency ?? this.currency,
    timezone: timezone ?? this.timezone,
    template: template ?? this.template,
    submitStatus: submitStatus ?? this.submitStatus,
    createdBusinessId: createdBusinessId ?? this.createdBusinessId,
  );

  @override
  List<Object?> get props => [
    currency,
    timezone,
    template,
    submitStatus,
    createdBusinessId,
  ];
}
