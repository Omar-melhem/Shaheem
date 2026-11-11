// Orchestrates the app's startup sequence.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/domain/use_cases/check_auth_status.dart';
import 'package:mobile_frontend/domain/use_cases/get_current_user.dart';
import 'package:mobile_frontend/helper/network/internet_connection_service.dart';
import 'package:mobile_frontend/view/app_state/connectivity/app_connectivity_cubit.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';

part 'splash_state.dart';

/// Runs startup: internet check → [CheckAuthStatus] → [GetCurrentUser] →
/// publish the user to [AppSessionCubit].
///
/// It owns no services. Reachability comes from the shared
/// [AppConnectivityCubit] (one app-wide monitor), and the signed-in user is
/// stored in the shared [AppSessionCubit], which outlives Splash. This cubit
/// holds only startup progress and errors. It never navigates: the router
/// redirects based on these states.
class SplashCubit extends Cubit<SplashState> {
  SplashCubit(
    this._connectivity,
    this._checkAuthStatus,
    this._getCurrentUser,
    this._session,
  ) : super(const SplashInitial()) {
    // While the No Internet screen is up, resume startup automatically as
    // soon as the shared monitor reports the connection is back.
    _connectivitySubscription = _connectivity.stream.listen((connectivity) {
      if (state is SplashOffline &&
          connectivity.status == InternetReachability.connected) {
        retry();
      }
    });
  }

  final AppConnectivityCubit _connectivity;
  final CheckAuthStatus _checkAuthStatus;
  final GetCurrentUser _getCurrentUser;
  final AppSessionCubit _session;
  late final StreamSubscription<AppConnectivityState> _connectivitySubscription;

  /// Runs startup once per app launch. Later calls do nothing.
  Future<void> start() async {
    if (state is! SplashInitial) return;
    await _run();
  }

  /// Runs startup again after a recoverable outcome. Ignored while a check
  /// is running, so repeated taps can't start overlapping requests.
  Future<void> retry() async {
    final canRetry = switch (state) {
      SplashOffline() ||
      SplashConnectivityCheckFailed() ||
      SplashServiceUnavailable() ||
      SplashProfileFailure() ||
      SplashBlocked() ||
      SplashFailure() => true,
      SplashInitial() || SplashChecking() || SplashResolved() => false,
    };
    if (canRetry) await _run();
  }

  Future<void> _run() async {
    final token = _session.beginAttempt();
    emit(const SplashChecking());

    // Each await below can be outrun by a sign-out or a newer attempt; a
    // stale result must never change state or sign anyone in.
    bool isStale() => isClosed || !_session.isCurrent(token);

    // 1. Internet, via the shared monitor (no second checker is created).
    final reachability = await _connectivity.check();
    if (isStale()) return;
    switch (reachability) {
      case InternetReachability.connected:
        break;
      case InternetReachability.disconnected:
        emit(const SplashOffline());
        return;
      case InternetReachability.checkFailed || InternetReachability.unknown:
        emit(const SplashConnectivityCheckFailed());
        return;
    }

    // 2. Is the stored session still valid?
    final authResult = await _checkAuthStatus();
    if (isStale()) return;
    switch (authResult) {
      case AuthCheckAuthenticated():
        break;
      case AuthCheckUnauthenticated():
        _session.markUnauthenticated(token);
        emit(const SplashResolved());
        return;
      case AuthCheckBlocked():
        emit(const SplashBlocked());
        return;
      case AuthCheckServiceUnavailable():
        emit(const SplashServiceUnavailable());
        return;
      case AuthCheckFailure():
        emit(const SplashFailure());
        return;
    }

    // 3. Load the user. Home opens only after this succeeds.
    final userResult = await _getCurrentUser();
    if (isStale()) return;
    switch (userResult) {
      case CurrentUserLoaded(:final user):
        // Publish the user before resolving, so the router sees a
        // fully-loaded session when it moves on.
        _session.authenticate(user, token);
        emit(const SplashResolved());
      case CurrentUserUnauthorized():
        _session.markUnauthenticated(token);
        emit(const SplashResolved());
      case CurrentUserBlocked():
        emit(const SplashBlocked());
      case CurrentUserUnavailable() || CurrentUserInvalid():
        // Recoverable; the session is kept and no user is invented.
        emit(const SplashProfileFailure());
      case CurrentUserFailure():
        emit(const SplashFailure());
    }
  }

  @override
  Future<void> close() async {
    await _connectivitySubscription.cancel();
    return super.close();
  }
}
