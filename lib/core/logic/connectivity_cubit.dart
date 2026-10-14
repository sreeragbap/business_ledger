import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:business_ledger/core/firebase/connectivity_service.dart';
import 'package:injectable/injectable.dart';

/// App-wide online flag, for the offline banner and for screens that disable
/// financial actions while offline. `true` means online.
@lazySingleton
class ConnectivityCubit extends Cubit<bool> {
  ConnectivityCubit(ConnectivityService service) : super(service.isOnline) {
    _subscription = service.onlineChanges.listen(emit);
  }

  late final StreamSubscription<bool> _subscription;

  bool get isOffline => !state;

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
