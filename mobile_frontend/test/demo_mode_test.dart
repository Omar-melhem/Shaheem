// SHAHM DEMO (Task 37) — debug-only demonstration mode: fixtures, the
// in-memory demo server, the demo login and the real app driven with
// fictional data; Task 38: the Home wallet balance and the history
// refresh; client revision (2026-11-20): one balance ≤ 5,000 fils without
// holds, lifetime statistics, no notification feed, four tabs and the
// standalone Current Order page.
// Removed with the demo (`tool/demo/remove_demo.sh`).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_frontend/demo/demo_app.dart';
import 'package:mobile_frontend/demo/demo_mode.dart';
import 'package:mobile_frontend/demo/demo_state.dart';
import 'package:mobile_frontend/demo/model/demo_fixtures.dart';
import 'package:mobile_frontend/demo/repo/demo_auth_repository.dart';
import 'package:mobile_frontend/demo/repo/demo_repositories.dart';
import 'package:mobile_frontend/demo/widget/demo_strip.dart';
import 'package:mobile_frontend/domain/entities/order_offer.dart';
import 'package:mobile_frontend/domain/errors/auth_exceptions.dart';
import 'package:mobile_frontend/domain/errors/order_offer_exceptions.dart';
import 'package:mobile_frontend/domain/use_cases/get_wallet.dart';
import 'package:mobile_frontend/main.dart';
import 'package:mobile_frontend/util/fonts.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';
import 'package:mobile_frontend/view/navigation/app_nav_bar.dart';
import 'package:mobile_frontend/view/navigation/new_order_offer_sheet.dart';
import 'package:mobile_frontend/view/screens/authentication/view/login_screen.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/cubit/current_order_cubit.dart';
import 'package:mobile_frontend/view/screens/home_screen/view/home_screen.dart';
import 'package:mobile_frontend/view/screens/home_screen/widget/wallet_balance_chip.dart';
import 'package:mobile_frontend/view/screens/order_history_screen/widget/declined_offer_tile.dart';
import 'package:mobile_frontend/view/screens/wallet_screen/cubit/wallet_cubit.dart';
import 'package:mobile_frontend/view/screens/wallet_screen/view/wallet_screen.dart';
import 'package:mobile_frontend/view/screens/wallet_screen/widget/wallet_balance_card.dart';
import 'package:mobile_frontend/view/screens/wallet_screen/widget/wallet_debit_card.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/view/current_order_screen.dart';
import 'package:mobile_frontend/view/widget/buttons/app_button.dart';
import 'package:mobile_frontend/view/widget/navigation/main_nav_destination.dart';
import 'package:mobile_frontend/view/widget/navigation/main_navigation_bar.dart';

import 'package:mobile_frontend/view/screens/current_order_screen/widget/active_order_pickup_view.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/widget/active_order_delivery_view.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/widget/customer_contact_card.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/widget/pickup_verification_form.dart';
import 'package:mobile_frontend/view/screens/order_history_screen/widget/completed_delivery_tile.dart';

import 'fakes.dart';
import 'test_app.dart';

/// A fixed demo clock.
final demoNow = DateTime(2026, 11, 15, 12);

/// The fixture texts, read once through the real asset bundle.
late Map<String, String> fixtureTexts;

/// An in-memory bundle with the same texts, for widget tests (no async I/O
/// inside the fake-async zone).
class _MemoryBundle extends CachingAssetBundle {
  _MemoryBundle(this.texts);

  final Map<String, String> texts;

  @override
  Future<ByteData> load(String key) async {
    final name = key.split('/').last.replaceAll('.json', '');
    final text = texts[name];
    if (text == null) throw FlutterError('missing $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(text)));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final name = key.split('/').last.replaceAll('.json', '');
    return texts[name] ?? (throw FlutterError('missing $key'));
  }
}

/// Records any HTTP attempt (none may happen in the demo).
class _NoHttp extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('the demo must not make HTTP requests');
  }
}

DemoState newState({DateTime Function()? clock}) =>
    DemoState(DemoFixtures.parse(fixtureTexts), clock: clock ?? () => demoNow);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    fixtureTexts = {
      for (final name in demoFixtureFiles)
        name: await rootBundle.loadString('$demoFixturesDir/$name.json'),
    };
    final loader = FontLoader(AppFonts.ibmPlexSansArabic);
    for (final weight in ['Light', 'Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(
        rootBundle.load(
          'assets/fonts/ibm_plex_sans_arabic/IBMPlexSansArabic-$weight.ttf',
        ),
      );
    }
    await loader.load();
  });

  group('activation', () {
    test('needs both the define and a debug build', () {
      expect(resolveShahmDemo(requested: true, debugBuild: true), isTrue);
      expect(resolveShahmDemo(requested: true, debugBuild: false), isFalse);
      expect(resolveShahmDemo(requested: false, debugBuild: true), isFalse);
      expect(resolveShahmDemo(requested: false, debugBuild: false), isFalse);
      // Tests run without the define: the demo is off.
      expect(shahmDemoRequested, isFalse);
      expect(shahmDemoEnabled, isFalse);
    });

    testWidgets('the normal app has no demo strip, captain or data', (
      tester,
    ) async {
      await tester.pumpWidget(
        MainApp(
          connectivityService: FakeInternetConnectionService(),
          authRepository: FakeAuthRepository(hasSession: false),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(DemoStrip), findsNothing);
      expect(find.text(l10n.demoBadge), findsNothing);
      expect(find.text(l10n.demoShowNewOffer), findsNothing);
    });

    testWidgets('the normal app\'s Home keeps «—» with the production '
        'wallet placeholder (no demo amount)', (tester) async {
      await tester.pumpWidget(
        MainApp(
          connectivityService: FakeInternetConnectionService(),
          authRepository: FakeAuthRepository(hasSession: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        tester
            .widget<WalletBalanceChip>(find.byType(WalletBalanceChip))
            .balanceFils,
        isNull,
      );
      expect(
        find.descendant(
          of: find.byType(WalletBalanceChip),
          matching: find.text(l10n.walletBalanceUnknownValue),
        ),
        findsOneWidget,
      );
      expect(find.byType(DemoStrip), findsNothing);
    });
  });

  group('fixtures', () {
    test('all seven files load through the asset bundle and agree', () {
      final f = DemoFixtures.parse(fixtureTexts);
      expect(f.username, 'demo_captain');
      expect(f.accessToken, 'DEMO_ONLY_NOT_A_JWT_DO_NOT_SEND');
      expect(f.captainName, 'أحمد الشهم');
      expect(f.pendingOfferIds, ['demo-offer-101', 'demo-offer-102']);
      expect(f.offers, hasLength(3));
      for (final o in [...f.offers, f.incomingTemplate]) {
        expect(o.deliveryFeeFils - o.commissionFils, greaterThanOrEqualTo(0));
      }
      // D-A74/D-A75: one balance, within the 5,000-fils ceiling.
      expect(f.walletBalanceFils, 4000);
      expect(f.walletBalanceFils, lessThanOrEqualTo(5000));
      expect(demoFixtureFiles, isNot(contains('notifications')));
      expect(f.declined, hasLength(1));
      // Includes a delivery older than the 7-day debit window.
      expect(f.completedCount, 3);
      expect(f.futureCount, 1);
    });

    Map<String, String> withFile(String name, String Function(String) edit) => {
      ...fixtureTexts,
      name: edit(fixtureTexts[name]!),
    };

    for (final (what, files) in [
      ('malformed JSON', () => withFile('offers', (s) => s.substring(5))),
      ('a missing file', () => {...fixtureTexts}..remove('wallet')),
      (
        'a wrong schema',
        () => withFile('home', (s) => s.replaceFirst('shahm-demo-v1', 'v0')),
      ),
      (
        'net != fee − commission',
        () => withFile(
          'offers',
          (s) => s.replaceFirst(
            '"captain_net_fils": 2000',
            '"captain_net_fils": 1999',
          ),
        ),
      ),
      (
        'a missing required field',
        () => withFile(
          'auth',
          (s) => s.replaceFirst('"demo_username"', '"user"'),
        ),
      ),
      (
        'a JWT-shaped token',
        () => withFile(
          'auth',
          (s) => s.replaceFirst('DEMO_ONLY_NOT_A_JWT_DO_NOT_SEND', 'a.b.c'),
        ),
      ),
      (
        'Home and Wallet disagreeing',
        () => withFile(
          'home',
          (s) => s.replaceFirst(
            '"wallet_balance_fils": 4000',
            '"wallet_balance_fils": 4001',
          ),
        ),
      ),
      (
        'a balance above the 5,000-fils ceiling',
        () => {
          ...withFile(
            'wallet',
            (s) =>
                s.replaceFirst('"balance_fils": 4000', '"balance_fils": 5001'),
          ),
          'home': fixtureTexts['home']!.replaceFirst(
            '"wallet_balance_fils": 4000',
            '"wallet_balance_fils": 5001',
          ),
        },
      ),
      (
        'a retired hold field',
        () => withFile(
          'wallet',
          (s) => s.replaceFirst(
            '"balance_fils": 4000,',
            '"balance_fils": 4000, "held_commissions_fils": 0,',
          ),
        ),
      ),
    ]) {
      test('rejects $what', () {
        expect(
          () => DemoFixtures.parse(files()),
          throwsA(isA<DemoFixtureException>()),
        );
      });
    }
  });

  group('demo server', () {
    test('relative times use the clock; the real GetWallet keeps the last '
        '7 × 24 h only, boundary included', () async {
      final state = newState();
      final overview = await GetWallet(
        DemoWalletRepository(state),
        now: () => demoNow,
      )();
      final wallet = (overview as WalletLoaded).overview;
      expect(wallet.debits.map((d) => d.id), ['demo-debit-1', 'demo-debit-2']);
      expect(
        state.wallet.debits.first.debitedAt,
        demoNow.subtract(const Duration(minutes: 600)).toUtc(),
      );
      // Lifetime statistics are not limited by the 7-day window.
      expect(state.deliveryStatistics.deliveredCount, 3);
      expect(state.deliveryStatistics.earningsFils, isNull);
    });

    test('accept: eligible instant only, once, one active order; no hold, '
        'no debit (the wallet is untouched)', () {
      final state = newState()..signIn('demo_captain', 'Demo1234!');
      final walletBefore = state.wallet;
      state.accept('demo-offer-101');
      expect(state.activeOrder!.orderId, 'demo-order-101');
      expect(state.eligibleOffers().map((o) => o.id), ['demo-offer-102']);
      expect(state.wallet, same(walletBefore));
      // Again: nothing to accept. Another one: one active order only.
      expect(
        () => state.accept('demo-offer-101'),
        throwsA(isA<OrderOfferNoLongerAvailableException>()),
      );
      expect(
        () => state.accept('demo-offer-102'),
        throwsA(isA<OrderOfferRefusedException>()),
      );
    });

    test('expired offers leave the list and cannot be answered', () {
      var now = demoNow;
      final state = newState(clock: () => now)
        ..signIn('demo_captain', 'Demo1234!');
      now = now.add(const Duration(seconds: 121));
      expect(state.eligibleOffers(), isEmpty);
      expect(
        () => state.decline('demo-offer-101'),
        throwsA(isA<OrderOfferNoLongerAvailableException>()),
      );
    });

    test('scheduled sample is visual only; decline records history only', () {
      final state = newState()..signIn('demo_captain', 'Demo1234!');
      expect(state.showScheduledSample(), 'demo-offer-201');
      expect(state.showScheduledSample(), isNull);
      final scheduled = state.eligibleOffers().last;
      expect(scheduled.kind, OrderOfferKind.scheduled);
      expect(scheduled.scheduledPickupAt, demoNow.add(const Duration(days: 1)));
      expect(scheduled.hasEarningsDisclosure, isTrue);
      expect(
        () => state.accept('demo-offer-201'),
        throwsA(isA<OrderOfferRefusedException>()),
      );
      state.decline('demo-offer-102');
      expect(state.declinedOffers.last.offerId, 'demo-offer-102');
      expect(state.activeOrder, isNull);
    });

    test('new offers: unique ids, at most three waiting; reset and sign-out '
        'restore the fixtures', () {
      final state = newState()..signIn('demo_captain', 'Demo1234!');
      expect(state.injectOffer(), 'demo-new-offer-1');
      expect(state.injectOffer(), 'demo-new-offer-2');
      expect(state.injectOffer(), 'demo-new-offer-3');
      expect(state.canInjectOffer, isFalse);
      expect(state.injectOffer(), isNull);
      final injected = state.eligibleOffers().last;
      expect(injected.commission!.amountFils, 600);
      expect(injected.netEarningsFils, 2400);
      state.reset();
      expect(state.eligibleOffers(), hasLength(2));
      expect(state.injectOffer(), 'demo-new-offer-1');
      state.signOut();
      expect(state.session, isNull);
      expect(state.injectOffer(), isNull);
    });

    test('one balance (no holds); reset counts every return to the '
        'fixtures, a decline does not', () {
      final state = newState();
      expect(state.wallet.summary.balanceFils, 4000);
      final resets = state.resetCount;
      state.signIn('demo_captain', 'Demo1234!');
      expect(state.resetCount, resets + 1);
      final walletBefore = state.wallet;
      state.decline('demo-offer-101');
      expect(state.resetCount, resets + 1);
      expect(state.wallet, same(walletBefore));
      state.reset();
      expect(state.resetCount, resets + 2);
      expect(state.declinedOffers, hasLength(1));
      state.signOut();
      expect(state.resetCount, resets + 3);
    });

    test('demo auth: only the fixture credentials; the token stays in demo '
        'memory and is not part of the user', () async {
      final state = newState();
      final auth = DemoAuthRepository(state);
      expect(await auth.hasStoredSession(), isFalse);
      await expectLater(
        auth.signIn(username: 'wrong_demo', password: 'Demo1234!'),
        throwsA(isA<InvalidCredentialsException>()),
      );
      await auth.signIn(username: 'demo_captain', password: 'Demo1234!');
      final user = await auth.getCurrentUser();
      expect(user.id, 'demo-captain-001');
      expect(user.role, 'captain');
      expect(user.phone, isNull);
      await auth.clearSession();
      expect(await auth.hasStoredSession(), isFalse);
      await expectLater(
        auth.getCurrentUser(),
        throwsA(isA<SessionInvalidException>()),
      );
    });
  });

  group('the real app with demo data', () {
    late _NoHttp http;

    Future<void> launch(WidgetTester tester) async {
      // The real Wallet use case filters with the device clock, so the demo
      // clock is "now" (fixed per test) rather than [demoNow]; otherwise
      // the 7-day window depends on the date the suite runs.
      final appNow = DateTime.now();
      http = _NoHttp();
      HttpOverrides.global = http;
      addTearDown(() => HttpOverrides.global = null);
      await tester.pumpWidget(
        DemoApp(
          connectivityService: FakeInternetConnectionService(),
          bundle: _MemoryBundle(fixtureTexts),
          clock: () => appNow,
        ),
      );
      await tester.pumpAndSettle();
    }

    Finder field(String label) => find.widgetWithText(TextFormField, label);

    Future<void> signIn(
      WidgetTester tester, {
      String user = 'demo_captain',
      String password = 'Demo1234!',
    }) async {
      await tester.enterText(field(l10n.usernameLabel), user);
      await tester.enterText(field(l10n.passwordLabel), password);
      await tester.tap(find.widgetWithText(FilledButton, l10n.loginButton));
      await tester.pumpAndSettle();
    }

    final navBar = find.byType(AppNavBar, skipOffstage: false);

    int branch(WidgetTester tester) =>
        tester.widget<AppNavBar>(navBar).navigationShell.currentIndex;

    Future<void> tapTab(WidgetTester tester, MainNavDestination d) async {
      await tester.tap(find.byKey(MainNavigationBar.itemKey(d)));
      await tester.pumpAndSettle();
    }

    final sheet = find.byType(NewOrderOfferSheet);

    testWidgets('Login shows the badge; wrong credentials are refused; the '
        'fixture captain reaches the real Home with the real offers', (
      tester,
    ) async {
      await launch(tester);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text(l10n.demoBadge), findsOneWidget);
      expect(find.text(l10n.demoShowNewOffer), findsNothing);
      await signIn(tester, user: 'wrong_demo');
      expect(find.text(l10n.loginInvalidCredentials), findsOneWidget);
      await signIn(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text(l10n.homeGreeting('أحمد الشهم')), findsOneWidget);
      expect(find.text('مطعم السنابل'), findsOneWidget);
      expect(find.text(l10n.demoBadge), findsOneWidget);
      expect(http.attempts, 0);
    });

    testWidgets('«إظهار طلب جديد» on Wallet opens the real sheet; accept → '
        'the real Current Order page for that order (no fifth tab)', (
      tester,
    ) async {
      await launch(tester);
      await signIn(tester);
      await tapTab(tester, MainNavDestination.wallet);
      await tester.tap(find.text(l10n.demoShowNewOffer));
      await tester.pumpAndSettle();
      expect(sheet, findsOneWidget);
      expect(
        find.descendant(of: sheet, matching: find.text('مطعم زيت وزعتر')),
        findsOneWidget,
      );
      expect(find.text(l10n.demoBadge), findsOneWidget);
      await tester.tap(find.text(l10n.offerAcceptFull));
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      expect(find.byType(CurrentOrderScreen), findsOneWidget);
      expect(branch(tester), MainNavDestination.wallet.index);
      final current = tester.element(navBar).read<CurrentOrderCubit>().state;
      expect((current as CurrentOrderActive).order.orderId, 'demo-new-order-1');
      expect(http.attempts, 0);
    });

    // D-A81 through the demo "server": every step is simulated in memory.
    testWidgets('accept → wrong PIN → demo PIN → delivery view with the '
        'optional phone → Start Delivery → completion → My Orders lists it '
        'and Wallet shows one more commission debit', (tester) async {
      setScreenSize(tester, 420, 2600);
      await launch(tester);
      await signIn(tester);
      CurrentOrderCubit cubitOf() =>
          tester.element(navBar).read<CurrentOrderCubit>();
      await tester.tap(find.text(l10n.demoShowNewOffer));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.offerAcceptFull));
      await tester.pumpAndSettle();
      expect(find.byType(ActiveOrderPickupView), findsOneWidget);

      Future<void> enterPin(String pin) async {
        await tester.tap(find.text(l10n.pickupConfirmAction));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.descendant(
            of: find.byType(PickupVerificationForm),
            matching: find.byType(EditableText),
          ),
          pin,
        );
        await tester.tap(
          find.widgetWithText(AppButton, l10n.pickupVerificationSubmit),
        );
        await tester.pumpAndSettle();
      }

      await enterPin('9999');
      expect(find.text(l10n.pickupPinIncorrectRemaining(2)), findsOneWidget);
      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();
      await enterPin('1234');
      expect(find.byType(ActiveOrderDeliveryView), findsOneWidget);
      expect(find.byType(CustomerContactCard), findsOneWidget);
      await tester.tap(find.text(l10n.startDeliveryAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.completeDeliveryAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.completeDeliveryConfirmAction));
      await tester.pumpAndSettle();

      expect(cubitOf().state, isA<CurrentOrderDelivered>());
      expect(branch(tester), MainNavDestination.orderHistory.index);
      expect(
        tester
            .widgetList<CompletedDeliveryTile>(
              find.byType(CompletedDeliveryTile),
            )
            .first
            .delivery
            .orderId,
        'demo-new-order-1',
      );
      await tapTab(tester, MainNavDestination.wallet);
      final wallet = tester.element(navBar).read<WalletCubit>().state;
      expect(wallet.overview!.debits.first.orderId, 'demo-new-order-1');
      // 4,000 − the template's 600-fils commission, read back from the demo
      // server (never computed by the app).
      expect(wallet.balanceFils, 3400);
      expect(http.attempts, 0);
    });

    List<String> historyMerchants(WidgetTester tester) => [
      for (final t in tester.widgetList<DeclinedOfferTile>(
        find.byType(DeclinedOfferTile),
      ))
        t.record.merchantName ?? '',
    ];

    testWidgets('decline while Order History stays open: the new record '
        'appears first at once, no navigation; «لاحقاً» adds nothing; reset '
        'restores the fixture history in place; the wallet is unchanged', (
      tester,
    ) async {
      // Tall viewport: My Orders now lists the completed deliveries above
      // the declined offers (D-A81), and both sections are built lazily.
      setScreenSize(tester, 420, 2600);
      await launch(tester);
      await signIn(tester);
      await tapTab(tester, MainNavDestination.orderHistory);
      expect(historyMerchants(tester), ['مقهى اللوز']);
      final walletTotal = tester
          .widget<WalletBalanceChip>(
            find.byType(WalletBalanceChip, skipOffstage: false),
          )
          .balanceFils;

      await tester.tap(find.text(l10n.demoShowNewOffer));
      await tester.pumpAndSettle();
      expect(sheet, findsOneWidget);
      // The full fee is the only amount (3.000 for the template offer).
      expect(
        find.descendant(
          of: sheet,
          matching: find.text(l10n.offerGrossFeeLabel),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheet, matching: find.textContaining('%')),
        findsNothing,
      );
      await tester.tap(find.text(l10n.offerDeclineFull));
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      expect(branch(tester), MainNavDestination.orderHistory.index);
      // Observed before any tab re-entry: exactly one new row, newest first.
      expect(historyMerchants(tester), ['مطعم زيت وزعتر', 'مقهى اللوز']);

      // Closed without an answer: the count does not change.
      await tester.tap(find.text(l10n.demoShowNewOffer));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.offerLater));
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      expect(find.byType(DeclinedOfferTile), findsNWidgets(2));

      expect(
        tester
            .widget<WalletBalanceChip>(
              find.byType(WalletBalanceChip, skipOffstage: false),
            )
            .balanceFils,
        walletTotal,
      );

      // Reset while the tab is visible: the fixture history returns.
      await tester.tap(find.text(l10n.demoTools));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.demoReset));
      await tester.pumpAndSettle();
      expect(branch(tester), MainNavDestination.orderHistory.index);
      expect(historyMerchants(tester), ['مقهى اللوز']);
      expect(http.attempts, 0);
    });

    testWidgets('a decline from the Home card shows when My Orders is '
        'opened; the wallet shows the last 7 days of debits only and the '
        'lifetime count', (tester) async {
      // Tall viewport: My Orders now lists the completed deliveries above
      // the declined offers (D-A81), and both sections are built lazily.
      setScreenSize(tester, 420, 2600);
      await launch(tester);
      await signIn(tester);
      final decline = find.widgetWithText(AppButton, l10n.offerDecline).first;
      await tester.ensureVisible(decline);
      await tester.pumpAndSettle();
      await tester.tap(decline);
      await tester.pumpAndSettle();
      expect(branch(tester), MainNavDestination.home.index);
      await tapTab(tester, MainNavDestination.orderHistory);
      expect(find.byType(DeclinedOfferTile), findsNWidgets(2));
      expect(historyMerchants(tester).last, 'مقهى اللوز');

      await tapTab(tester, MainNavDestination.wallet);
      expect(find.byType(WalletDebitCard), findsWidgets);
      // The list is lazy; the real Cubit holds what the screen lists.
      final walletState = tester
          .element(find.byType(WalletScreen))
          .read<WalletCubit>()
          .state;
      expect(walletState.overview!.debits.map((d) => d.id), [
        'demo-debit-1',
        'demo-debit-2',
      ]);
      expect(walletState.statistics!.deliveredCount, 3);
      expect(find.text(l10n.walletEarningsUnavailable), findsOneWidget);
    });

    testWidgets('Home shows the same balance as Wallet (JOD, three decimals); '
        'the chip opens Wallet; sign-out and a fresh sign-in re-read it', (
      tester,
    ) async {
      final expected = WalletBalanceChip.visibleText(l10n, 4000);
      expect(expected, contains('4.000'));
      final chip = find.byType(WalletBalanceChip);
      await launch(tester);
      await signIn(tester);
      expect(tester.widget<WalletBalanceChip>(chip).balanceFils, 4000);
      expect(
        find.descendant(of: chip, matching: find.text(expected)),
        findsOneWidget,
      );

      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(branch(tester), MainNavDestination.wallet.index);
      final walletState = tester
          .element(find.byType(WalletScreen))
          .read<WalletCubit>()
          .state;
      expect(walletState.overview!.summary.balanceFils, 4000);
      expect(
        find.descendant(
          of: find.byType(WalletBalanceCard),
          matching: find.text(expected),
        ),
        findsOneWidget,
      );
      await tapTab(tester, MainNavDestination.home);

      await tester.tap(find.text(l10n.demoTools));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.demoSignOut));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(WalletBalanceChip), findsNothing);
      await signIn(tester);
      expect(tester.widget<WalletBalanceChip>(chip).balanceFils, 4000);
    });

    testWidgets('a pre-assigned order blocks a second acceptance; it carries '
        'into a fresh demo session, which opens Current Order first '
        '(startup routing, D-A73); reset restores the fixtures', (
      tester,
    ) async {
      await launch(tester);
      await signIn(tester);
      await tester.tap(find.text(l10n.demoTools));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.demoScenarioAssigned));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.demoShowNewOffer));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.offerAcceptFull));
      await tester.pumpAndSettle();
      expect(sheet, findsOneWidget);
      expect(find.text(l10n.offerRefused), findsOneWidget);
      await tester.tap(find.text(l10n.offerLater));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.demoSignOut));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(
        tester.element(find.byType(LoginScreen)).read<AppSessionCubit>().state,
        isA<SessionUnauthenticated>(),
      );
      await signIn(tester);
      expect(find.byType(CurrentOrderScreen), findsOneWidget);
      expect(find.text('مطعم النخلة'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);

      // Reset returns to the fixtures: no active order any more. (The tools
      // row is still open from before the sign-out.)
      if (find.text(l10n.demoReset).evaluate().isEmpty) {
        await tester.tap(find.text(l10n.demoTools));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text(l10n.demoReset));
      await tester.pumpAndSettle();
      final current = tester
          .element(find.byType(MaterialApp))
          .read<CurrentOrderCubit>();
      await current.refreshed();
      await tester.pumpAndSettle();
      expect(current.state, isA<CurrentOrderEmpty>());
    });

    testWidgets(
      'the scheduled sample shows in the real sheet with Accept off',
      (tester) async {
        await launch(tester);
        await signIn(tester);
        await tester.tap(find.text(l10n.demoTools));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.demoShowScheduled));
        await tester.pumpAndSettle();
        expect(sheet, findsOneWidget);
        expect(find.text(l10n.offerScheduledAdminOnly), findsOneWidget);
      },
    );

    testWidgets('strip at 320 px and text scale 3: no overflow, readable', (
      tester,
    ) async {
      setScreenSize(tester, 320, 640);
      tester.platformDispatcher.textScaleFactorTestValue = 3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await launch(tester);
      expect(tester.takeException(), isNull);
      expect(
        tester
            .renderObject<RenderParagraph>(find.text(l10n.demoBadge))
            .didExceedMaxLines,
        isFalse,
      );
    });
  });
}
