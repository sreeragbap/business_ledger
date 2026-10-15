import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/features/business/domain/const/business_template.dart';
import 'package:equatable/equatable.dart';

/// Input of the `createBusiness` callable (`docs/FUNCTIONS_API.md`).
class CreateBusinessRequest extends Equatable {
  const CreateBusinessRequest({
    required this.requestId,
    required this.name,
    required this.currency,
    required this.timezone,
    required this.template,
    this.description = '',
  });

  /// Reused for every retry of the same create, so a timeout followed by a
  /// retry can never create two businesses.
  final String requestId;
  final String name;
  final String description;
  final Currency currency;
  final String timezone;
  final BusinessTemplate template;

  /// Same input, ignoring the request id: whether a retry may reuse it.
  bool sameInputAs(CreateBusinessRequest other) =>
      name == other.name &&
      description == other.description &&
      currency == other.currency &&
      timezone == other.timezone &&
      template == other.template;

  CreateBusinessRequest withRequestId(String id) => CreateBusinessRequest(
    requestId: id,
    name: name,
    description: description,
    currency: currency,
    timezone: timezone,
    template: template,
  );

  Map<String, dynamic> toPayload() => {
    'requestId': requestId,
    'name': name.trim(),
    if (description.trim().isNotEmpty) 'description': description.trim(),
    'currencyCode': currency.code,
    'timezone': timezone,
    'template': template.key,
  };

  @override
  List<Object?> get props => [
    requestId,
    name,
    description,
    currency,
    timezone,
    template,
  ];
}
