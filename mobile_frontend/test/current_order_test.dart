// Tests for the Current Order destination: the use cases, the Cubit, and
// the full flow through the real app (MainApp + router) with injected
// fakes. Orders, coordinates and positions exist only in these tests.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_frontend/data/repositories/active_order_repository_placeholder.dart';
import 'package:mobile_frontend/data/repositories/captain_location_repository_placeholder.dart';
import 'package:mobile_frontend/domain/entities/active_order.dart';
import 'package:mobile_frontend/domain/errors/order_exceptions.dart';
import 'package:mobile_frontend/domain/use_cases/get_active_order.dart';
import 'package:mobile_frontend/domain/use_cases/get_captain_location.dart';
import 'package:mobile_frontend/main.dart';
import 'package:mobile_frontend/util/routes/routes_string.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';
import 'package:mobile_frontend/view/navigation/app_nav_bar.dart';
import 'package:mobile_frontend/view/screens/authentication/view/login_screen.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/cubit/current_order_cubit.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/view/current_order_screen.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/widget/active_order_pickup_view.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/widget/pickup_map.dart';
import 'package:mobile_frontend/view/screens/home_screen/view/home_screen.dart';
import 'package:mobile_frontend/view/widget/navigation/main_nav_destination.dart';
import 'package:mobile_frontend/view/widget/navigation/main_navigation_bar.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import 'fakes.dart';
import 'test_app.dart';

void main() {
  late FakeActiveOrderRepository orders;
  late FakeCaptainLocationRepository location;

  setUp(() {
    orders = FakeActiveOrderRepository();
    location = FakeCaptainLocationRepository(
      location: const GeoPoint(latitude: 31.97, longitude: 35.92),
    );
  });

  group('GeoPoint.isValid', () {
    test('well-formed means finite and within the geographic ranges', () {
      expect(testPickup.isValid, isTrue);
      // (0, 0) is a well-formed coordinate. Whether it is acceptable for a
      // restaurant is a service-area rule that is not defined yet (D-P31),
      // so the client does not reject it.
      expect(const GeoPoint(latitude: 0, longitude: 0).isValid, isTrue);
      expect(const GeoPoint(latitude: -90, longitude: 180).isValid, isTrue);
      for (final bad in const [
        GeoPoint(latitude: 91, longitude: 35),
        GeoPoint(latitude: 31, longitude: 181),
        GeoPoint(latitude: double.nan, longitude: 35),
        GeoPoint(latitude: 31, longitude: double.infinity),
      ]) {
        expect(bad.isValid, isFalse);
      }
    });
  });

  group('GetActiveOrder', () {
    Future<ActiveOrderResult> run() => GetActiveOrder(orders)();

    test('found / none come straight from the repository', () async {
      expect(await run(), isA<ActiveOrderNone>());
      orders.order = testActiveOrder;
      final result = await run();
      expect((result as ActiveOrderFound).order.orderId, 'order-42');
    });

    test('every failure stays distinct from "no active order"', () async {
      orders.error = const OrderBackendNotConfiguredException();
      expect(await run(), isA<ActiveOrderNotConfigured>());
      orders.error = const OrderNetworkUnavailableException();
      expect(await run(), isA<ActiveOrderNoInternet>());
      orders.error = const OrderServiceUnavailableException();
      expect(await run(), isA<ActiveOrderServiceUnavailable>());
      orders.error = StateError('boom');
      expect(await run(), isA<ActiveOrderFailure>());
    });

    test('a repository that never answers times out as unavailable', () async {
      orders.pending = Completer<void>();
      final result = await GetActiveOrder(
        orders,
        timeout: const Duration(milliseconds: 10),
      )();
      expect(result, isA<ActiveOrderServiceUnavailable>());
    });

    test('production placeholders report "not configured", never data', () {
      expect(
        const ActiveOrderRepositoryPlaceholder().getActiveOrder(),
        throwsA(isA<OrderBackendNotConfiguredException>()),
      );
      expect(
        const CaptainLocationRepositoryPlaceholder().getCurrentLocation(),
        throwsA(isA<LocationNotConfiguredException>()),
      );
    });
  });

  group('GetCaptainLocation', () {
    Future<CaptainLocationResult> run() => GetCaptainLocation(location)();

    test('classifies found, denied, unavailable and not configured', () async {
      expect(await run(), isA<CaptainLocationFound>());
      location.error = const LocationPermissionDeniedException();
      expect(await run(), isA<CaptainLocationPermissionDenied>());
      location.error = const LocationUnavailableException();
      expect(await run(), isA<CaptainLocationUnavailable>());
      location.error = const LocationNotConfiguredException();
      expect(await run(), isA<CaptainLocationNotConfigured>());
    });

    test('a malformed reading is not used as a position', () async {
      location.location = const GeoPoint(latitude: double.nan, longitude: 35);
      expect(await run(), isA<CaptainLocationUnavailable>());
    });
  });

  group('CurrentOrderCubit', () {
    late CurrentOrderCubit cubit;

    setUp(() {
      cubit = CurrentOrderCubit(
        GetActiveOrder(orders),
        GetCaptainLocation(location),
      );
    });
    tearDown(() => cubit.close());

    test('starts idle without asking anything', () {
      expect(cubit.state, isA<CurrentOrderInitial>());
      expect(cubit.state.hasActiveOrder, isFalse);
      expect(orders.calls, 0);
      expect(location.calls, 0);
    });

    test('load while loading is ignored (no overlapping lookups)', () async {
      orders.pending = Completer<void>();
      final first = cubit.load();
      expect(cubit.state, isA<CurrentOrderLoading>());
      await cubit.load();
      await cubit.load();
      expect(orders.calls, 1);
      orders.pending!.complete();
      await first;
      expect(cubit.state, isA<CurrentOrderEmpty>());
    });

    test('active order → map state, then the captain location', () async {
      orders.order = testActiveOrder;
      await cubit.load();
      final state = cubit.state as CurrentOrderActive;
      expect(state.order.orderId, 'order-42');
      expect(state.pickup, same(testPickup));
      expect(state.captainLocation, isA<CaptainLocationFound>());
      expect(state.hasActiveOrder, isTrue);
      expect(location.calls, 1);
    });

    test('no order or a failure never asks for the location', () async {
      await cubit.load();
      orders.error = const OrderServiceUnavailableException();
      await cubit.load();
      expect(
        (cubit.state as CurrentOrderFailure).kind,
        CurrentOrderFailureKind.serviceUnavailable,
      );
      expect(cubit.state.hasActiveOrder, isFalse);
      expect(location.calls, 0);
    });

    test('missing or malformed coordinates: still active, map off', () async {
      for (final pickup in const [
        null,
        GeoPoint(latitude: 120, longitude: 35),
        GeoPoint(latitude: double.nan, longitude: 35),
      ]) {
        orders.order = ActiveOrder(
          orderId: 'o',
          restaurantName: 'r',
          pickupLocation: pickup,
        );
        await cubit.load();
        // The same state as any other active order…
        final state = cubit.state as CurrentOrderActive;
        expect(state.hasActiveOrder, isTrue);
        expect(state.order.orderId, 'o');
        // …with only the map switched off, and no made-up destination.
        expect(state.canShowMap, isFalse);
        expect(state.pickup, isNull);
      }
      // No map, so the captain's location is never requested.
      expect(location.calls, 0);
      await cubit.retryLocation();
      expect(location.calls, 0);
    });

    test(
      'empty, not configured and failure are three different states',
      () async {
        await cubit.load();
        expect(cubit.state, isA<CurrentOrderEmpty>());

        orders.error = const OrderBackendNotConfiguredException();
        await cubit.load();
        expect(cubit.state, isA<CurrentOrderNotConfigured>());
        expect(cubit.state, isNot(isA<CurrentOrderFailure>()));

        orders.error = const OrderNetworkUnavailableException();
        await cubit.load();
        expect(
          (cubit.state as CurrentOrderFailure).kind,
          CurrentOrderFailureKind.noInternet,
        );
        orders.error = const OrderServiceUnavailableException();
        await cubit.load();
        expect(
          (cubit.state as CurrentOrderFailure).kind,
          CurrentOrderFailureKind.serviceUnavailable,
        );
        // None of them is an active order.
        expect(cubit.state.hasActiveOrder, isFalse);
      },
    );

    test('every load asks the server again and replaces the state', () async {
      orders.order = testActiveOrder;
      await cubit.load();
      expect(cubit.state, isA<CurrentOrderActive>());
      // The order ended on the server in the meantime.
      orders.order = null;
      await cubit.load();
      expect(cubit.state, isA<CurrentOrderEmpty>());
      expect(orders.calls, 2);
    });

    test('retryLocation re-reads only after a location failure', () async {
      orders.order = testActiveOrder;
      location.error = const LocationPermissionDeniedException();
      await cubit.load();
      expect(
        (cubit.state as CurrentOrderActive).captainLocation,
        isA<CaptainLocationPermissionDenied>(),
      );
      // No automatic re-prompt: still one call until the user retries.
      expect(location.calls, 1);

      location.error = null;
      await cubit.retryLocation();
      expect(
        (cubit.state as CurrentOrderActive).captainLocation,
        isA<CaptainLocationFound>(),
      );
      expect(location.calls, 2);
      expect(orders.calls, 1);
    });

    test('an answer arriving after close is dropped', () async {
      orders.pending = Completer<void>();
      orders.order = testActiveOrder;
      final load = cubit.load();
      await cubit.close();
      orders.pending!.complete();
      await load;
      expect(cubit.state, isA<CurrentOrderLoading>());
    });

    test('states do not print order details', () async {
      orders.order = testActiveOrder;
      await cubit.load();
      final text = cubit.state.toString();
      expect(text, isNot(contains('order-42')));
      expect(text, isNot(contains(testActiveOrder.restaurantName)));
    });
  });

  group('flow in the app', () {
    late FakeInternetConnectionService internet;
    late FakeAuthRepository auth;

    /// What the injected map was asked to show, in order.
    late List<PickupMapData> mapRequests;

    setUp(() {
      internet = FakeInternetConnectionService();
      auth = FakeAuthRepository(hasSession: true);
      mapRequests = [];
    });

    /// A stand-in map: records its input and draws a labelled box.
    Widget fakeMap(BuildContext context, PickupMapData data) {
      mapRequests.add(data);
      return const Center(child: Text('fake-map'));
    }

    Future<void> launch(WidgetTester tester, {bool withMap = true}) async {
      await tester.pumpWidget(
        MainApp(
          connectivityService: internet,
          authRepository: auth,
          activeOrderRepository: orders,
          captainLocationRepository: location,
          pickupMapBuilder: withMap ? fakeMap : null,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    }

    final centerItem = find.byKey(
      MainNavigationBar.itemKey(MainNavDestination.currentOrder),
    );
    final spinner = find.byKey(MainNavigationBar.centerProgressKey);

    MainNavigationBar bar(WidgetTester tester) =>
        tester.widget<MainNavigationBar>(find.byType(MainNavigationBar));

    Future<void> openCurrentOrder(WidgetTester tester) async {
      await tester.tap(centerItem);
      await tester.pumpAndSettle();
      expect(find.byType(CurrentOrderScreen), findsOneWidget);
    }

    testWidgets('nothing is looked up until the captain opens it', (
      tester,
    ) async {
      await launch(tester);
      expect(orders.calls, 0);
      expect(location.calls, 0);
      expect(bar(tester).hasActiveOrder, isFalse);
      expect(bar(tester).isCheckingActiveOrder, isFalse);
    });

    testWidgets('tap looks the order up; it is not an order-creation screen', (
      tester,
    ) async {
      await launch(tester);
      await openCurrentOrder(tester);
      expect(orders.calls, 1);
      // Read-only destination: no form, no input, no "add" control.
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(Form), findsNothing);
      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.text(l10n.currentOrderTitle), findsNWidgets(2));
    });

    testWidgets('no active order → localized empty state, no map, no toast', (
      tester,
    ) async {
      await launch(tester);
      await openCurrentOrder(tester);
      expect(l10n.currentOrderEmptyTitle, 'لا يوجد لديك طلب فعال حالياً');
      expect(find.text(l10n.currentOrderEmptyTitle), findsOneWidget);
      expect(find.byType(ActiveOrderPickupView), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(mapRequests, isEmpty);
      expect(location.calls, 0);
      expect(bar(tester).hasActiveOrder, isFalse);
      // Still on the Current Order destination.
      expect(bar(tester).selectedIndex, MainNavDestination.currentOrder.index);

      // Refresh asks again.
      await tester.tap(find.widgetWithText(FilledButton, l10n.refresh));
      await tester.pumpAndSettle();
      expect(orders.calls, 2);
    });

    testWidgets('duplicate taps while loading start one lookup only', (
      tester,
    ) async {
      await launch(tester);
      orders.pending = Completer<void>();
      await tester.tap(centerItem);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // Loading is shown on the screen and inside the bar's button.
      expect(find.text(l10n.currentOrderLoading), findsOneWidget);
      expect(spinner, findsOneWidget);
      expect(bar(tester).hasActiveOrder, isFalse);

      await tester.tap(centerItem);
      await tester.pump();
      await tester.tap(centerItem);
      await tester.pump();
      expect(orders.calls, 1);

      orders.pending!.complete();
      await tester.pumpAndSettle();
      expect(spinner, findsNothing);
      expect(find.text(l10n.currentOrderEmptyTitle), findsOneWidget);
    });

    testWidgets('lookup failure → error with Retry; retry can succeed', (
      tester,
    ) async {
      await launch(tester);
      orders.error = const OrderServiceUnavailableException();
      await openCurrentOrder(tester);
      expect(find.text(l10n.currentOrderLoadFailedTitle), findsOneWidget);
      expect(find.text(l10n.serviceUnavailableMessage), findsOneWidget);
      // A failure is neither "empty" nor "active".
      expect(find.text(l10n.currentOrderEmptyTitle), findsNothing);
      expect(bar(tester).hasActiveOrder, isFalse);

      orders
        ..error = null
        ..order = testActiveOrder;
      await tester.tap(find.widgetWithText(FilledButton, l10n.retry));
      await tester.pumpAndSettle();
      expect(orders.calls, 2);
      expect(find.byType(ActiveOrderPickupView), findsOneWidget);
    });

    testWidgets('offline lookup has its own message', (tester) async {
      await launch(tester);
      orders.error = const OrderNetworkUnavailableException();
      await openCurrentOrder(tester);
      expect(find.text(l10n.currentOrderNoInternet), findsOneWidget);
    });

    testWidgets('production default (no backend) → truthful not-configured', (
      tester,
    ) async {
      await tester.pumpWidget(
        MainApp(connectivityService: internet, authRepository: auth),
      );
      await tester.pumpAndSettle();
      await openCurrentOrder(tester);
      expect(find.text(l10n.currentOrderNotConfiguredTitle), findsOneWidget);
      expect(find.text(l10n.currentOrderNotConfiguredMessage), findsOneWidget);
      // Not shown as "no order", and not as a temporary outage.
      expect(find.text(l10n.currentOrderEmptyTitle), findsNothing);
      expect(find.text(l10n.currentOrderLoadFailedTitle), findsNothing);
      expect(find.text(l10n.serviceUnavailableMessage), findsNothing);
      expect(find.text(l10n.currentOrderNoInternet), findsNothing);
      // Nothing to retry: no Retry button in the body.
      expect(find.widgetWithText(FilledButton, l10n.retry), findsNothing);
      expect(find.byType(ActiveOrderPickupView), findsNothing);
      expect(bar(tester).hasActiveOrder, isFalse);
    });

    test('the three outcomes have three different Arabic messages', () {
      final titles = {
        l10n.currentOrderEmptyTitle,
        l10n.currentOrderNotConfiguredTitle,
        l10n.currentOrderLoadFailedTitle,
      };
      expect(titles.length, 3);
      final bodies = {
        l10n.currentOrderEmptyMessage,
        l10n.currentOrderNotConfiguredMessage,
        l10n.serviceUnavailableMessage,
        l10n.currentOrderNoInternet,
        l10n.unexpectedError,
      };
      expect(bodies.length, 5);
      // The not-configured text never asks the user to try again.
      for (final retryWord in ['إعادة المحاولة', 'أعد المحاولة', 'بعد قليل']) {
        expect(l10n.currentOrderNotConfiguredTitle, isNot(contains(retryWord)));
        expect(
          l10n.currentOrderNotConfiguredMessage,
          isNot(contains(retryWord)),
        );
      }
    });

    testWidgets('error state is centered in the body, not the screen', (
      tester,
    ) async {
      // iPhone 17 logical size and insets.
      setScreenSize(tester, 402, 874);
      tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
      addTearDown(tester.view.resetPadding);
      await launch(tester);
      orders.error = const OrderServiceUnavailableException();
      await openCurrentOrder(tester);

      final header = tester.getRect(
        find.descendant(
          of: find.byType(CurrentOrderScreen),
          matching: find.byType(AppBar),
        ),
      );
      final navBar = tester.getRect(find.byType(MainNavigationBar));
      final icon = tester.getRect(
        find.byIcon(PhosphorIconsRegular.warningCircle),
      );
      final button = tester.getRect(
        find.widgetWithText(FilledButton, l10n.retry),
      );
      final bodyCenter = (header.bottom + navBar.top) / 2;
      final groupCenter = (icon.top + button.bottom) / 2;
      expect(groupCenter, moreOrLessEquals(bodyCenter, epsilon: 0.5));
      expect(icon.top, greaterThan(header.bottom));
      expect(button.bottom, lessThan(navBar.top));
    });

    testWidgets('active order → map for that order at the restaurant pickup', (
      tester,
    ) async {
      await launch(tester);
      orders.order = testActiveOrder;
      await openCurrentOrder(tester);

      expect(find.byType(ActiveOrderPickupView), findsOneWidget);
      expect(find.text(l10n.pickupPointLabel), findsOneWidget);
      expect(find.text(testActiveOrder.restaurantName), findsOneWidget);
      expect(find.text(l10n.pickupInstructionsLabel), findsOneWidget);
      expect(find.text(testActiveOrder.pickupInstructions!), findsOneWidget);
      expect(find.text('fake-map'), findsOneWidget);
      // The shell stays around the map.
      expect(find.byType(MainNavigationBar), findsOneWidget);

      final shown = mapRequests.last;
      expect(shown.orderId, testActiveOrder.orderId);
      // Destination = the order's restaurant coordinates, exactly.
      expect(shown.pickup.latitude, testPickup.latitude);
      expect(shown.pickup.longitude, testPickup.longitude);
      expect(shown.restaurantName, testActiveOrder.restaurantName);
      // The captain's own position is a separate, optional input.
      expect(shown.captainLocation!.latitude, 31.97);
      expect(location.calls, 1);
    });

    testWidgets('selected branch and active order are independent in the bar', (
      tester,
    ) async {
      await launch(tester);
      orders.order = testActiveOrder;
      await openCurrentOrder(tester);
      final center = MainNavDestination.currentOrder.index;
      expect(bar(tester).selectedIndex, center);
      expect(bar(tester).hasActiveOrder, isTrue);

      // Leave the branch: no longer selected, still an active order.
      await tester.tap(
        find.byKey(MainNavigationBar.itemKey(MainNavDestination.home)),
      );
      await tester.pumpAndSettle();
      expect(bar(tester).selectedIndex, MainNavDestination.home.index);
      expect(bar(tester).hasActiveOrder, isTrue);

      // The order ends on the server; coming back revalidates.
      orders.order = null;
      await openCurrentOrder(tester);
      expect(orders.calls, 2);
      expect(bar(tester).selectedIndex, center);
      expect(bar(tester).hasActiveOrder, isFalse);
      expect(find.text(l10n.currentOrderEmptyTitle), findsOneWidget);
      expect(find.byType(ActiveOrderPickupView), findsNothing);
    });

    testWidgets('missing coordinates → active order shown, map unavailable', (
      tester,
    ) async {
      await launch(tester);
      orders.order = const ActiveOrder(
        orderId: 'order-7',
        restaurantName: 'مطعم بلا موقع',
        pickupInstructions: 'اتصل عند الوصول',
      );
      await openCurrentOrder(tester);

      // Still presented as the active order: the pickup view with its card.
      expect(find.byType(ActiveOrderPickupView), findsOneWidget);
      expect(find.text(l10n.pickupPointLabel), findsOneWidget);
      expect(find.text('مطعم بلا موقع'), findsOneWidget);
      expect(find.text('اتصل عند الوصول'), findsOneWidget);
      expect(bar(tester).hasActiveOrder, isTrue);
      // Not confused with "no order" or a lookup failure.
      expect(find.text(l10n.currentOrderEmptyTitle), findsNothing);
      expect(find.text(l10n.currentOrderLoadFailedTitle), findsNothing);

      // Only the map is unavailable, and it says why.
      expect(find.text(l10n.pickupLocationInvalidTitle), findsOneWidget);
      expect(
        find.text(l10n.pickupLocationInvalidMessage('مطعم بلا موقع')),
        findsOneWidget,
      );
      expect(find.text('fake-map'), findsNothing);
      // No map at any default or made-up location, and no location prompt.
      expect(mapRequests, isEmpty);
      expect(location.calls, 0);
      expect(find.text(l10n.locationLocating), findsNothing);

      // Once the server supplies coordinates, Retry brings the map.
      orders.order = testActiveOrder;
      final retry = find.widgetWithText(FilledButton, l10n.retry);
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(find.text('fake-map'), findsOneWidget);
      expect(mapRequests.last.pickup.latitude, testPickup.latitude);
    });

    testWidgets('malformed coordinates are treated the same way', (
      tester,
    ) async {
      await launch(tester);
      orders.order = const ActiveOrder(
        orderId: 'order-8',
        restaurantName: 'مطعم',
        pickupLocation: GeoPoint(latitude: 200, longitude: 35),
      );
      await openCurrentOrder(tester);
      expect(find.byType(ActiveOrderPickupView), findsOneWidget);
      expect(find.text(l10n.pickupLocationInvalidTitle), findsOneWidget);
      expect(mapRequests, isEmpty);
    });

    testWidgets('permission denied → explained, Retry asks once more', (
      tester,
    ) async {
      await launch(tester);
      orders.order = testActiveOrder;
      location.error = const LocationPermissionDeniedException();
      await openCurrentOrder(tester);

      expect(
        find.textContaining(l10n.locationPermissionDenied),
        findsOneWidget,
      );
      expect(
        find.textContaining(l10n.locationPermissionRationale),
        findsOneWidget,
      );
      // The restaurant is still shown; only the captain's dot is missing.
      expect(mapRequests.last.captainLocation, isNull);
      expect(mapRequests.last.pickup.latitude, testPickup.latitude);
      expect(location.calls, 1);

      location.error = null;
      await tester.tap(find.widgetWithText(TextButton, l10n.retry));
      await tester.pumpAndSettle();
      expect(location.calls, 2);
      expect(find.textContaining(l10n.locationPermissionDenied), findsNothing);
      expect(mapRequests.last.captainLocation, isNotNull);
    });

    testWidgets('device location unavailable → message with Retry', (
      tester,
    ) async {
      await launch(tester);
      orders.order = testActiveOrder;
      location.error = const LocationUnavailableException();
      await openCurrentOrder(tester);
      expect(find.text(l10n.locationUnavailable), findsOneWidget);
      expect(find.widgetWithText(TextButton, l10n.retry), findsOneWidget);
      expect(mapRequests.last.captainLocation, isNull);
    });

    testWidgets('no map configured → clear state instead of a blank area', (
      tester,
    ) async {
      await launch(tester, withMap: false);
      orders.order = testActiveOrder;
      location.error = const LocationNotConfiguredException();
      await openCurrentOrder(tester);
      // The pickup information is still there.
      expect(find.text(testActiveOrder.restaurantName), findsOneWidget);
      expect(find.text(l10n.mapUnavailableTitle), findsOneWidget);
      expect(find.text(l10n.mapUnavailableMessage), findsOneWidget);
      expect(find.text(l10n.locationNotConfigured), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('direct route entry starts exactly one lookup', (tester) async {
      await launch(tester);
      orders.order = testActiveOrder;
      GoRouter.of(
        tester.element(find.byType(AppNavBar)),
      ).go(RoutesString.currentOrder);
      await tester.pumpAndSettle();
      expect(orders.calls, 1);
      expect(mapRequests.last.orderId, testActiveOrder.orderId);
    });

    testWidgets('app-bar refresh revalidates the shown order', (tester) async {
      await launch(tester);
      orders.order = testActiveOrder;
      await openCurrentOrder(tester);
      orders.order = null;
      await tester.tap(find.byTooltip(l10n.refresh));
      await tester.pumpAndSettle();
      expect(find.text(l10n.currentOrderEmptyTitle), findsOneWidget);
    });

    testWidgets('sign-out during a lookup: late answer is ignored', (
      tester,
    ) async {
      await launch(tester);
      orders
        ..pending = Completer<void>()
        ..order = testActiveOrder;
      await tester.tap(centerItem);
      await tester.pump();
      final session = tester
          .element(find.byType(CurrentOrderScreen))
          .read<AppSessionCubit>();
      await session.endSession();
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);

      orders.pending!.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(location.calls, 0);
    });

    group('layout', () {
      testWidgets('empty state is centered between the header and the bar', (
        tester,
      ) async {
        setScreenSize(tester, 375, 800);
        tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
        addTearDown(tester.view.resetPadding);
        await launch(tester);
        await openCurrentOrder(tester);

        final header = tester.getRect(
          find.descendant(
            of: find.byType(CurrentOrderScreen),
            matching: find.byType(AppBar),
          ),
        );
        final navBar = tester.getRect(find.byType(MainNavigationBar));
        final title = tester.getRect(find.text(l10n.currentOrderEmptyTitle));
        final button = tester.getRect(
          find.widgetWithText(FilledButton, l10n.refresh),
        );
        // The header starts below the status-bar inset.
        expect(header.top, 0);
        expect(
          tester.getRect(find.text(l10n.currentOrderTitle).first).top,
          greaterThanOrEqualTo(47),
        );
        // The group sits fully inside the body…
        expect(title.top, greaterThan(header.bottom));
        expect(button.bottom, lessThan(navBar.top));
        // …and around the middle of the body, not of the physical screen.
        final bodyCenter = (header.bottom + navBar.top) / 2;
        final icon = tester.getRect(
          find.descendant(
            of: find.byType(CurrentOrderScreen),
            matching: find.byIcon(PhosphorIconsRegular.mapPin),
          ),
        );
        final groupCenter = (icon.top + button.bottom) / 2;
        expect(groupCenter, moreOrLessEquals(bodyCenter, epsilon: 1));
        expect((groupCenter - 400).abs(), greaterThan(1));
        // Shared horizontal inset.
        expect(title.left, greaterThanOrEqualTo(20));
        expect(title.right, lessThanOrEqualTo(375 - 20));
      });

      for (final size in const [
        Size(320, 568),
        Size(375, 800),
        Size(600, 900),
        Size(1024, 768),
        Size(740, 360),
      ]) {
        testWidgets('pickup view fits ${size.width}×${size.height}', (
          tester,
        ) async {
          setScreenSize(tester, size.width, size.height);
          await launch(tester);
          orders.order = testActiveOrder;
          await openCurrentOrder(tester);
          expect(tester.takeException(), isNull);
          final map = find.byKey(ActiveOrderPickupView.mapAreaKey);
          await tester.ensureVisible(map);
          expect(tester.getSize(map).height, greaterThanOrEqualTo(240));
          expect(tester.takeException(), isNull);
        });
      }
    });
  });
}
