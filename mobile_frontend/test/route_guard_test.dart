// Unit tests for the routing policy in resolveRedirect: protected routes
// stay closed until the session is authenticated, and no rule redirects to
// the page the user is already on (no loops).

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_frontend/util/routes/debug_shell_preview.dart';
import 'package:mobile_frontend/util/routes/route_guard.dart';
import 'package:mobile_frontend/util/routes/routes_string.dart';
import 'package:mobile_frontend/view/screens/splash_screen/cubit/splash_cubit.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';

import 'fakes.dart';

/// Shorthand for calling the policy in tests.
String? redirect(
  String location,
  SplashState startup,
  AppSessionState session,
) => resolveRedirect(location: location, startup: startup, session: session);

void main() {
  const unknown = SessionUnknown();
  const signedOut = SessionUnauthenticated();
  const signedIn = SessionAuthenticated(testUser);

  test('/home before initialization is blocked → Splash', () {
    expect(
      redirect(RoutesString.home, const SplashChecking(), unknown),
      RoutesString.splash,
    );
    expect(
      redirect(RoutesString.home, const SplashInitial(), unknown),
      RoutesString.splash,
    );
  });

  test('/home while startup failed is blocked → Splash', () {
    expect(
      redirect(RoutesString.home, const SplashProfileFailure(), unknown),
      RoutesString.splash,
    );
    expect(
      redirect(RoutesString.home, const SplashBlocked(), unknown),
      RoutesString.splash,
    );
  });

  test('offline → No Internet; stays there while retrying', () {
    expect(
      redirect(RoutesString.splash, const SplashOffline(), unknown),
      RoutesString.noInternet,
    );
    expect(
      redirect(RoutesString.noInternet, const SplashOffline(), unknown),
      isNull,
    );
    expect(
      redirect(RoutesString.noInternet, const SplashChecking(), unknown),
      isNull,
    );
  });

  test('service unavailable is shown on Splash, not No Internet', () {
    expect(
      redirect(
        RoutesString.noInternet,
        const SplashServiceUnavailable(),
        unknown,
      ),
      RoutesString.splash,
    );
    expect(
      redirect(RoutesString.splash, const SplashServiceUnavailable(), unknown),
      isNull,
    );
  });

  test('connectivity check failure is shown on Splash', () {
    expect(
      redirect(
        RoutesString.noInternet,
        const SplashConnectivityCheckFailed(),
        unknown,
      ),
      RoutesString.splash,
    );
    expect(
      redirect(
        RoutesString.home,
        const SplashConnectivityCheckFailed(),
        unknown,
      ),
      RoutesString.splash,
    );
  });

  test('signed out → Login from anywhere, including /home', () {
    for (final location in [
      RoutesString.splash,
      RoutesString.noInternet,
      RoutesString.home,
    ]) {
      expect(
        redirect(location, const SplashResolved(), signedOut),
        RoutesString.login,
      );
    }
    expect(
      redirect(RoutesString.login, const SplashResolved(), signedOut),
      isNull,
    );
  });

  test('signed in → startup and login screens forward to Home', () {
    for (final location in publicRoutes) {
      expect(
        redirect(location, const SplashResolved(), signedIn),
        RoutesString.home,
      );
    }
    expect(
      redirect(RoutesString.home, const SplashResolved(), signedIn),
      isNull,
    );
  });

  group('main shell routes', () {
    test('five distinct branch roots, Current Order in the middle', () {
      expect(mainShellRoutes, [
        RoutesString.home,
        RoutesString.notifications,
        RoutesString.currentOrder,
        RoutesString.orderHistory,
        RoutesString.profile,
      ]);
      expect(mainShellRoutes.toSet().length, 5);
      expect(mainShellRoutes.every((path) => path.startsWith('/')), isTrue);
      expect(mainShellRoutes.any(publicRoutes.contains), isFalse);
    });

    test('isMainShellRoute matches roots and nested paths only', () {
      expect(isMainShellRoute(RoutesString.profile), isTrue);
      expect(isMainShellRoute('${RoutesString.home}/details'), isTrue);
      expect(isMainShellRoute('/homework'), isFalse);
      expect(isMainShellRoute(RoutesString.login), isFalse);
    });

    test('signed in → every destination is open', () {
      for (final path in mainShellRoutes) {
        expect(redirect(path, const SplashResolved(), signedIn), isNull);
      }
    });

    test('signed out or unknown → every destination is closed', () {
      // This is the behavior of profile/release builds, where the debug
      // preview can never be active.
      for (final path in mainShellRoutes) {
        expect(
          redirect(path, const SplashResolved(), signedOut),
          RoutesString.login,
        );
        expect(
          redirect(path, const SplashChecking(), unknown),
          RoutesString.splash,
        );
      }
    });
  });

  group('debug preview (temporary)', () {
    String? preview(String location, AppSessionState session) =>
        resolveRedirect(
          location: location,
          startup: const SplashResolved(),
          session: session,
          debugPreviewActive: true,
        );

    test('opens the main-shell routes for a signed-out developer', () {
      for (final path in mainShellRoutes) {
        expect(preview(path, signedOut), isNull);
      }
      expect(preview('${RoutesString.home}/details', signedOut), isNull);
    });

    test('opens nothing else and never replaces startup', () {
      expect(preview('/somewhere-else', signedOut), RoutesString.login);
      expect(preview(RoutesString.splash, signedOut), RoutesString.login);
      // Session still unknown: protected routes stay closed.
      expect(
        resolveRedirect(
          location: RoutesString.home,
          startup: const SplashChecking(),
          session: unknown,
          debugPreviewActive: true,
        ),
        RoutesString.splash,
      );
    });

    test('switch: off by default, on after enter, off after exit', () {
      final switch_ = DebugShellPreview();
      expect(switch_.isActive, isFalse);
      switch_.enter();
      expect(switch_.isActive, isTrue);
      switch_.exit();
      expect(switch_.isActive, isFalse);
    });

    test('switch simulating a non-debug build can never turn on', () {
      final switch_ = DebugShellPreview(allowed: false);
      expect(switch_.isAvailable, isFalse);
      switch_.enter();
      expect(switch_.isActive, isFalse);
    });
  });
}
