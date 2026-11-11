// App-wide holder of the signed-in user.

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/domain/entities/app_user.dart';
import 'package:mobile_frontend/domain/use_cases/sign_out.dart';

part 'app_session_state.dart';

/// Holds the current user for the whole app lifetime, so Home and later
/// screens can read it after Splash is gone without fetching it again.
///
/// The router reads this state to protect authenticated routes. The user is
/// kept in memory only; it is never persisted as proof of a session.
///
/// Every attempt to establish a session (startup now, login later) gets a
/// token from [beginAttempt]. A result is only applied while its token is
/// still the latest, so a slow response that arrives after a sign-out or a
/// newer attempt cannot sign the user back in.
class AppSessionCubit extends Cubit<AppSessionState> {
  AppSessionCubit(this._signOut) : super(const SessionUnknown());

  final SignOut _signOut;
  int _attempt = 0;

  /// Starts a new session attempt and invalidates every older one.
  int beginAttempt() => ++_attempt;

  /// Whether [token] still belongs to the latest attempt.
  bool isCurrent(int token) => token == _attempt;

  /// Publishes a validated [user]. Ignored if [token] is outdated.
  void authenticate(AppUser user, int token) {
    if (!isCurrent(token) || isClosed) return;
    emit(SessionAuthenticated(user));
  }

  /// Records that no session exists. Ignored if [token] is outdated.
  void markUnauthenticated(int token) {
    if (!isCurrent(token) || isClosed) return;
    emit(const SessionUnauthenticated());
  }

  /// Ends the session: used for logout and as the central reaction when a
  /// later API call reports the session is no longer valid (e.g. 401).
  ///
  /// The in-memory user is cleared first so protected screens close
  /// immediately, then stored credentials are removed. Any attempt still
  /// in flight is invalidated.
  Future<void> endSession() async {
    _attempt++;
    if (!isClosed) emit(const SessionUnauthenticated());
    await _signOut();
  }
}
