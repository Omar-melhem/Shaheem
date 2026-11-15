// The single routing policy for startup and authenticated routes.

import 'package:flutter/foundation.dart';
import 'package:mobile_frontend/util/routes/routes_string.dart';
import 'package:mobile_frontend/view/screens/splash_screen/cubit/splash_cubit.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';

/// Routes anyone may open without a session.
const Set<String> publicRoutes = {
  RoutesString.splash,
  RoutesString.noInternet,
  RoutesString.login,
};

/// Root paths of the main navigation shell's branches, in bar order.
/// All of them are protected.
const List<String> mainShellRoutes = [
  RoutesString.home,
  RoutesString.notifications,
  RoutesString.currentOrder,
  RoutesString.orderHistory,
  RoutesString.profile,
];

/// Whether [location] is a main-shell branch root or a route nested in one.
bool isMainShellRoute(String location) => mainShellRoutes.any(
  (root) => location == root || location.startsWith('$root/'),
);

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
///
/// [debugPreviewActive] is the TEMPORARY development exception (see
/// `DebugShellPreview`): in a debug build, a signed-out developer who
/// pressed the Login preview button may open the main-shell routes. It is
/// ANDed with [kDebugMode] here as well, so in profile/release builds the
/// argument has no effect whatever the caller passes.
String? resolveRedirect({
  required String location,
  required SplashState startup,
  required AppSessionState session,
  bool debugPreviewActive = false,
}) {
  final isPublic = publicRoutes.contains(location);

  switch (session) {
    case SessionAuthenticated():
      return isPublic ? RoutesString.home : null;
    case SessionUnauthenticated():
      if (location == RoutesString.login) return null;
      // TODO(debug-preview): remove this rule with DebugShellPreview.
      if (kDebugMode && debugPreviewActive && isMainShellRoute(location)) {
        return null;
      }
      return RoutesString.login;
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
