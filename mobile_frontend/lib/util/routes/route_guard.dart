// The single routing policy for startup and authenticated routes.

import 'package:flutter/foundation.dart';
import 'package:mobile_frontend/util/routes/routes_string.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/cubit/current_order_cubit.dart';
import 'package:mobile_frontend/view/screens/splash_screen/cubit/splash_cubit.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';

/// Routes anyone may open without a session.
const Set<String> publicRoutes = {
  RoutesString.splash,
  RoutesString.noInternet,
  RoutesString.login,
};

/// Root paths of the main navigation shell's branches, in bar order
/// (`MainNavDestination` order, D-A70). All of them are protected.
const List<String> mainShellRoutes = [
  RoutesString.home,
  RoutesString.orderHistory,
  RoutesString.wallet,
  RoutesString.profile,
];

/// Protected pages opened above the shell (not tabs).
const Set<String> shellOverlayRoutes = {
  RoutesString.currentOrder,
  RoutesString.settings,
  RoutesString.about,
};

/// Where a signed-in captain lands after startup or sign-in, from the
/// authoritative active-order lookup (D-A73):
/// - still being resolved → null (stay on the current public screen);
/// - an active order → Current Order;
/// - confirmed none, not configured or a failed lookup → Home. A failure is
///   not "no order": the Current Order state keeps the explicit failure and
///   Home shows it with a Retry; nobody is signed out.
String? postSignInDestination(CurrentOrderState activeOrder) =>
    switch (activeOrder) {
      CurrentOrderInitial() || CurrentOrderLoading() => null,
      CurrentOrderActive() => RoutesString.currentOrder,
      CurrentOrderEmpty() ||
      CurrentOrderNotConfigured() ||
      CurrentOrderFailure() ||
      // The order just ended (delivered, cancelled, reassigned): no active
      // work, so the normal destination applies.
      CurrentOrderDelivered() ||
      CurrentOrderEnded() => RoutesString.home,
    };

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
/// - Signed in: startup/login screens forward to the post-sign-in
///   destination ([postSignInDestination], from [activeOrder]) once the
///   active order is resolved; everything else is open. There is no order
///   rule for other routes: recovery never redirects arbitrary navigation.
/// - Signed out: everything leads to Login.
/// - Unknown (startup running or failed): protected routes are closed and
///   the startup screen matching [startup] is shown.
///
/// [debugPreviewActive] is the TEMPORARY development exception (see
/// `DebugShellPreview`): in a debug build, a signed-out developer who
/// pressed the Login preview button may open the main-shell routes and
/// [shellOverlayRoutes]. It is
/// ANDed with [kDebugMode] here as well, so in profile/release builds the
/// argument has no effect whatever the caller passes.
String? resolveRedirect({
  required String location,
  required SplashState startup,
  required AppSessionState session,
  CurrentOrderState activeOrder = const CurrentOrderNotConfigured(),
  bool debugPreviewActive = false,
}) {
  final isPublic = publicRoutes.contains(location);

  switch (session) {
    case SessionAuthenticated():
      if (!isPublic) return null;
      final target = postSignInDestination(activeOrder);
      return target == location ? null : target;
    case SessionUnauthenticated():
      if (location == RoutesString.login) return null;
      // TODO(debug-preview): remove this rule with DebugShellPreview.
      if (kDebugMode &&
          debugPreviewActive &&
          (isMainShellRoute(location) ||
              shellOverlayRoutes.contains(location))) {
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
