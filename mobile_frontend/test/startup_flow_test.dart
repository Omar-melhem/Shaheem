// Widget tests for the full app (MainApp + real router) with injected fake
// services: startup destinations, the shared session, and the single global
// offline banner across routes.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_frontend/data/repositories/auth_repository_placeholder.dart';
import 'package:mobile_frontend/domain/errors/auth_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/auth_repository.dart';
import 'package:mobile_frontend/helper/network/internet_connection_service.dart';
import 'package:mobile_frontend/main.dart';
import 'package:mobile_frontend/view/app_state/connectivity/global_connectivity_banner.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';
import 'package:mobile_frontend/view/navigation/app_nav_bar.dart';
import 'package:mobile_frontend/view/screens/authentication/view/login_screen.dart';
import 'package:mobile_frontend/view/screens/home_screen/view/home_screen.dart';
import 'package:mobile_frontend/view/screens/no_internet_screen/view/no_internet_screen.dart';
import 'package:mobile_frontend/view/screens/splash_screen/view/splash_screen.dart';

import 'fakes.dart';
import 'test_app.dart';

void main() {
  late FakeInternetConnectionService internet;
  late FakeAuthRepository repo;

  setUp(() {
    internet = FakeInternetConnectionService();
    repo = FakeAuthRepository(hasSession: true);
  });

  /// Launches the app and waits for startup to settle.
  Future<void> launch(
    WidgetTester tester, {
    AuthRepository? authRepository,
  }) async {
    await tester.pumpWidget(
      MainApp(
        connectivityService: internet,
        authRepository: authRepository ?? repo,
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Simulates the shared monitor reporting a change, then settles.
  Future<void> reportConnectivity(
    WidgetTester tester,
    InternetReachability status,
  ) async {
    internet.result = status;
    internet.emit(status);
    await tester.pumpAndSettle();
  }

  final banner = find.byKey(GlobalConnectivityBanner.barKey);

  group('startup', () {
    testWidgets('default placeholder (no backend) → Login', (tester) async {
      await launch(tester, authRepository: const AuthRepositoryPlaceholder());
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('valid session + user → shared user set, Home shown', (
      tester,
    ) async {
      await launch(tester);
      expect(find.byType(AppNavBar), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
      final session = tester
          .element(find.byType(HomeScreen))
          .read<AppSessionCubit>();
      expect((session.state as SessionAuthenticated).user.id, testUser.id);
    });

    testWidgets('revoked session → Login, credentials cleared', (tester) async {
      repo.validateError = const SessionInvalidException();
      await launch(tester);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(repo.clearCalls, 1);
    });

    testWidgets('profile failure → Splash error, not Home or Login', (
      tester,
    ) async {
      repo.userError = const ProfileUnavailableException();
      await launch(tester);
      expect(find.text(l10n.profileFailureMessage), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('blocked account → access message, no Home', (tester) async {
      repo.validateError = const AccountBlockedException();
      await launch(tester);
      expect(find.text(l10n.accountBlockedMessage), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('backend down → service message, not No Internet', (
      tester,
    ) async {
      repo.validateError = const ServiceUnavailableException();
      await launch(tester);
      expect(find.text(l10n.serviceUnavailableMessage), findsOneWidget);
      expect(find.byType(NoInternetScreen), findsNothing);
    });

    testWidgets('checker failure → recoverable Splash message, not offline', (
      tester,
    ) async {
      internet.result = InternetReachability.checkFailed;
      await launch(tester);
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text(l10n.connectivityCheckFailedMessage), findsOneWidget);
      expect(find.byType(NoInternetScreen), findsNothing);
    });

    testWidgets('offline → No Internet; retry offline stays; online → Home', (
      tester,
    ) async {
      internet.result = InternetReachability.disconnected;
      await launch(tester);
      expect(find.byType(NoInternetScreen), findsOneWidget);
      // During startup the dedicated screen handles it: no global banner.
      expect(banner, findsNothing);

      await tester.tap(find.text(l10n.retry));
      await tester.pumpAndSettle();
      expect(find.byType(NoInternetScreen), findsOneWidget);

      internet.result = InternetReachability.connected;
      await tester.tap(find.text(l10n.retry));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('No Internet resumes startup when the monitor reconnects', (
      tester,
    ) async {
      internet.result = InternetReachability.disconnected;
      await launch(tester);
      expect(find.byType(NoInternetScreen), findsOneWidget);

      await reportConnectivity(tester, InternetReachability.connected);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('logout → shared user cleared, Home closed, Login shown', (
      tester,
    ) async {
      await launch(tester);
      final session = tester
          .element(find.byType(HomeScreen))
          .read<AppSessionCubit>();
      await session.endSession();
      await tester.pumpAndSettle();
      expect(session.state, isA<SessionUnauthenticated>());
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('global connectivity banner', () {
    testWidgets('appears on Home when connection is lost, hides on restore', (
      tester,
    ) async {
      await launch(tester);
      expect(banner, findsNothing);

      await reportConnectivity(tester, InternetReachability.disconnected);
      expect(banner, findsOneWidget);
      // No navigation away: the user stays on Home.
      expect(find.byType(HomeScreen), findsOneWidget);

      await reportConnectivity(tester, InternetReachability.connected);
      expect(banner, findsNothing);
    });

    testWidgets('same global banner on a different route (Login)', (
      tester,
    ) async {
      repo.hasSession = false;
      await launch(tester);
      expect(find.byType(LoginScreen), findsOneWidget);

      await reportConnectivity(tester, InternetReachability.disconnected);
      expect(banner, findsOneWidget);
    });

    testWidgets('mounted exactly once; screens add none', (tester) async {
      await launch(tester);
      await reportConnectivity(tester, InternetReachability.disconnected);
      expect(find.byType(GlobalConnectivityBanner), findsOneWidget);
      expect(banner, findsOneWidget);
    });

    testWidgets('a failed check does not show the offline banner', (
      tester,
    ) async {
      await launch(tester);
      await reportConnectivity(tester, InternetReachability.checkFailed);
      expect(banner, findsNothing);
    });

    testWidgets('banner Retry uses the shared check', (tester) async {
      await launch(tester);
      await reportConnectivity(tester, InternetReachability.disconnected);
      final checksBefore = internet.checks;

      internet.result = InternetReachability.connected;
      await tester.tap(find.text(l10n.retry));
      await tester.pumpAndSettle();
      expect(internet.checks, checksBefore + 1);
      expect(banner, findsNothing);
    });

    testWidgets('page keeps its state when the banner toggles', (tester) async {
      await launch(tester);
      final homeBefore = tester.state(find.byType(StatefulNavigationShell));
      await reportConnectivity(tester, InternetReachability.disconnected);
      await reportConnectivity(tester, InternetReachability.connected);
      expect(
        identical(
          tester.state(find.byType(StatefulNavigationShell)),
          homeBefore,
        ),
        isTrue,
      );
    });

    testWidgets('only one monitor subscription for the whole app', (
      tester,
    ) async {
      await launch(tester);
      await reportConnectivity(tester, InternetReachability.disconnected);
      await reportConnectivity(tester, InternetReachability.connected);
      expect(internet.streamRequests, 1);
    });
  });

  testWidgets('layout is RTL', (tester) async {
    repo.hasSession = false;
    await launch(tester);
    final context = tester.element(find.byType(LoginScreen));
    expect(Directionality.of(context), TextDirection.rtl);
  });
}
