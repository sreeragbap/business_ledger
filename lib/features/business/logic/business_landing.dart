import 'package:auto_route/auto_route.dart';
import 'package:business_ledger/core/router/app_router.dart';
import 'package:business_ledger/features/business/logic/business_scope_cubit/business_scope_cubit.dart';

/// Where a signed-in user lands: the home shell on their last business, or
/// the picker when there is none to reopen (first launch, or access lost).
///
/// Used by the splash (cold start) and by sign-in.
Future<PageRouteInfo<void>> businessLanding(BusinessScopeCubit scope) async {
  final businessId = await scope.restore();
  return businessId == null
      ? const BusinessPickerRoute()
      : const HomeShellRoute();
}
