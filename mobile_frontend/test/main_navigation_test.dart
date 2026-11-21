// Widget tests for the main navigation shell through the real app (MainApp
// and the real GoRouter) with injected fakes: branches, deep links, state
// preservation, system back, shell visibility, keyboard and protection.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_frontend/domain/errors/auth_exceptions.dart';
import 'package:mobile_frontend/helper/network/internet_connection_service.dart';
import 'package:mobile_frontend/main.dart';
import 'package:mobile_frontend/util/routes/route_guard.dart';
import 'package:mobile_frontend/util/routes/routes_string.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';
import 'package:mobile_frontend/view/navigation/app_nav_bar.dart';
import 'package:mobile_frontend/view/screens/authentication/view/login_screen.dart';
import 'package:mobile_frontend/view/screens/home_screen/view/home_screen.dart';
import 'package:mobile_frontend/view/screens/no_internet_screen/view/no_internet_screen.dart';
import 'package:mobile_frontend/view/screens/order_history_screen/view/order_history_screen.dart';
import 'package:mobile_frontend/view/screens/profile_screen/view/profile_screen.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/view/current_order_screen.dart';
import 'package:mobile_frontend/view/screens/splash_screen/view/splash_screen.dart';
import 'package:mobile_frontend/view/screens/wallet_screen/view/wallet_screen.dart';
import 'package:mobile_frontend/view/widget/navigation/main_nav_destination.dart';
import 'package:mobile_frontend/view/widget/navigation/main_navigation_bar.dart';

import 'fakes.dart';
import 'test_app.dart';

void main() {
  late FakeInternetConnectionService internet;
  late FakeAuthRepository repo;

  /// Screen type expected for each destination, in branch order.
  const screens = <MainNavDestination, Type>{
    MainNavDestination.home: HomeScreen,
    MainNavDestination.orderHistory: OrderHistoryScreen,
    MainNavDestination.wallet: WalletScreen,
    MainNavDestination.profile: ProfileScreen,
  };

  setUp(() {
    internet = FakeInternetConnectionService();
    repo = FakeAuthRepository(hasSession: true); // signed in → Home
  });

  Future<void> launch(WidgetTester tester) async {
    await tester.pumpWidget(
      MainApp(connectivityService: internet, authRepository: repo),
    );
    await tester.pumpAndSettle();
  }

  final bar = find.byType(MainNavigationBar);
  Finder item(MainNavDestination d) => find.byKey(MainNavigationBar.itemKey(d));

  GoRouter router(WidgetTester tester) =>
      GoRouter.of(tester.element(find.byType(AppNavBar)));

  /// Branch index according to GoRouter (the source of truth).
  int branchIndex(WidgetTester tester) => tester
      .widget<AppNavBar>(find.byType(AppNavBar))
      .navigationShell
      .currentIndex;

  /// Index the visual bar is showing as selected.
  int shownIndex(WidgetTester tester) =>
      tester.widget<MainNavigationBar>(bar).selectedIndex;

  /// Expects [d] to be the open destination everywhere.
  void expectOn(WidgetTester tester, MainNavDestination d) {
    expect(branchIndex(tester), d.index);
    expect(shownIndex(tester), d.index);
    expect(find.byType(screens[d]!), findsOneWidget);
  }

  Future<void> tapTab(WidgetTester tester, MainNavDestination d) async {
    await tester.tap(item(d));
    await tester.pumpAndSettle();
  }

  /// Simulates the Android/system back button.
  Future<void> systemBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  /// Pushes a page onto the current branch's own Navigator, standing in for
  /// a nested route (none exist in production yet).
  void pushNested(WidgetTester tester, Type onScreen) {
    Navigator.of(tester.element(find.byType(onScreen))).push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('nested-page')),
      ),
    );
  }

  final nested = find.text('nested-page');

  group('branches', () {
    testWidgets('starts on Home with the bar and four destinations', (
      tester,
    ) async {
      await launch(tester);
      expectOn(tester, MainNavDestination.home);
      expect(MainNavDestination.values.length, 4);
      for (final d in MainNavDestination.values) {
        expect(item(d), findsOneWidget);
      }
    });

    testWidgets('branch order matches the route constants', (tester) async {
      expect(MainNavDestination.values.length, mainShellRoutes.length);
      expect(mainShellRoutes, [
        RoutesString.home,
        RoutesString.orderHistory,
        RoutesString.wallet,
        RoutesString.profile,
      ]);
      for (final d in MainNavDestination.values) {
        expect(mainShellRoutes[d.index], isNot(RoutesString.currentOrder));
      }
    });

    testWidgets('tapping each destination selects its branch and screen', (
      tester,
    ) async {
      await launch(tester);
      for (final d in MainNavDestination.values.reversed) {
        await tapTab(tester, d);
        expectOn(tester, d);
        // Its title is shown in the app bar and as the bar label; Home
        // shows the greeting instead of a visible title (D-A71).
        expect(
          find.text(d.label(l10n)),
          findsNWidgets(d == MainNavDestination.home ? 1 : 2),
        );
      }
    });

    testWidgets('direct route entry selects the matching destination', (
      tester,
    ) async {
      await launch(tester);
      final go = router(tester);
      for (final d in MainNavDestination.values.reversed) {
        go.go(mainShellRoutes[d.index]);
        await tester.pumpAndSettle();
        expectOn(tester, d);
        expect(
          go.routerDelegate.currentConfiguration.uri.path,
          mainShellRoutes[d.index],
        );
      }
    });

    testWidgets('placeholders show the under-construction state', (
      tester,
    ) async {
      await launch(tester);
      // Order History shows its declined-offers section (Task 36): with no
      // backend it says the service is not connected, never "none".
      await tapTab(tester, MainNavDestination.orderHistory);
      expect(find.text(l10n.orderHistoryPlaceholderMessage), findsOneWidget);
      expect(find.text(l10n.declinedOffersNotConfigured), findsOneWidget);
      expect(find.text(l10n.declinedOffersEmpty), findsNothing);
      // Profile is the fourth tab (D-A70).
      await tapTab(tester, MainNavDestination.profile);
      expect(find.byType(ProfileScreen), findsOneWidget);
    });
  });

  group('state preservation', () {
    testWidgets('each branch keeps its own stack across tab switches', (
      tester,
    ) async {
      await launch(tester);
      await tapTab(tester, MainNavDestination.orderHistory);
      pushNested(tester, OrderHistoryScreen);
      await tester.pumpAndSettle();
      expect(nested, findsOneWidget);
      // The shell stays visible around a nested page.
      expect(bar, findsOneWidget);

      await tapTab(tester, MainNavDestination.home);
      expectOn(tester, MainNavDestination.home);
      expect(nested, findsNothing);

      await tapTab(tester, MainNavDestination.orderHistory);
      expect(branchIndex(tester), MainNavDestination.orderHistory.index);
      expect(nested, findsOneWidget);
    });

    testWidgets('tapping the current destination does not reset its stack', (
      tester,
    ) async {
      await launch(tester);
      await tapTab(tester, MainNavDestination.wallet);
      pushNested(tester, WalletScreen);
      await tester.pumpAndSettle();
      await tapTab(tester, MainNavDestination.wallet);
      expect(nested, findsOneWidget);
    });

    testWidgets('branch pages are not rebuilt from scratch when switching', (
      tester,
    ) async {
      await launch(tester);
      final homeElement = tester.element(find.byType(HomeScreen));
      await tapTab(tester, MainNavDestination.orderHistory);
      await tapTab(tester, MainNavDestination.home);
      expect(
        identical(tester.element(find.byType(HomeScreen)), homeElement),
        isTrue,
      );
    });
  });

  group('system back', () {
    /// Records platform calls so "the app would close" can be observed.
    List<String> recordPlatformCalls(WidgetTester tester) {
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      return calls;
    }

    testWidgets('nested page pops first, then branch root returns to Home', (
      tester,
    ) async {
      await launch(tester);
      final calls = recordPlatformCalls(tester);
      await tapTab(tester, MainNavDestination.orderHistory);
      pushNested(tester, OrderHistoryScreen);
      await tester.pumpAndSettle();

      // 1st back: only the nested page closes; still on the same tab.
      await systemBack(tester);
      expect(nested, findsNothing);
      expectOn(tester, MainNavDestination.orderHistory);

      // 2nd back: at the branch root → Home.
      await systemBack(tester);
      expectOn(tester, MainNavDestination.home);
      expect(calls, isNot(contains('SystemNavigator.pop')));
    });

    testWidgets('nested page on Home pops without leaving the app', (
      tester,
    ) async {
      await launch(tester);
      final calls = recordPlatformCalls(tester);
      pushNested(tester, HomeScreen);
      await tester.pumpAndSettle();
      await systemBack(tester);
      expect(nested, findsNothing);
      expectOn(tester, MainNavDestination.home);
      expect(calls, isNot(contains('SystemNavigator.pop')));
    });

    testWidgets('Home root: back is left to the platform (app exit)', (
      tester,
    ) async {
      await launch(tester);
      final calls = recordPlatformCalls(tester);
      await systemBack(tester);
      // Not intercepted: Flutter asks the platform to close the app.
      expect(calls, contains('SystemNavigator.pop'));
    });

    testWidgets('returning Home by back keeps the other branch stack', (
      tester,
    ) async {
      await launch(tester);
      await tapTab(tester, MainNavDestination.profile);
      await systemBack(tester);
      expectOn(tester, MainNavDestination.home);
      await tapTab(tester, MainNavDestination.profile);
      expectOn(tester, MainNavDestination.profile);
    });
  });

  group('Current Order page (standalone, D-A73)', () {
    testWidgets('pushed above a tab: no bar, no selected tab; Back returns '
        'to the same tab', (tester) async {
      await launch(tester);
      await tapTab(tester, MainNavDestination.wallet);
      router(tester).push(RoutesString.currentOrder);
      await tester.pumpAndSettle();
      expect(find.byType(CurrentOrderScreen), findsOneWidget);
      expect(bar, findsNothing);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expectOn(tester, MainNavDestination.wallet);
    });

    testWidgets('as the first page (deep link), Back and system back go '
        'Home', (tester) async {
      await launch(tester);
      router(tester).go(RoutesString.currentOrder);
      await tester.pumpAndSettle();
      expect(find.byType(CurrentOrderScreen), findsOneWidget);
      await systemBack(tester);
      expectOn(tester, MainNavDestination.home);

      router(tester).go(RoutesString.currentOrder);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expectOn(tester, MainNavDestination.home);
    });

    testWidgets('/notifications no longer exists', (tester) async {
      await launch(tester);
      expect(
        router(
          tester,
        ).configuration.findMatch(Uri.parse('/notifications')).isEmpty,
        isTrue,
      );
    });
  });

  group('shell visibility', () {
    testWidgets('Login has no navigation bar', (tester) async {
      repo.hasSession = false;
      await launch(tester);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(bar, findsNothing);
      expect(find.byType(AppNavBar), findsNothing);
    });

    testWidgets('No Internet has no navigation bar', (tester) async {
      internet.result = InternetReachability.disconnected;
      await launch(tester);
      expect(find.byType(NoInternetScreen), findsOneWidget);
      expect(bar, findsNothing);
    });

    testWidgets('Splash (startup error) has no navigation bar', (tester) async {
      repo.userError = const ProfileUnavailableException();
      await launch(tester);
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(bar, findsNothing);
    });

    testWidgets('signing out from a tab closes the shell → Login', (
      tester,
    ) async {
      await launch(tester);
      await tapTab(tester, MainNavDestination.wallet);
      final session = tester
          .element(find.byType(WalletScreen))
          .read<AppSessionCubit>();
      await session.endSession();
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(bar, findsNothing);
    });
  });

  group('keyboard and safe area', () {
    testWidgets('bar hides while the keyboard is open and returns after', (
      tester,
    ) async {
      await launch(tester);
      expect(bar, findsOneWidget);

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(bar, findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      expect(bar, findsOneWidget);
    });

    testWidgets('page body ends above the bar and the system inset', (
      tester,
    ) async {
      setScreenSize(tester, 375, 800);
      tester.view.padding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.resetPadding);
      await launch(tester);
      final barRect = tester.getRect(bar);
      expect(barRect.bottom, 800);
      expect(
        tester.getRect(find.byType(HomeScreen)).bottom,
        lessThanOrEqualTo(barRect.top),
      );
    });
  });

  group('responsive shell', () {
    for (final width in [
      320.0,
      375.0,
      450.5,
      600.0,
      800.5,
      840.0,
      1024.0,
      1440.0,
      1920.5,
    ]) {
      testWidgets('width $width: every tab opens without overflow', (
        tester,
      ) async {
        setScreenSize(tester, width, 800);
        await launch(tester);
        for (final d in MainNavDestination.values) {
          await tapTab(tester, d);
          expectOn(tester, d);
          expect(tester.takeException(), isNull);
        }
      });
    }

    testWidgets('landscape short screen: every tab opens without overflow', (
      tester,
    ) async {
      setScreenSize(tester, 740, 320);
      await launch(tester);
      for (final d in MainNavDestination.values) {
        await tapTab(tester, d);
        expect(tester.takeException(), isNull);
      }
    });
  });

  testWidgets('layout is RTL inside the shell: Home on the right', (
    tester,
  ) async {
    await launch(tester);
    expect(
      Directionality.of(tester.element(find.byType(HomeScreen))),
      TextDirection.rtl,
    );
    expect(
      tester.getCenter(item(MainNavDestination.home)).dx,
      greaterThan(tester.getCenter(item(MainNavDestination.wallet)).dx),
    );
  });
}
