// App-wide connectivity state, fed by the single InternetConnectionService.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/helper/network/internet_connection_service.dart';

part 'app_connectivity_state.dart';

/// Publishes internet reachability to the whole app.
///
/// One instance is created in `MainApp` and provided above the router. It
/// is the only subscriber to [InternetConnectionService]; screens read this
/// state (or call [check]) and never start their own monitor.
///
/// Lifecycle: `MainApp` calls [pauseMonitoring] when the app goes to the
/// background and [resumeMonitoring] when it returns. Pausing cancels the
/// stream subscription (which also stops the package's periodic probes);
/// resuming subscribes again and runs one fresh check. This follows the
/// package's guidance to avoid replaying stale buffered events.
///
/// This is a reachability signal for feedback only. API calls must still
/// handle their own failures and must not be blocked on this state.
class AppConnectivityCubit extends Cubit<AppConnectivityState> {
  AppConnectivityCubit(this._service) : super(const AppConnectivityState());

  final InternetConnectionService _service;

  StreamSubscription<InternetReachability>? _subscription;
  Future<InternetReachability>? _inFlight;
  bool _started = false;
  bool _paused = false;

  /// Increases with every applied update (stream event or check). A check
  /// only applies its result if nothing newer arrived while it ran.
  int _version = 0;

  /// Starts monitoring: subscribes once and runs the first check.
  /// Further calls do nothing.
  void start() {
    if (_started || isClosed) return;
    _started = true;
    _subscribe();
    check();
  }

  /// Runs one bounded reachability check and returns its result.
  ///
  /// Calls made while a check is running share it, so taps and startup
  /// can't stack probes. If a stream event arrives meanwhile, that newer
  /// status wins and is returned instead of the (stale) check result.
  Future<InternetReachability> check() =>
      _inFlight ??= _runCheck().whenComplete(() => _inFlight = null);

  Future<InternetReachability> _runCheck() async {
    final version = ++_version;
    if (!isClosed) emit(state.copyWith(isChecking: true));

    final result = await _service.checkNow();
    if (isClosed) return result;

    if (version == _version) {
      emit(AppConnectivityState(status: result));
      return result;
    }
    // Superseded by a newer stream event: keep that status.
    emit(state.copyWith(isChecking: false));
    return state.status;
  }

  /// Stops monitoring while the app is in the background.
  void pauseMonitoring() {
    if (!_started || _paused) return;
    _paused = true;
    _subscription?.cancel();
    _subscription = null;
  }

  /// Resumes monitoring after [pauseMonitoring]: fresh subscription plus one
  /// check. Does nothing if monitoring was not paused.
  void resumeMonitoring() {
    if (!_started || !_paused || isClosed) return;
    _paused = false;
    _subscribe();
    check();
  }

  /// Subscribes to the service stream unless already subscribed, so there
  /// is never more than one active subscription.
  void _subscribe() {
    _subscription ??= _service.statusChanges.listen(
      (status) {
        if (isClosed) return;
        _version++;
        emit(state.copyWith(status: status));
      },
      onError: (Object _) {
        // A stream error means the checker failed, not that we're offline.
        if (isClosed) return;
        _version++;
        emit(state.copyWith(status: InternetReachability.checkFailed));
      },
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    return super.close();
  }
}
