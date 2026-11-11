// The single routing policy for startup and authenticated routes.

import 'package:mobile_frontend/util/routes/routes_string.dart';
import 'package:mobile_frontend/view/screens/splash_screen/cubit/splash_cubit.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';

/// Routes anyone may open without a session.
const Set<String> publicRoutes = {
  RoutesString.splash,
  RoutesString.noInternet,
  RoutesString.login,
};

/// Decides where the user may be, given startup progress and session state.
/// Returns the path to redirect to, or null to stay on [location].
///
/// This is the only place navigation decisions are made; screens never call
/// `go` for startup. Each rule returns null when the user is already on the
/// target, so redirects cannot loop.
///
/// - Signed in: startup/login screens forward to Home; everything else is open.
/// - Signed out: everything leads to Login.
/// - Unknown (startup running or failed): protected routes are closed and
///   the startup screen matching [startup] is shown.
String? resolveRedirect({
  required String location,
  required SplashState startup,
  required AppSessionState session,
}) {
  final isPublic = publicRoutes.contains(location);

  switch (session) {
    case SessionAuthenticated():
      return isPublic ? RoutesString.home : null;
    case SessionUnauthenticated():
      return location == RoutesString.login ? null : RoutesString.login;
    case SessionUnknown():
      final String? target = switch (startup) {
        SplashOffline() => RoutesString.noInternet,
        // Startup errors (and its not-yet-started state) are shown on Splash.
        SplashInitial() ||
        SplashConnectivityCheckFailed() ||
        SplashServiceUnavailable() ||
        SplashProfileFailure() ||
        SplashBlocked() ||
        SplashFailure() => RoutesString.splash,
        // While checking, stay on the current startup screen (e.g. No
        // Internet keeps showing its disabled Retry button).
        SplashChecking() || SplashResolved() => null,
      };
      if (target != null) return target == location ? null : target;
      return isPublic ? null : RoutesString.splash;
  }
}
