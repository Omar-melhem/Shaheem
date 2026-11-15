// Home tab re-entry freshness (Task 28), through the real app: MainApp, the
// real GoRouter `StatefulShellRoute.indexedStack` and `AppNavBar`, with
// counting fakes. Counts how often Home's two read models are loaded for
// each navigation/lifecycle event, and how much of a long offers list is
// built.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_frontend/domain/entities/app_user.dart';
import 'package:mobile_frontend/domain/entities/order_offer.dart';
import 'package:mobile_frontend/domain/repositories/order_offer_repository.dart';
import 'package:mobile_frontend/main.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';
import 'package:mobile_frontend/view/screens/home_screen/cubit/pending_offers_cubit.dart';
import 'package:mobile_frontend/view/screens/home_screen/view/home_screen.dart';
import 'package:mobile_frontend/view/screens/home_screen/widget/home_lifecycle_bridge.dart';
import 'package:mobile_frontend/view/screens/notifications_screen/view/notifications_screen.dart';
import 'package:mobile_frontend/view/widget/navigation/main_nav_destination.dart';
import 'package:mobile_frontend/view/widget/navigation/main_navigation_bar.dart';
import 'package:mobile_frontend/view/widget/order/app_order_offer_card.dart';

import 'availability_fakes.dart';
import 'fakes.dart';
import 'test_app.dart';

/// Offers source that counts loads and can hold an answer back.
class CountingOfferRepository implements OrderOfferRepository {
  CountingOfferRepository(this.offers);

  /// What the server currently returns.
  List<CaptainOrderOffer> offers;

  /// When set, [getEligibleOffers] waits on it.
  Completer<List<CaptainOrderOffer>>? pending;

  /// When set, [declineOffer] waits on it.
  Completer<void>? declinePending;

  int loadCalls = 0;

  @override
  Future<List<CaptainOrderOffer>> getEligibleOffers() async {
    loadCalls++;
    if (pending != null) return pending!.future;
    return [...offers];
  }

  @override
  Future<void> acceptOffer(String offerId) async {}

  @override
  Future<void> declineOffer(String offerId) async {
    if (declinePending != null) await declinePending!.future;
  }
}

/// Test data only: production code never contains an offer.
CaptainOrderOffer offer(String id) => CaptainOrderOffer(
  id: id,
  merchantName: 'مطعم $id',
  deliveryAreaName: 'منطقة $id',
  deliveryFeeFils: 2500,
);

void main() {
  late FakeAvailabilityRepository availabilityRepo;
  late FakePermissionGateway permissions;
  late CountingOfferRepository offersRepo;
  late FakeAuthRepository auth;

  setUp(() {
    availabilityRepo = FakeAvailabilityRepository();
    permissions = FakePermissionGateway(prerequisites());
    offersRepo = CountingOfferRepository([offer('a1'), offer('a2')]);
    auth = FakeAuthRepository(hasSession: true);
  });

  Future<void> launch(WidgetTester tester) async {
    await tester.pumpWidget(
      MainApp(
        connectivityService: FakeInternetConnectionService(),
        authRepository: auth,
        captainAvailabilityRepository: availabilityRepo,
        availabilityPermissions: permissions,
        orderOfferRepository: offersRepo,
      ),
    );
    await tester.pumpAndSettle();
  }

  /// (availability loads, offers loads) so far.
  (int, int) loads() => (availabilityRepo.getCalls, offersRepo.loadCalls);

  Future<void> tapTab(WidgetTester tester, MainNavDestination d) async {
    await tester.tap(find.byKey(MainNavigationBar.itemKey(d)));
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

  /// The Home element's lifecycle bridge state (one per Home mount).
  State bridgeState(WidgetTester tester) =>
      tester.state(find.byType(HomeLifecycleBridge, skipOffstage: false));

  AppSessionCubit sessionOf(WidgetTester tester) =>
      tester.element(find.byType(MaterialApp)).read<AppSessionCubit>();

  testWidgets('first opening Home loads each feature exactly once', (
    tester,
  ) async {
    await launch(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(loads(), (1, 1));
  });

  for (final away in [
    MainNavDestination.notifications,
    MainNavDestination.currentOrder,
    MainNavDestination.orderHistory,
    MainNavDestination.profile,
  ]) {
    testWidgets('Home → ${away.name} → Home (app stays in foreground) '
        're-reads both features once', (tester) async {
      await launch(tester);
      final bridge = bridgeState(tester);

      await tapTab(tester, away);
      // Leaving Home loads nothing.
      expect(loads(), (1, 1));

      // The server changed while Home was hidden.
      offersRepo.offers = [offer('a2')];
      await tapTab(tester, MainNavDestination.home);
      expect(loads(), (2, 2));
      // Home was retained, not mounted again: same bridge, so still one
      // lifecycle listener.
      expect(identical(bridgeState(tester), bridge), isTrue);
      // Only what the server now returns is shown.
      expect(find.byKey(const ValueKey('a1')), findsNothing);
      expect(find.byKey(const ValueKey('a2')), findsOneWidget);
      expect(permissions.requestCalls, 0);
    });
  }

  testWidgets('re-selecting the Home tab while on Home loads nothing', (
    tester,
  ) async {
    await launch(tester);
    await tapTab(tester, MainNavDestination.home);
    await tapTab(tester, MainNavDestination.home);
    expect(loads(), (1, 1));
  });

  testWidgets('rebuilds without a tab change load nothing (text scale, '
      'screen size, display name, Cubit state)', (tester) async {
    await launch(tester);

    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    setScreenSize(tester, 320, 640);
    await tester.pumpAndSettle();

    final session = sessionOf(tester);
    session.authenticate(
      const AppUser(id: 'c1', displayName: 'سارة'),
      session.beginAttempt(),
    );
    await tester.pumpAndSettle();

    // A Cubit state change (a command) re-renders Home only.
    final home = tester.element(find.byType(HomeScreen));
    await home.read<PendingOffersCubit>().decline('a1');
    await tester.pumpAndSettle();
    // The decline re-reads the list once (existing command behavior).
    expect(loads(), (1, 2));
  });

  testWidgets('resume with Home visible: one refresh per feature, no '
      'permission prompt', (tester) async {
    await launch(tester);
    resume(tester);
    await tester.pumpAndSettle();
    expect(loads(), (2, 2));
    expect(permissions.requestCalls, 0);
  });

  testWidgets('resume during an in-flight load sends no second request', (
    tester,
  ) async {
    await launch(tester);
    offersRepo.pending = Completer();
    resume(tester);
    await tester.pump();
    resume(tester);
    await tester.pump();
    expect(offersRepo.loadCalls, 2);
    offersRepo.pending!.complete([offer('a1')]);
    await tester.pumpAndSettle();
    expect(offersRepo.loadCalls, 2);
  });

  testWidgets('resume while another tab is visible loads nothing; coming '
      'back to Home then re-reads once (Task 29)', (tester) async {
    await launch(tester);
    await tapTab(tester, MainNavDestination.notifications);
    resume(tester);
    await tester.pumpAndSettle();
    // Home is hidden: no background work.
    expect(loads(), (1, 1));
    expect(find.byType(NotificationsScreen), findsOneWidget);

    await tapTab(tester, MainNavDestination.home);
    expect(loads(), (2, 2));
    expect(permissions.requestCalls, 0);
  });

  testWidgets('resume while a full page covers Home loads nothing; closing '
      'the page re-reads once (Task 29)', (tester) async {
    await launch(tester);
    unawaited(
      Navigator.of(tester.element(find.byType(HomeScreen))).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('nested-page')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    resume(tester);
    await tester.pumpAndSettle();
    expect(loads(), (1, 1));

    Navigator.of(tester.element(find.text('nested-page'))).pop();
    await tester.pumpAndSettle();
    expect(loads(), (2, 2));
    expect(permissions.requestCalls, 0);
  });

  testWidgets('resume then an immediate switch to Home (signals close '
      'together) sends one request per feature', (tester) async {
    await launch(tester);
    await tapTab(tester, MainNavDestination.notifications);
    // Keep the answer in flight so both signals overlap.
    offersRepo.pending = Completer();
    availabilityRepo.getPending = Completer();
    resume(tester);
    await tester.tap(
      find.byKey(MainNavigationBar.itemKey(MainNavDestination.home)),
    );
    await tester.pump();
    resume(tester);
    await tester.pump();
    expect(loads(), (2, 2));
    offersRepo.pending!.complete([offer('a1')]);
    availabilityRepo.getPending!.complete(availabilityRepo.status);
    offersRepo.pending = null;
    availabilityRepo.getPending = null;
    await tester.pumpAndSettle();
    expect(loads(), (2, 2));
  });

  testWidgets('sign-out then a new session: no previous captain data, the '
      'late answer is dropped', (tester) async {
    await launch(tester);
    expect(find.byKey(const ValueKey('a1')), findsOneWidget);

    // A refresh for captain A is still in flight when A signs out.
    offersRepo.pending = Completer();
    resume(tester);
    await tester.pump();
    final session = sessionOf(tester);
    await session.endSession();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsNothing);
    offersRepo.pending!.complete([offer('a1'), offer('stale')]);
    offersRepo.pending = null;
    await tester.pumpAndSettle();

    // Captain B signs in; the server has B's offers only.
    offersRepo.offers = [offer('b1')];
    session.authenticate(
      const AppUser(id: 'c2', displayName: 'سارة'),
      session.beginAttempt(),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('b1')), findsOneWidget);
    expect(find.byKey(const ValueKey('a1')), findsNothing);
    expect(find.byKey(const ValueKey('stale')), findsNothing);
  });

  testWidgets('a full page covering Home (none exist yet) also counts as '
      'Home becoming visible again: one re-read on return; a dialog none', (
    tester,
  ) async {
    await launch(tester);
    final home = tester.element(find.byType(HomeScreen));

    // A dialog keeps Home visible underneath: no re-read.
    unawaited(
      showDialog<void>(context: home, builder: (_) => const Text('dialog')),
    );
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('dialog'))).pop();
    await tester.pumpAndSettle();
    expect(loads(), (1, 1));

    // An opaque page on Home's own Navigator hides it.
    unawaited(
      Navigator.of(home).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('nested-page')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(loads(), (1, 1));
    Navigator.of(tester.element(find.text('nested-page'))).pop();
    await tester.pumpAndSettle();
    expect(loads(), (2, 2));
  });

  testWidgets('debug preview (no session): tab away and back stays truthful '
      'and asks no backend', (tester) async {
    auth = FakeAuthRepository();
    await launch(tester);
    final button = find.text(l10n.debugPreviewButton);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    await tapTab(tester, MainNavDestination.notifications);
    await tapTab(tester, MainNavDestination.home);
    // The Cubits refuse without a session before calling any backend.
    expect(loads(), (0, 0));
    expect(permissions.requestCalls, 0);
    expect(find.byType(AppOrderOfferCard), findsNothing);
    await tester.ensureVisible(find.text(l10n.offersNoSession));
    expect(find.text(l10n.offersNoSession), findsOneWidget);
  });

  group('long lists stay lazy', () {
    for (final count in [100, 500]) {
      testWidgets('$count offers: only the visible part is built, keys are '
          'stable, and one card changing builds no more', (tester) async {
        // Every card element that exists, including the scroll cache area.
        int builtCards() => tester
            .widgetList(find.byType(AppOrderOfferCard, skipOffstage: false))
            .length;
        setScreenSize(tester, 375, 800);
        offersRepo.offers = [for (var i = 1; i <= count; i++) offer('o$i')];
        await launch(tester);
        expect(builtCards(), lessThan(10));
        expect(find.byKey(const ValueKey('o1')), findsOneWidget);
        expect(
          find.byKey(ValueKey('o$count'), skipOffstage: false),
          findsNothing,
        );

        // One card changes state (a decline in flight): still lazy.
        offersRepo.declinePending = Completer();
        final cubit = tester
            .element(find.byType(HomeScreen))
            .read<PendingOffersCubit>();
        unawaited(cubit.decline('o1'));
        await tester.pump();
        expect(builtCards(), lessThan(10));
        offersRepo.declinePending!.complete();
        await tester.pumpAndSettle();
        expect(builtCards(), lessThan(10));

        // Tab away and back re-reads once and stays lazy.
        await tapTab(tester, MainNavDestination.notifications);
        await tapTab(tester, MainNavDestination.home);
        expect(builtCards(), lessThan(10));
      });
    }
  });
}
