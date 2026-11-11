// Unit tests for the routing policy in resolveRedirect: protected routes
// stay closed until the session is authenticated, and no rule redirects to
// the page the user is already on (no loops).

import 'package:flutter_test/flutter_test.dart';
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
}
