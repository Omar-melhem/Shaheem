// Home «طلبات بانتظار القبول» (Task 26): PendingOffersCubit, use cases,
// the placeholder, AppOrderOfferCard and the Home section, with the real
// IBM Plex Sans Arabic glyphs. Offers come from fakes here only.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/cubit/current_order_cubit.dart';
import 'package:mobile_frontend/domain/use_cases/get_active_order.dart';
import 'package:mobile_frontend/domain/use_cases/get_captain_location.dart';
import 'package:mobile_frontend/data/repositories/active_order_repository_placeholder.dart';
import 'package:mobile_frontend/data/repositories/captain_location_repository_placeholder.dart';
import 'package:mobile_frontend/data/repositories/availability_permission_gateway_placeholder.dart';
import 'package:mobile_frontend/data/repositories/captain_availability_repository_placeholder.dart';
import 'package:mobile_frontend/data/repositories/order_offer_repository_placeholder.dart';
import 'package:mobile_frontend/domain/entities/app_user.dart';
import 'package:mobile_frontend/domain/entities/order_offer.dart';
import 'package:mobile_frontend/domain/errors/order_offer_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/order_offer_repository.dart';
import 'package:mobile_frontend/domain/use_cases/captain_availability.dart';
import 'package:mobile_frontend/domain/use_cases/order_offers.dart';
import 'package:mobile_frontend/domain/use_cases/sign_out.dart';
import 'package:mobile_frontend/helper/money/jod_format.dart';
import 'package:mobile_frontend/main.dart';
import 'package:mobile_frontend/preview/home_offers_preview.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/theme/app_theme.dart';
import 'package:mobile_frontend/util/fonts.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';
import 'package:mobile_frontend/view/screens/home_screen/cubit/home_availability_cubit.dart';
import 'package:mobile_frontend/view/screens/home_screen/cubit/pending_offers_cubit.dart';
import 'package:mobile_frontend/view/screens/home_screen/view/home_screen.dart';
import 'package:mobile_frontend/view/widget/buttons/app_button.dart';
import 'package:mobile_frontend/view/widget/order/app_order_offer_card.dart';
import 'package:mobile_frontend/view/widget/toggle/app_availability_toggle.dart';

import 'fakes.dart';
import 'test_app.dart';

CaptainOrderOffer offer(
  int i, {
  String? merchant,
  String? pickup = 'الشميساني',
  String? area,
  int fee = 2500,
}) => CaptainOrderOffer(
  id: 'offer-$i',
  merchantName: merchant ?? 'مطعم رقم $i',
  pickupLabel: pickup,
  deliveryAreaName: area ?? 'منطقة $i',
  deliveryFeeFils: fee,
);

/// Offers backend whose answers each test controls.
class FakeOfferRepository implements OrderOfferRepository {
  FakeOfferRepository([List<CaptainOrderOffer>? offers])
    : offers = offers ?? [offer(1), offer(2), offer(3)];

  /// What the server lists as actionable for this captain.
  List<CaptainOrderOffer> offers;
  Object? loadError;
  Object? commandError;
  Completer<void>? commandPending;

  int loadCalls = 0;
  final accepted = <String>[];
  final declined = <String>[];

  @override
  Future<List<CaptainOrderOffer>> getEligibleOffers() async {
    loadCalls++;
    if (loadError != null) throw loadError!;
    return [...offers];
  }

  Future<void> _command(String id, List<String> log) async {
    log.add(id);
    if (commandPending != null) await commandPending!.future;
    if (commandError != null) throw commandError!;
    // The server no longer lists it for this captain.
    offers = [
      for (final o in offers)
        if (o.id != id) o,
    ];
  }

  @override
  Future<void> acceptOffer(String offerId) => _command(offerId, accepted);

  @override
  Future<void> declineOffer(String offerId) => _command(offerId, declined);
}

void main() {
  setUpAll(() async {
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

  group('PendingOffersCubit', () {
    late FakeOfferRepository repo;
    late bool session;
    late int acceptCallbacks;

    PendingOffersCubit build({OrderOfferRepository? source}) {
      final r = source ?? repo;
      final cubit = PendingOffersCubit(
        GetEligibleOffers(r),
        AcceptOrderOffer(r),
        DeclineOrderOffer(r),
        () => session,
      );
      // A confirmed acceptance is observable from state (D-A73: the sheet
      // host reacts to it): count each transition into "accepted".
      var previous = cubit.state.message;
      cubit.stream.listen((state) {
        if (state.message == PendingOffersMessage.accepted &&
            previous != PendingOffersMessage.accepted) {
          acceptCallbacks++;
        }
        previous = state.message;
      });
      return cubit;
    }

    setUp(() {
      repo = FakeOfferRepository();
      session = true;
      acceptCallbacks = 0;
    });

    test('placeholder: "not configured", never an empty list', () async {
      final cubit = build(source: const OrderOfferRepositoryPlaceholder());
      await cubit.load();
      expect(cubit.state.status, PendingOffersStatus.notConfigured);
      expect(cubit.state.offers, isEmpty);
    });

    test('no session: nothing is loaded', () async {
      session = false;
      final cubit = build();
      await cubit.load();
      expect(cubit.state.status, PendingOffersStatus.noSession);
      expect(repo.loadCalls, 0);
    });

    test(
      'server-confirmed empty list is "loaded", not "not configured"',
      () async {
        repo.offers = [];
        final cubit = build();
        await cubit.load();
        expect(cubit.state.status, PendingOffersStatus.loaded);
        expect(cubit.state.offers, isEmpty);
      },
    );

    test('the list is exactly the server list (an ignored but valid offer '
        'stays; expired/declined/taken ones are gone only when the server '
        'drops them)', () async {
      final cubit = build();
      await cubit.load();
      expect(cubit.state.offers.map((o) => o.id), [
        'offer-1',
        'offer-2',
        'offer-3',
      ]);
      // The server stops listing offer-2 (expired or taken elsewhere).
      repo.offers = [offer(1), offer(3)];
      await cubit.load();
      expect(cubit.state.offers.map((o) => o.id), ['offer-1', 'offer-3']);
    });

    test('offline and failure while loading are distinct states', () async {
      final cubit = build();
      repo.loadError = const OrderOfferNetworkUnavailableException();
      await cubit.load();
      expect(cubit.state.status, PendingOffersStatus.noInternet);
      repo.loadError = const OrderOfferServiceUnavailableException();
      await cubit.load();
      expect(cubit.state.status, PendingOffersStatus.failure);
    });

    test('accept: card stays while pending; removed only after the server '
        'confirms; Current Order refresh requested; list reloaded', () async {
      final pending = Completer<void>();
      repo.commandPending = pending;
      final cubit = build();
      await cubit.load();
      final loads = repo.loadCalls;

      final accepting = cubit.accept('offer-2');
      await pumpEventQueue();
      expect(cubit.state.pending, (
        offerId: 'offer-2',
        action: OfferAction.accept,
      ));
      expect(cubit.state.offers.map((o) => o.id), contains('offer-2'));
      expect(acceptCallbacks, 0);

      pending.complete();
      await accepting;
      expect(cubit.state.offers.map((o) => o.id), isNot(contains('offer-2')));
      expect(cubit.state.message, PendingOffersMessage.accepted);
      expect(acceptCallbacks, 1);
      expect(repo.loadCalls, loads + 1);
    });

    test('decline: this captain only; no Current Order refresh', () async {
      final cubit = build();
      await cubit.load();
      await cubit.decline('offer-1');
      expect(repo.declined, ['offer-1']);
      expect(cubit.state.message, PendingOffersMessage.declined);
      expect(cubit.state.offers.map((o) => o.id), ['offer-2', 'offer-3']);
      expect(acceptCallbacks, 0);
    });

    final failures = {
      'no longer available': (
        const OrderOfferNoLongerAvailableException(),
        OfferCardNotice.noLongerAvailable,
      ),
      'refused': (const OrderOfferRefusedException(), OfferCardNotice.refused),
      'not configured': (
        const OrderOfferBackendNotConfiguredException(),
        OfferCardNotice.notConfigured,
      ),
      'offline (unknown outcome)': (
        const OrderOfferNetworkUnavailableException(),
        OfferCardNotice.unconfirmed,
      ),
      'server failure (unknown outcome)': (
        const OrderOfferServiceUnavailableException(),
        OfferCardNotice.unconfirmed,
      ),
    };
    for (final MapEntry(key: name, value: (error, notice))
        in failures.entries) {
      test('$name: never a success, the card stays with a notice', () async {
        repo.commandError = error;
        final cubit = build();
        await cubit.load();
        await cubit.accept('offer-1');
        expect(cubit.state.offers.map((o) => o.id), contains('offer-1'));
        expect(cubit.state.notices['offer-1'], notice);
        expect(cubit.state.pending, isNull);
        expect(cubit.state.message, isNull);
        expect(acceptCallbacks, 0);
      });
    }

    test(
      'a notice that blocks actions ignores new taps until a refresh',
      () async {
        repo.commandError = const OrderOfferNoLongerAvailableException();
        final cubit = build();
        await cubit.load();
        await cubit.accept('offer-1');
        await cubit.accept('offer-1');
        expect(repo.accepted, ['offer-1']);
        repo.commandError = null;
        await cubit.load();
        expect(cubit.state.notices, isEmpty);
      },
    );

    test('double tap and a second card while pending: one command', () async {
      final pending = Completer<void>();
      repo.commandPending = pending;
      final cubit = build();
      await cubit.load();
      final first = cubit.accept('offer-1');
      await pumpEventQueue();
      await cubit.accept('offer-1');
      await cubit.decline('offer-2');
      await cubit.load(); // also ignored while a command runs
      pending.complete();
      await first;
      expect(repo.accepted, ['offer-1']);
      expect(repo.declined, isEmpty);
    });

    test('an id the server did not list (e.g. from a stale push) is not '
        'sent', () async {
      final cubit = build();
      await cubit.load();
      await cubit.accept('from-a-push');
      expect(repo.accepted, isEmpty);
    });

    test('sign-out during a command: answer dropped, list cleared', () async {
      final pending = Completer<void>();
      repo.commandPending = pending;
      final cubit = build();
      await cubit.load();
      final accepting = cubit.accept('offer-1');
      await pumpEventQueue();
      session = false;
      pending.complete();
      await accepting;
      expect(cubit.state.status, PendingOffersStatus.noSession);
      expect(cubit.state.offers, isEmpty);
      expect(acceptCallbacks, 0);
    });

    test('closed during a command: no error, no emit', () async {
      final pending = Completer<void>();
      repo.commandPending = pending;
      final cubit = build();
      await cubit.load();
      final accepting = cubit.accept('offer-1');
      await pumpEventQueue();
      await cubit.close();
      pending.complete();
      await accepting;
      expect(cubit.isClosed, isTrue);
    });

    test('use cases: a hanging command times out as unconfirmed', () async {
      repo.commandPending = Completer<void>();
      final accept = AcceptOrderOffer(
        repo,
        timeout: const Duration(milliseconds: 10),
      );
      expect(await accept('offer-1'), isA<OfferCommandUnconfirmed>());
    });

    test(
      'placeholder commands are "not configured", never confirmed',
      () async {
        const placeholder = OrderOfferRepositoryPlaceholder();
        expect(
          await const AcceptOrderOffer(placeholder)('x'),
          isA<OfferCommandNotConfigured>(),
        );
        expect(
          await const DeclineOrderOffer(placeholder)('x'),
          isA<OfferCommandNotConfigured>(),
        );
      },
    );
  });

  group('AppOrderOfferCard', () {
    Future<void> pumpCard(
      WidgetTester tester,
      CaptainOrderOffer o, {
      VoidCallback? onAccept,
      VoidCallback? onDecline,
      bool disabled = false,
      AppOfferCardAction? busy,
      String? notice,
      TextDirection? direction,
    }) {
      Widget card = AppOrderOfferCard(
        offer: o,
        onAccept: disabled ? null : (onAccept ?? () {}),
        onDecline: disabled ? null : (onDecline ?? () {}),
        busyAction: busy,
        notice: notice,
      );
      if (direction != null) {
        card = Directionality(textDirection: direction, child: card);
      }
      return tester.pumpWidget(
        testApp(
          SingleChildScrollView(padding: const EdgeInsets.all(16), child: card),
        ),
      );
    }

    for (final (name, bad) in [
      ('blank merchant', offer(1, merchant: ' ')),
      ('blank area', offer(1, area: '  ')),
      ('negative fee', offer(1, fee: -1)),
    ]) {
      testWidgets('$name asserts', (tester) async {
        await pumpCard(tester, bad);
        expect(tester.takeException(), isAssertionError);
      });
    }

    testWidgets('a blank notice asserts', (tester) async {
      await pumpCard(tester, offer(1), notice: ' ');
      expect(tester.takeException(), isAssertionError);
    });

    testWidgets('shows merchant, pickup, area and the JOD fee; missing '
        'pickup is neutral', (tester) async {
      await pumpCard(tester, offer(1, merchant: 'مطعم السنابل', fee: 2500));
      expect(find.text('مطعم السنابل'), findsOneWidget);
      expect(find.textContaining('الشميساني'), findsOneWidget);
      expect(find.textContaining('منطقة 1'), findsOneWidget);
      expect(
        find.text('${ltrIsolate('2.500')} ${l10n.walletCurrencySymbol}'),
        findsOneWidget,
      );
      await pumpCard(tester, offer(1, pickup: null));
      expect(find.textContaining(l10n.offerPickupUnknown), findsOneWidget);
    });

    testWidgets('«قبول» is the filled red primary with a check icon; '
        '«رفض» is a neutral outline with a close icon (D-A69)', (tester) async {
      await pumpCard(tester, offer(1));
      final decline = tester.widget<AppButton>(
        find.widgetWithText(AppButton, l10n.offerDecline),
      );
      final scheme = AppTheme.light.colorScheme;
      expect(decline.backgroundColor, scheme.surface);
      expect(decline.foregroundColor, AppColor.textPrimary);
      expect(decline.border, const BorderSide(color: AppColor.inputOutline));
      final accept = tester.widget<AppButton>(
        find.widgetWithText(AppButton, l10n.offerAccept),
      );
      // D-A69: Accept keeps AppButton's default red (theme pressed and
      // disabled states), so no per-call colors are passed.
      expect(accept.backgroundColor, isNull);
      expect(accept.foregroundColor, isNull);
      final acceptMaterial = tester.widget<Material>(
        find
            .descendant(
              of: find.widgetWithText(AppButton, l10n.offerAccept),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(acceptMaterial.color, AppColor.primary);
      expect((accept.icon! as Icon).icon, Icons.check_circle_outline);
      expect((decline.icon! as Icon).icon, Icons.close);
      double contrast(Color a, Color b) {
        final la = a.computeLuminance(), lb = b.computeLuminance();
        return ((la > lb ? la : lb) + 0.05) / ((la > lb ? lb : la) + 0.05);
      }

      expect(contrast(AppColor.textPrimary, scheme.surface), greaterThan(4.5));
      expect(contrast(scheme.onPrimary, scheme.primary), greaterThan(4.5));
    });

    testWidgets('taps reach the callbacks; null disables', (tester) async {
      var accepts = 0, declines = 0;
      await pumpCard(
        tester,
        offer(1),
        onAccept: () => accepts++,
        onDecline: () => declines++,
      );
      await tester.tap(find.text(l10n.offerAccept));
      await tester.tap(find.text(l10n.offerDecline));
      expect((accepts, declines), (1, 1));
      await pumpCard(tester, offer(1), disabled: true);
      for (final b in tester.widgetList<AppButton>(find.byType(AppButton))) {
        expect(b.onPressed, isNull);
      }
    });

    testWidgets('busy accept: spinner on «قبول», «رفض» disabled, taps do '
        'nothing', (tester) async {
      var declines = 0;
      await pumpCard(
        tester,
        offer(1),
        onDecline: () => declines++,
        busy: AppOfferCardAction.accept,
      );
      final accept = tester.widget<AppButton>(
        find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(AppButton),
        ),
      );
      expect(accept.isLoading, isTrue);
      final decline = tester.widget<AppButton>(
        find.widgetWithText(AppButton, l10n.offerDecline),
      );
      expect(decline.onPressed, isNull);
      await tester.tap(find.text(l10n.offerDecline), warnIfMissed: false);
      expect(declines, 0);
    });

    testWidgets('semantics: one summary with merchant, pickup, area and fee; '
        'buttons named', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpCard(tester, offer(1, merchant: 'مطعم السنابل'));
      expect(
        find.bySemanticsLabel(
          l10n.offerCardSemantics(
            'مطعم السنابل',
            'الشميساني',
            'منطقة 1',
            '2.500',
          ),
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(l10n.offerAccept), findsOneWidget);
      expect(find.bySemanticsLabel(l10n.offerDecline), findsOneWidget);
      semantics.dispose();
    });

    for (final direction in TextDirection.values) {
      testWidgets('$direction: accept at the start, decline at the end', (
        tester,
      ) async {
        await pumpCard(tester, offer(1), direction: direction);
        final accept = tester.getCenter(find.text(l10n.offerAccept)).dx;
        final decline = tester.getCenter(find.text(l10n.offerDecline)).dx;
        expect(
          direction == TextDirection.rtl ? accept > decline : accept < decline,
          isTrue,
        );
      });
    }
  });

  group('Home section', () {
    final cards = find.byType(AppOrderOfferCard);
    // The page body's scrollable (the Home AppBar has its own, D-A71).
    final homeBody = find.descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(Scrollable),
    );

    /// Pumps Home with a signed-in captain and [repository] for offers.
    Future<PendingOffersCubit> pumpHome(
      WidgetTester tester, {
      OrderOfferRepository? repository,
      bool signedIn = true,
    }) async {
      final session = AppSessionCubit(SignOut(FakeAuthRepository()));
      if (signedIn) {
        session.authenticate(
          const AppUser(id: 'c1', displayName: 'أحمد'),
          session.beginAttempt(),
        );
      }
      final availability = HomeAvailabilityCubit(
        const GetCaptainAvailability(
          CaptainAvailabilityRepositoryPlaceholder(),
        ),
        const ChangeCaptainAvailability(
          CaptainAvailabilityRepositoryPlaceholder(),
        ),
        const AvailabilityPermissionGatewayPlaceholder(),
        () => session.state is SessionAuthenticated,
      );
      final r = repository ?? FakeOfferRepository();
      final offers = PendingOffersCubit(
        GetEligibleOffers(r),
        AcceptOrderOffer(r),
        DeclineOrderOffer(r),
        () => session.state is SessionAuthenticated,
      );
      addTearDown(offers.close);
      addTearDown(availability.close);
      addTearDown(session.close);
      await tester.pumpWidget(
        testApp(
          MultiBlocProvider(
            providers: [
              BlocProvider.value(value: session),
              BlocProvider.value(value: availability),
              BlocProvider.value(value: offers),
              // The app-level active-order owner Home reads (D-A73); the
              // placeholder reports "not configured", so nothing is shown.
              BlocProvider(
                create: (_) => CurrentOrderCubit(
                  const GetActiveOrder(ActiveOrderRepositoryPlaceholder()),
                  const GetCaptainLocation(
                    CaptainLocationRepositoryPlaceholder(),
                  ),
                ),
              ),
            ],
            child: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return offers;
    }

    testWidgets('order: greeting, availability card, section, cards', (
      tester,
    ) async {
      await pumpHome(tester);
      final greeting = tester.getTopLeft(find.text(l10n.homeGreeting('أحمد')));
      final toggle = tester.getTopLeft(find.byType(AppAvailabilityToggle));
      final title = tester.getTopLeft(
        find.text(l10n.offersSectionTitleWithCount(3)),
      );
      final firstCard = tester.getTopLeft(cards.first);
      expect(greeting.dy, lessThan(toggle.dy));
      expect(toggle.dy, lessThan(title.dy));
      expect(title.dy, lessThan(firstCard.dy));
      expect(find.text(l10n.offersSectionSubtitle), findsOneWidget);
    });

    testWidgets('default source (not configured): truthful line, no cards, '
        'never "no offers"', (tester) async {
      await pumpHome(
        tester,
        repository: const OrderOfferRepositoryPlaceholder(),
      );
      expect(find.text(l10n.offersNotConfigured), findsOneWidget);
      expect(find.text(l10n.offersEmpty), findsNothing);
      expect(cards, findsNothing);
      expect(find.text(l10n.offersSectionTitle), findsOneWidget);
    });

    testWidgets('no session: no offers are loaded', (tester) async {
      final repo = FakeOfferRepository();
      await pumpHome(tester, repository: repo, signedIn: false);
      expect(find.text(l10n.offersNoSession), findsOneWidget);
      expect(repo.loadCalls, 0);
      expect(cards, findsNothing);
    });

    testWidgets('confirmed empty: "no offers now" with refresh', (
      tester,
    ) async {
      await pumpHome(tester, repository: FakeOfferRepository([]));
      expect(find.text(l10n.offersEmpty), findsOneWidget);
      expect(find.text(l10n.refresh), findsOneWidget);
    });

    testWidgets('load failure: message and refresh that reloads', (
      tester,
    ) async {
      final repo = FakeOfferRepository()
        ..loadError = const OrderOfferServiceUnavailableException();
      await pumpHome(tester, repository: repo);
      expect(find.text(l10n.offersLoadFailed), findsOneWidget);
      repo.loadError = null;
      await tester.ensureVisible(find.text(l10n.refresh));
      await tester.tap(find.text(l10n.refresh));
      await tester.pumpAndSettle();
      expect(find.text(l10n.offersSectionTitleWithCount(3)), findsOneWidget);
      expect(cards, findsWidgets);
    });

    for (final count in [1, 3, 20, 100]) {
      testWidgets('$count offers: lazily built, page scrolls to the last', (
        tester,
      ) async {
        setScreenSize(tester, 375, 800);
        await pumpHome(
          tester,
          repository: FakeOfferRepository([
            for (var i = 1; i <= count; i++) offer(i),
          ]),
        );
        expect(
          find.text(l10n.offersSectionTitleWithCount(count)),
          findsOneWidget,
        );
        // Only what is near the viewport is built.
        expect(
          tester.widgetList(cards).length,
          lessThanOrEqualTo(count < 10 ? count : 10),
        );
        await tester.scrollUntilVisible(
          find.byKey(ValueKey('offer-$count')),
          600,
          scrollable: homeBody,
        );
        expect(find.byKey(ValueKey('offer-$count')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('cards fill the width inside the screen padding; height is '
        'content only', (tester) async {
      setScreenSize(tester, 375, 800);
      await pumpHome(
        tester,
        repository: FakeOfferRepository([
          offer(1),
          offer(
            2,
            merchant: 'مخبز وحلويات الياسمين الشرقية للمناسبات والأفراح',
            area: 'دابوق — الحي الغربي قرب المدارس الخاصة والحديقة',
          ),
        ]),
      );
      final first = tester.getRect(find.byKey(const ValueKey('offer-1')));
      final second = tester.getRect(find.byKey(const ValueKey('offer-2')));
      final toggle = tester.getRect(find.byType(AppAvailabilityToggle));
      expect(first.width, second.width);
      // The same content edge as the Home AppBar's availability row.
      expect(first.width, toggle.width);
      expect(first.width, lessThan(375));
      expect(second.height, greaterThan(first.height));
    });

    testWidgets('accept in the UI: spinner, card kept until confirmed, then '
        'removed with the confirmation line', (tester) async {
      final pending = Completer<void>();
      final repo = FakeOfferRepository()..commandPending = pending;
      await pumpHome(tester, repository: repo);
      final accept = find.descendant(
        of: find.byKey(const ValueKey('offer-1')),
        matching: find.text(l10n.offerAccept),
      );
      await tester.ensureVisible(accept);
      await tester.tap(accept);
      await tester.pump();
      expect(find.byKey(const ValueKey('offer-1')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Other cards cannot send anything meanwhile.
      final other = tester.widget<AppButton>(
        find.descendant(
          of: find.byKey(const ValueKey('offer-2')),
          matching: find.widgetWithText(AppButton, l10n.offerAccept),
        ),
      );
      expect(other.onPressed, isNull);

      pending.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('offer-1')), findsNothing);
      // The confirmation is in the section header, above the cards.
      tester.state<ScrollableState>(homeBody).position.jumpTo(0);
      await tester.pumpAndSettle();
      expect(find.text(l10n.offersAcceptedMessage), findsOneWidget);
      expect(repo.accepted, ['offer-1']);
    });

    testWidgets('expired on the server: notice on the card, actions off, '
        'refresh in the header', (tester) async {
      final repo = FakeOfferRepository()
        ..commandError = const OrderOfferNoLongerAvailableException();
      await pumpHome(tester, repository: repo);
      final decline = find.descendant(
        of: find.byKey(const ValueKey('offer-1')),
        matching: find.text(l10n.offerDecline),
      );
      await tester.ensureVisible(decline);
      await tester.tap(decline);
      await tester.pumpAndSettle();
      expect(find.text(l10n.offerNoLongerAvailable), findsOneWidget);
      final buttons = tester.widgetList<AppButton>(
        find.descendant(
          of: find.byKey(const ValueKey('offer-1')),
          matching: find.byType(AppButton),
        ),
      );
      for (final b in buttons) {
        expect(b.onPressed, isNull);
      }
      // The header (with «تحديث») is above; scroll back to it.
      await tester.drag(homeBody, const Offset(0, 2000));
      await tester.pumpAndSettle();
      expect(find.text(l10n.refresh), findsOneWidget);
    });

    for (final width in [320.0, 375.0, 450.0]) {
      for (final scale in [1.0, 2.0, 3.0]) {
        testWidgets('$width px × $scale: long Arabic data wraps, nothing cut, '
            '48 px actions', (tester) async {
          setScreenSize(tester, width, 800);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await pumpHome(
            tester,
            repository: FakeOfferRepository([
              offer(
                1,
                merchant: 'مخبز وحلويات الياسمين الشرقية للمناسبات',
                pickup: 'جبل عمّان، الدوار الثالث، بجانب المكتبة العامة',
                area: 'دابوق — الحي الغربي قرب المدارس الخاصة',
                fee: 123456789,
              ),
            ]),
          );
          expect(tester.takeException(), isNull);
          final card = find.byKey(const ValueKey('offer-1'));
          await tester.scrollUntilVisible(card, 200, scrollable: homeBody);
          await tester.pumpAndSettle();
          for (final p in tester.renderObjectList<RenderParagraph>(
            find.descendant(of: card, matching: find.byType(RichText)),
          )) {
            expect(p.didExceedMaxLines, isFalse, reason: p.text.toPlainText());
          }
          for (final b in [l10n.offerAccept, l10n.offerDecline]) {
            final button = find.descendant(
              of: card,
              matching: find.widgetWithText(AppButton, b),
            );
            expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
          }
          expect(
            find.descendant(
              of: card,
              matching: find.text(
                '${ltrIsolate(formatJodFils(123456789))} '
                '${l10n.walletCurrencySymbol}',
              ),
            ),
            findsOneWidget,
          );
        });
      }
    }

    testWidgets('landscape short screen: scrolls, no overflow', (tester) async {
      setScreenSize(tester, 740, 320);
      await pumpHome(tester);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('offer-3')),
        300,
        scrollable: homeBody,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('app composition', () {
    testWidgets('real app, signed in, default sources: not-configured line '
        'and no cards', (tester) async {
      await tester.pumpWidget(
        MainApp(
          connectivityService: FakeInternetConnectionService(),
          authRepository: FakeAuthRepository(hasSession: true),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(l10n.offersNotConfigured));
      expect(find.text(l10n.offersNotConfigured), findsOneWidget);
      expect(find.byType(AppOrderOfferCard), findsNothing);
    });

    testWidgets('Login debug preview still opens Home (D-A40 kept); no '
        'session means no offers', (tester) async {
      await tester.pumpWidget(
        MainApp(
          connectivityService: FakeInternetConnectionService(),
          authRepository: FakeAuthRepository(),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.text(l10n.debugPreviewButton);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      await tester.ensureVisible(find.text(l10n.offersNoSession));
      expect(find.text(l10n.offersNoSession), findsOneWidget);
      expect(find.byType(AppOrderOfferCard), findsNothing);
    });

    testWidgets('standalone preview: caption, sample cards, commands say '
        'nothing was sent', (tester) async {
      await tester.pumpWidget(const HomeOffersPreviewApp());
      await tester.pumpAndSettle();
      expect(find.text(l10n.previewCaption), findsOneWidget);
      expect(find.byType(AppOrderOfferCard), findsAtLeastNWidgets(1));
      final accept = find.descendant(
        of: find.byKey(ValueKey(previewSampleOffers.first.id)),
        matching: find.text(l10n.offerAccept),
      );
      await tester.ensureVisible(accept);
      // The lazy list re-estimates its extent after the jump; settle first.
      await tester.pumpAndSettle();
      await tester.tap(accept);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      await tester.pumpAndSettle();
      expect(find.text(l10n.offerNotConfigured), findsOneWidget);
      expect(
        find.byKey(ValueKey(previewSampleOffers.first.id)),
        findsOneWidget,
      );
    });

    test('the preview entrypoint is not imported by the app', () {
      final appFiles = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.contains('${Platform.pathSeparator}preview'));
      for (final f in appFiles) {
        expect(
          f.readAsStringSync().contains('preview/home_offers_preview.dart'),
          isFalse,
          reason: f.path,
        );
      }
    });
  });
}
