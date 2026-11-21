// Active-order recovery through the real app (D-A73): startup routing from
// the authoritative lookup, failure kept explicit, foreground return,
// completion elsewhere and sign-out. Test repositories stand in for the
// backend; a fresh MainApp per test plays a fresh application process.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_frontend/domain/errors/order_exceptions.dart';
import 'package:mobile_frontend/main.dart';
import 'package:mobile_frontend/util/routes/debug_shell_preview.dart';
import 'package:mobile_frontend/util/routes/routes_string.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';
import 'package:mobile_frontend/view/navigation/app_nav_bar.dart';
import 'package:mobile_frontend/view/screens/authentication/view/login_screen.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/cubit/current_order_cubit.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/view/current_order_screen.dart';
import 'package:mobile_frontend/view/screens/home_screen/view/home_screen.dart';
import 'package:mobile_frontend/view/screens/splash_screen/view/splash_screen.dart';
import 'package:mobile_frontend/view/widget/navigation/main_nav_destination.dart';
import 'package:mobile_frontend/view/widget/navigation/main_navigation_bar.dart';

import 'fakes.dart';
import 'test_app.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeActiveOrderRepository orders;

  setUp(() {
    auth = FakeAuthRepository(hasSession: true);
    orders = FakeActiveOrderRepository();
  });

  /// A fresh app instance with a valid persisted test session.
  Future<void> start(WidgetTester tester, {DebugShellPreview? preview}) async {
    await tester.pumpWidget(
      MainApp(
        connectivityService: FakeInternetConnectionService(),
        authRepository: auth,
        activeOrderRepository: orders,
        captainLocationRepository: FakeCaptainLocationRepository(),
        debugShellPreview: preview,
      ),
    );
    await tester.pumpAndSettle();
  }

  void resume(WidgetTester tester) {
    for (final s in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
  }

  CurrentOrderCubit cubit(WidgetTester tester) =>
      tester.element(find.byType(MaterialApp)).read<CurrentOrderCubit>();

  String location(WidgetTester tester) => GoRouter.of(
    tester.element(find.byType(Navigator).first),
  ).state.matchedLocation;

  group('cold start', () {
    testWidgets('an unfinished order → Current Order first; Back → Home', (
      tester,
    ) async {
      orders.order = testActiveOrder;
      await start(tester);
      expect(find.byType(CurrentOrderScreen), findsOneWidget);
      expect(orders.calls, 1);
      expect(find.text(testActiveOrder.restaurantName), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      // Home keeps a way back to the order.
      expect(find.text(l10n.homeActiveOrderOpen), findsOneWidget);
      await tester.tap(find.text(l10n.homeActiveOrderOpen));
      await tester.pumpAndSettle();
      expect(find.byType(CurrentOrderScreen), findsOneWidget);
    });

    testWidgets('confirmed none → Home, nothing about an order shown', (
      tester,
    ) async {
      await start(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text(l10n.homeActiveOrderOpen), findsNothing);
      expect(find.text(l10n.homeActiveOrderCheckFailed), findsNothing);
    });

    testWidgets('a slow lookup keeps the startup screen until it answers', (
      tester,
    ) async {
      orders
        ..pending = Completer<void>()
        ..order = testActiveOrder;
      await tester.pumpWidget(
        MainApp(
          connectivityService: FakeInternetConnectionService(),
          authRepository: auth,
          activeOrderRepository: orders,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.byType(SplashScreen), findsOneWidget);
      orders.pending!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(CurrentOrderScreen), findsOneWidget);
    });

    for (final (name, error) in [
      ('offline', const OrderNetworkUnavailableException()),
      ('service down', const OrderServiceUnavailableException()),
    ]) {
      testWidgets('$name: Home with an explicit "could not check" and Retry; '
          'never "no order", never signed out', (tester) async {
        orders.error = error;
        await start(tester);
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text(l10n.homeActiveOrderCheckFailed), findsOneWidget);
        expect(cubit(tester).state, isA<CurrentOrderFailure>());
        expect(
          tester.element(find.byType(HomeScreen)).read<AppSessionCubit>().state,
          isA<SessionAuthenticated>(),
        );
        // Retry finds the order now and opens it.
        orders
          ..error = null
          ..order = testActiveOrder;
        await tester.tap(find.text(l10n.retry).first);
        await tester.pumpAndSettle();
        expect(find.byType(CurrentOrderScreen), findsOneWidget);
      });
    }

    testWidgets('production placeholder (not configured) → Home, no claim', (
      tester,
    ) async {
      await tester.pumpWidget(
        MainApp(
          connectivityService: FakeInternetConnectionService(),
          authRepository: auth,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      final app = tester.element(find.byType(MaterialApp));
      expect(
        app.read<CurrentOrderCubit>().state,
        isA<CurrentOrderNotConfigured>(),
      );
      expect(find.text(l10n.homeActiveOrderOpen), findsNothing);
    });

    testWidgets('signed out: no lookup at all', (tester) async {
      auth.hasSession = false;
      await start(tester);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(orders.calls, 0);
    });

    testWidgets('debug preview (no session): inert, never looks up', (
      tester,
    ) async {
      auth.hasSession = false;
      await start(tester);
      final button = find.text(l10n.debugPreviewButton);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      resume(tester);
      await tester.pumpAndSettle();
      expect(orders.calls, 0);
    });
  });

  group('foreground return', () {
    testWidgets('an order appeared meanwhile → Current Order once, from any '
        'tab; no duplicate page or loop', (tester) async {
      await start(tester);
      await tester.tap(
        find.byKey(MainNavigationBar.itemKey(MainNavDestination.wallet)),
      );
      await tester.pumpAndSettle();
      orders.order = testActiveOrder;
      final before = orders.calls;
      resume(tester);
      await tester.pumpAndSettle();
      expect(orders.calls, before + 1);
      expect(find.byType(CurrentOrderScreen), findsOneWidget);
      expect(location(tester), RoutesString.currentOrder);

      // A second resume re-reads but pushes nothing more.
      resume(tester);
      await tester.pumpAndSettle();
      expect(find.byType(CurrentOrderScreen), findsOneWidget);
      // Back returns to the tab the captain was on.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(CurrentOrderScreen), findsNothing);
      expect(
        tester
            .widget<AppNavBar>(find.byType(AppNavBar))
            .navigationShell
            .currentIndex,
        MainNavDestination.wallet.index,
      );
    });

    testWidgets('concurrent resumes coalesce into bounded reads', (
      tester,
    ) async {
      await start(tester);
      orders
        ..pending = Completer<void>()
        ..order = testActiveOrder;
      final before = orders.calls;
      resume(tester);
      resume(tester);
      resume(tester);
      await tester.pump();
      orders.pending!.complete();
      await tester.pumpAndSettle();
      // One running read plus at most one fresh follow-up.
      expect(orders.calls - before, lessThanOrEqualTo(2));
      expect(find.byType(CurrentOrderScreen), findsOneWidget);
    });

    testWidgets('no order and a failure navigate nowhere', (tester) async {
      await start(tester);
      resume(tester);
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      orders.error = const OrderServiceUnavailableException();
      resume(tester);
      await tester.pumpAndSettle();
      expect(find.byType(CurrentOrderScreen), findsNothing);
      expect(find.text(l10n.homeActiveOrderCheckFailed), findsOneWidget);
    });

    testWidgets('completed elsewhere: resume on the page shows the confirmed '
        'absence', (tester) async {
      orders.order = testActiveOrder;
      await start(tester);
      expect(find.byType(CurrentOrderScreen), findsOneWidget);
      orders.order = null;
      resume(tester);
      await tester.pumpAndSettle();
      expect(find.text(l10n.currentOrderEmptyTitle), findsOneWidget);
    });
  });

  group('sign-out', () {
    testWidgets('clears the order; a late answer is dropped; the next '
        'captain starts clean', (tester) async {
      orders.order = testActiveOrder;
      await start(tester);
      expect(find.byType(CurrentOrderScreen), findsOneWidget);
      orders.pending = Completer<void>();
      unawaited(cubit(tester).refreshed());
      await tester.pump();
      await tester
          .element(find.byType(CurrentOrderScreen))
          .read<AppSessionCubit>()
          .endSession();
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(cubit(tester).state, isA<CurrentOrderInitial>());
      orders.pending!.complete();
      await tester.pumpAndSettle();
      expect(cubit(tester).state, isA<CurrentOrderInitial>());
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
