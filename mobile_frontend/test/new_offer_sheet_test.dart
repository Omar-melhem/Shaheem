// New-order offer sheet (Task 36): the earnings maths and gating, the sheet
// widget, the shell-level presentation through the real app (fake
// repositories: widget tests, not production wiring proof), the declined-
// offers history, the card's action colors and the Wallet title.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_frontend/data/repositories/order_history_repository_placeholder.dart';
import 'package:mobile_frontend/domain/entities/active_order.dart';
import 'package:mobile_frontend/domain/entities/declined_offer.dart';
import 'package:mobile_frontend/domain/entities/order_offer.dart';
import 'package:mobile_frontend/domain/errors/order_history_exceptions.dart';
import 'package:mobile_frontend/domain/errors/order_offer_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/order_history_repository.dart';
import 'package:mobile_frontend/domain/repositories/order_offer_repository.dart';
import 'package:mobile_frontend/domain/use_cases/get_active_order.dart';
import 'package:mobile_frontend/domain/use_cases/get_captain_location.dart';
import 'package:mobile_frontend/domain/use_cases/get_declined_offers.dart';
import 'package:mobile_frontend/domain/use_cases/order_offers.dart';
import 'package:mobile_frontend/helper/date/date_time_format.dart';
import 'package:mobile_frontend/helper/money/jod_format.dart';
import 'package:mobile_frontend/main.dart';
import 'package:mobile_frontend/preview/new_offer_sheet_preview.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/theme/app_theme.dart';
import 'package:mobile_frontend/util/fonts.dart';
import 'package:mobile_frontend/domain/repositories/active_order_repository.dart';
import 'package:mobile_frontend/domain/errors/order_exceptions.dart';
import 'package:mobile_frontend/util/routes/routes_string.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';
import 'package:mobile_frontend/view/navigation/app_nav_bar.dart';
import 'package:mobile_frontend/view/navigation/new_offer_sheet_host.dart';
import 'package:mobile_frontend/view/navigation/new_order_offer_sheet.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/cubit/current_order_cubit.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/view/current_order_screen.dart';
import 'package:mobile_frontend/view/screens/home_screen/cubit/pending_offers_cubit.dart';
import 'package:mobile_frontend/view/screens/authentication/view/login_screen.dart';
import 'package:mobile_frontend/view/screens/order_history_screen/cubit/declined_offers_cubit.dart';
import 'package:mobile_frontend/view/screens/order_history_screen/widget/declined_offer_tile.dart';
import 'package:mobile_frontend/view/screens/wallet_screen/view/wallet_screen.dart';
import 'package:mobile_frontend/view/widget/buttons/app_button.dart';
import 'package:mobile_frontend/view/widget/navigation/main_nav_destination.dart';
import 'package:mobile_frontend/view/widget/navigation/main_navigation_bar.dart';
import 'package:mobile_frontend/view/widget/order/app_order_offer_card.dart';
import 'package:mobile_frontend/view/widget/pop_up_screen/app_popup.dart';

import 'fakes.dart';
import 'test_app.dart';

/// Test data only: production code never contains an offer.
CaptainOrderOffer offer(
  String id, {
  OrderOfferKind kind = OrderOfferKind.instant,
  String? orderId,
  int fee = 2500,
  OfferCommissionSnapshot? commission = const OfferCommissionSnapshot(
    amountFils: 500,
    rateBasisPoints: 2000,
  ),
  DateTime? scheduledPickupAt,
  String? merchant,
  String? area,
}) => CaptainOrderOffer(
  id: id,
  orderId: orderId ?? 'order-$id',
  kind: kind,
  merchantName: merchant ?? 'مطعم $id',
  pickupLabel: 'الشميساني',
  deliveryAreaName: area ?? 'تلاع العلي',
  deliveryFeeFils: fee,
  commission: commission,
  scheduledPickupAt: scheduledPickupAt,
);

/// Offers backend whose answers each test controls.
class FakeOffers implements OrderOfferRepository {
  FakeOffers(this.offers);

  List<CaptainOrderOffer> offers;
  Object? commandError;
  Completer<void>? commandPending;
  int loadCalls = 0;
  final accepted = <String>[];
  final declined = <String>[];

  /// Runs when the server "confirms" an acceptance (e.g. the order becomes
  /// the active one).
  void Function(String offerId)? onAccepted;

  @override
  Future<List<CaptainOrderOffer>> getEligibleOffers() async {
    loadCalls++;
    return [...offers];
  }

  Future<void> _command(String id, List<String> log) async {
    log.add(id);
    if (commandPending != null) await commandPending!.future;
    if (commandError != null) throw commandError!;
    offers = [
      for (final o in offers)
        if (o.id != id) o,
    ];
  }

  @override
  Future<void> acceptOffer(String offerId) async {
    await _command(offerId, accepted);
    onAccepted?.call(offerId);
  }

  @override
  Future<void> declineOffer(String offerId) => _command(offerId, declined);
}

/// History backend whose every read waits for [release], so a test can
/// change the "server" while a read is in flight.
class _GatedHistory implements OrderHistoryRepository {
  List<DeclinedOfferRecord> records = const [];
  int calls = 0;
  final _gates = <Completer<List<DeclinedOfferRecord>>>[];

  /// Answers the oldest waiting read with [answer] (or the current
  /// [records]).
  void release([List<DeclinedOfferRecord>? answer]) =>
      _gates.removeAt(0).complete(answer ?? records);

  @override
  Future<List<DeclinedOfferRecord>> getDeclinedOffers() {
    calls++;
    final gate = Completer<List<DeclinedOfferRecord>>();
    _gates.add(gate);
    return gate.future;
  }
}

/// History backend whose answer each test controls.
class FakeHistory implements OrderHistoryRepository {
  FakeHistory({this.records = const [], this.error});

  List<DeclinedOfferRecord> records;
  Object? error;
  int calls = 0;

  @override
  Future<List<DeclinedOfferRecord>> getDeclinedOffers() async {
    calls++;
    if (error != null) throw error!;
    return records;
  }
}

Finder get sheet => find.byType(NewOrderOfferSheet);

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

  group('earnings and gating', () {
    test('net = fee − snapshot commission (integer fils); inconsistent or '
        'missing snapshot gives no net', () {
      expect(offer('a').netEarningsFils, 2000);
      expect(offer('a').hasEarningsDisclosure, isTrue);
      final zero = offer(
        'z',
        commission: const OfferCommissionSnapshot(
          amountFils: 0,
          rateBasisPoints: 0,
        ),
      );
      expect(zero.netEarningsFils, 2500);
      expect(zero.hasEarningsDisclosure, isTrue);
      expect(offer('m', commission: null).netEarningsFils, isNull);
      for (final bad in [
        const OfferCommissionSnapshot(amountFils: 2501, rateBasisPoints: 2000),
        const OfferCommissionSnapshot(amountFils: -1, rateBasisPoints: 2000),
      ]) {
        expect(offer('b', commission: bad).netEarningsFils, isNull);
        expect(offer('b', commission: bad).hasEarningsDisclosure, isFalse);
      }
      // The rate is part of the disclosure and must be a valid percentage.
      for (final rate in [null, -1, 10001]) {
        final o = offer(
          'r',
          commission: OfferCommissionSnapshot(
            amountFils: 500,
            rateBasisPoints: rate,
          ),
        );
        expect(o.netEarningsFils, 2000);
        expect(o.hasEarningsDisclosure, isFalse, reason: '$rate');
      }
    });

    test('accept is blocked for scheduled offers and missing snapshots; '
        'the default kind is instant', () {
      expect(offerAcceptBlock(offer('a')), OfferAcceptBlock.none);
      expect(
        offerAcceptBlock(offer('s', kind: OrderOfferKind.scheduled)),
        OfferAcceptBlock.scheduledAdminOnly,
      );
      expect(
        offerAcceptBlock(offer('m', commission: null)),
        OfferAcceptBlock.earningsMissing,
      );
      expect(
        const CaptainOrderOffer(
          id: 'x',
          merchantName: 'م',
          deliveryAreaName: 'ع',
          deliveryFeeFils: 0,
        ).kind,
        OrderOfferKind.instant,
      );
    });
  });

  group('NewOrderOfferSheet', () {
    Future<void> pumpSheet(
      WidgetTester tester,
      CaptainOrderOffer o, {
      VoidCallback? onAccept,
      VoidCallback? onDecline,
      VoidCallback? onLater,
      AppOfferCardAction? busy,
      String? notice,
    }) async {
      // A fresh app each time, so no earlier sheet stays open.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        testApp(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                enableDrag: false,
                builder: (_) => NewOrderOfferSheet(
                  offer: o,
                  onAccept: onAccept,
                  onDecline: onDecline,
                  onLater: onLater,
                  busyAction: busy,
                  notice: notice,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      // A running spinner never settles.
      if (busy == null) {
        await tester.pumpAndSettle();
      } else {
        await tester.pump(const Duration(seconds: 1));
      }
    }

    String amount(int fils) =>
        '${ltrIsolate(formatJodFils(fils))} ${l10n.walletCurrencySymbol}';

    /// Every text a breakdown would add: a percentage, a minus sign or a
    /// net amount (Task 38 removed them; only the full fee remains).
    void expectOnlyFullFee(WidgetTester tester, int feeFils) {
      expect(find.text(l10n.offerGrossFeeLabel), findsOneWidget);
      expect(find.text(amount(feeFils)), findsOneWidget);
      final sheet = find.byType(NewOrderOfferSheet);
      final texts = [
        for (final t in tester.widgetList<Text>(
          find.descendant(of: sheet, matching: find.byType(Text)),
        ))
          t.data ?? '',
      ];
      // Exactly one amount in the sheet: the fee.
      expect(texts.where((t) => t.contains(l10n.walletCurrencySymbol)), [
        amount(feeFils),
      ]);
      expect(texts.where((t) => t.contains('%')), isEmpty);
      expect(texts.where((t) => t.contains('-')), isEmpty);
      for (final icon in [Icons.percent, Icons.price_check]) {
        expect(find.byIcon(icon), findsNothing, reason: '$icon');
      }
    }

    testWidgets('instant: type, merchant, pickup, delivery AREA and the full '
        'fee as the only amount, with an icon per section', (tester) async {
      await pumpSheet(tester, offer('a'), onAccept: () {}, onDecline: () {});
      expect(find.text(l10n.newOfferSheetTitle), findsOneWidget);
      expect(find.text(l10n.offerKindInstant), findsOneWidget);
      expect(find.text(l10n.offerKindScheduled), findsNothing);
      expect(find.text('مطعم a'), findsOneWidget);
      expect(find.text(l10n.offerPickupLine('الشميساني')), findsOneWidget);
      expect(
        find.text(l10n.offerDeliveryAreaLine('تلاع العلي')),
        findsOneWidget,
      );
      expect(
        find.textContaining(l10n.offerScheduledPickupLine('').trim()),
        findsNothing,
      );
      // 2.500 with a 0.500 commission snapshot: the fee is shown as-is,
      // with no commission, rate or net 2.000.
      expectOnlyFullFee(tester, 2500);
      expect(find.text(amount(2000)), findsNothing);
      expect(find.text(amount(500)), findsNothing);
      for (final icon in [
        Icons.inventory_2_outlined,
        Icons.bolt,
        Icons.storefront_outlined,
        Icons.location_on_outlined,
        Icons.flag_outlined,
        Icons.local_shipping_outlined,
        Icons.check_circle_outline,
        Icons.close,
      ]) {
        expect(find.byIcon(icon), findsOneWidget, reason: '$icon');
      }
      // One faint divider, not a heavy line.
      final divider = tester.widget<Divider>(find.byType(Divider));
      expect(divider.thickness, lessThan(1));
    });

    testWidgets('the fee row is one screen-reader sentence', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpSheet(tester, offer('a'));
      expect(
        find.bySemanticsLabel(
          RegExp(
            '${RegExp.escape(l10n.offerGrossFeeLabel)}.*'
            '${RegExp.escape(formatJodFils(2500))}',
            dotAll: true,
          ),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('scheduled: «مؤجل» with its icon and the local pickup time; '
        'a missing time reads "not available"', (tester) async {
      final at = DateTime(2026, 11, 16, 13, 30);
      await pumpSheet(
        tester,
        offer('s', kind: OrderOfferKind.scheduled, scheduledPickupAt: at),
      );
      expect(find.text(l10n.offerKindScheduled), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
      expect(
        find.text(
          l10n.offerScheduledPickupLine(ltrIsolate(formatLocalDateTime(at))),
        ),
        findsOneWidget,
      );
      // Scheduled offers show the same single full-fee row.
      expect(find.text(l10n.offerGrossFeeLabel), findsOneWidget);
      expect(find.text(amount(2500)), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
      await pumpSheet(tester, offer('s', kind: OrderOfferKind.scheduled));
      expect(
        find.text(l10n.offerScheduledPickupLine(l10n.offerValueUnavailable)),
        findsOneWidget,
      );
    });

    testWidgets('missing or inconsistent snapshot: still only the full fee, '
        'nothing "not available" in its place', (tester) async {
      for (final commission in [
        null,
        const OfferCommissionSnapshot(amountFils: 2501, rateBasisPoints: 2000),
        const OfferCommissionSnapshot(amountFils: 500),
      ]) {
        await pumpSheet(tester, offer('m', commission: commission));
        expectOnlyFullFee(tester, 2500);
        expect(find.text(l10n.offerValueUnavailable), findsNothing);
      }
    });

    testWidgets(
      'accept is the red primary with a check icon; decline is outlined '
      'error with a close icon; callbacks and null disable',
      (tester) async {
        var accepts = 0, declines = 0, laters = 0;
        await pumpSheet(
          tester,
          offer('a'),
          onAccept: () => accepts++,
          onDecline: () => declines++,
          onLater: () => laters++,
        );
        final scheme = AppTheme.light.colorScheme;
        AppButton button(String label) =>
            tester.widget<AppButton>(find.widgetWithText(AppButton, label));
        final accept = button(l10n.offerAcceptFull);
        final decline = button(l10n.offerDeclineFull);
        // D-A69: default red Accept; neutral outlined Decline.
        expect(accept.backgroundColor, isNull);
        expect(scheme.primary, AppColor.primary);
        expect((accept.icon! as Icon).icon, Icons.check_circle_outline);
        expect(decline.foregroundColor, AppColor.textPrimary);
        expect(decline.border, const BorderSide(color: AppColor.inputOutline));
        expect((decline.icon! as Icon).icon, Icons.close);
        await tester.tap(find.text(l10n.offerAcceptFull));
        await tester.tap(find.text(l10n.offerDeclineFull));
        await tester.tap(find.text(l10n.offerLater));
        expect((accepts, declines, laters), (1, 1, 1));
        // Touch targets.
        for (final label in [l10n.offerAcceptFull, l10n.offerDeclineFull]) {
          expect(
            tester.getSize(find.widgetWithText(AppButton, label)).height,
            greaterThanOrEqualTo(48),
          );
        }

        await pumpSheet(tester, offer('a'));
        expect(button(l10n.offerAcceptFull).onPressed, isNull);
        expect(button(l10n.offerDeclineFull).onPressed, isNull);
        expect(button(l10n.offerDeclineFull).border, isNull);
      },
    );

    testWidgets('busy accept: spinner, decline and later off; one tap only', (
      tester,
    ) async {
      var declines = 0;
      await pumpSheet(
        tester,
        offer('a'),
        onAccept: () {},
        onDecline: () => declines++,
        onLater: () {},
        busy: AppOfferCardAction.accept,
        notice: l10n.offerUnconfirmed,
      );
      expect(
        tester
            .widget<AppButton>(
              find.widgetWithText(AppButton, l10n.offerAcceptFull),
            )
            .isLoading,
        isTrue,
      );
      expect(
        tester
            .widget<AppButton>(
              find.widgetWithText(AppButton, l10n.offerDeclineFull),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text(l10n.offerDeclineFull), warnIfMissed: false);
      expect(declines, 0);
      expect(find.text(l10n.offerUnconfirmed), findsOneWidget);
    });

    for (final width in [320.0, 375.0, 450.0]) {
      for (final scale in [1.0, 2.0, 3.0]) {
        for (final height in [640.0, 360.0]) {
          testWidgets(
            '${width.toInt()}×${height.toInt()} at text scale $scale: no '
            'overflow, nothing truncated, both answers visible',
            (tester) async {
              setScreenSize(tester, width, height);
              tester.platformDispatcher.textScaleFactorTestValue = scale;
              addTearDown(
                tester.platformDispatcher.clearTextScaleFactorTestValue,
              );
              const longName =
                  'مطعم ومطبخ السنابل الذهبية للمأكولات الشرقية والغربية';
              await pumpSheet(
                tester,
                offer(
                  'a',
                  merchant: longName,
                  area: 'ضاحية الأمير راشد الجنوبية',
                  fee: 1234500,
                  commission: const OfferCommissionSnapshot(
                    amountFils: 246900,
                    rateBasisPoints: 2000,
                  ),
                ),
                onAccept: () {},
                onDecline: () {},
                onLater: () {},
              );
              expect(tester.takeException(), isNull);
              for (final text in [
                longName,
                l10n.offerGrossFeeLabel,
                amount(1234500),
              ]) {
                expect(
                  tester
                      .renderObject<RenderParagraph>(find.text(text))
                      .didExceedMaxLines,
                  isFalse,
                );
              }
              // Pinned (visible at once) when there is room at this text
              // size; otherwise reachable by scrolling, never clipped.
              final pinned = height >= 300 * scale;
              for (final label in [
                l10n.offerAcceptFull,
                l10n.offerDeclineFull,
              ]) {
                final button = find.widgetWithText(AppButton, label);
                if (pinned) {
                  expect(find.text(label).hitTestable(), findsOneWidget);
                } else {
                  await tester.ensureVisible(button);
                  await tester.pumpAndSettle();
                }
                final rect = tester.getRect(button);
                expect(rect.bottom, lessThanOrEqualTo(height), reason: label);
                expect(rect.top, greaterThanOrEqualTo(0), reason: label);
                expect(find.text(label).hitTestable(), findsOneWidget);
                expect(rect.height, greaterThanOrEqualTo(48));
              }
            },
          );
        }
      }
    }

    testWidgets('LTR text keeps the order of section labels and amounts', (
      tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: testApp(
            NewOrderOfferSheet(
              offer: offer('a'),
              onAccept: null,
              onDecline: null,
              onLater: null,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text(amount(2500)), findsOneWidget);
    });
  });

  group('history: declined offers', () {
    test(
      'newest first; typed failures; placeholder is not configured',
      () async {
        final a = DeclinedOfferRecord(
          offerId: 'a',
          declinedAt: DateTime.utc(2026, 11, 14),
        );
        final b = DeclinedOfferRecord(
          offerId: 'b',
          declinedAt: DateTime.utc(2026, 11, 15),
        );
        const u = DeclinedOfferRecord(offerId: 'u');
        final r =
            await GetDeclinedOffers(FakeHistory(records: [u, a, b]))()
                as DeclinedOffersLoaded;
        expect(r.records.map((x) => x.offerId), ['b', 'a', 'u']);
        Future<DeclinedOffersResult> with_(Object e) =>
            GetDeclinedOffers(FakeHistory(error: e))();
        expect(
          await with_(const OrderHistoryBackendNotConfiguredException()),
          isA<DeclinedOffersNotConfigured>(),
        );
        expect(
          await with_(const OrderHistoryNetworkUnavailableException()),
          isA<DeclinedOffersNoInternet>(),
        );
        expect(await with_(StateError('x')), isA<DeclinedOffersFailure>());
        expect(
          await GetDeclinedOffers(const OrderHistoryRepositoryPlaceholder())(),
          isA<DeclinedOffersNotConfigured>(),
        );
      },
    );

    test('Cubit: no session loads nothing; failure clears records', () async {
      var session = false;
      final repo = FakeHistory(
        records: [const DeclinedOfferRecord(offerId: 'a')],
      );
      final cubit = DeclinedOffersCubit(GetDeclinedOffers(repo), () => session);
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.status, DeclinedOffersStatus.noSession);
      expect(repo.calls, 0);
      session = true;
      await cubit.load();
      expect(cubit.state.records, hasLength(1));
      repo.error = const OrderHistoryServiceUnavailableException();
      await cubit.load();
      expect(cubit.state.status, DeclinedOffersStatus.failure);
      expect(cubit.state.records, isEmpty);
      expect(cubit.state.canRetry, isTrue);
    });

    test('Cubit refresh: nothing before the first load; during a load, '
        'repeated invalidations give exactly one more read; a late answer '
        'never replaces a newer one; sign-out drops it', () async {
      var session = true;
      final repo = _GatedHistory();
      final cubit = DeclinedOffersCubit(GetDeclinedOffers(repo), () => session);
      addTearDown(cubit.close);

      // Order History never opened: no read.
      await cubit.refresh();
      expect(repo.calls, 0);

      // First load is in flight; the server changes; three invalidations.
      final first = cubit.load();
      repo.records = [const DeclinedOfferRecord(offerId: 'new')];
      await cubit.refresh();
      await cubit.refresh();
      await cubit.refresh();
      expect(repo.calls, 1);
      // The in-flight read answers with the stale (empty) list...
      repo.release([]);
      await pumpEventQueue();
      // ...and exactly one follow-up read starts.
      expect(repo.calls, 2);
      repo.release();
      await first;
      expect(cubit.state.status, DeclinedOffersStatus.loaded);
      expect(cubit.state.records.map((r) => r.offerId), ['new']);
      expect(repo.calls, 2);

      // Settled: one refresh is one read.
      final next = cubit.refresh();
      repo.release();
      await next;
      expect(repo.calls, 3);

      // Sign-out while a refresh runs: the late answer is dropped.
      final late = cubit.refresh();
      await cubit.refresh();
      session = false;
      repo.release();
      await late;
      expect(cubit.state.status, DeclinedOffersStatus.noSession);
      expect(cubit.state.records, isEmpty);
      expect(repo.calls, 4);
    });

    test('PendingOffersCubit: onDeclineConfirmed runs only for a confirmed '
        'decline', () async {
      final offers = FakeOffers([offer('a'), offer('b'), offer('c')]);
      var declines = 0;
      final pending = PendingOffersCubit(
        GetEligibleOffers(offers),
        AcceptOrderOffer(offers),
        DeclineOrderOffer(offers),
        () => true,
        onDeclineConfirmed: () => declines++,
      );
      addTearDown(pending.close);
      await pending.load();
      offers.commandError = const OrderOfferNoLongerAvailableException();
      await pending.decline('a');
      expect(declines, 0);
      offers.commandError = null;
      await pending.decline('b');
      expect(declines, 1);
      await pending.accept('c');
      // An acceptance never triggers the decline callback.
      expect(offers.accepted, ['c']);
      expect(declines, 1);
    });

    testWidgets('a record reads as this captain\'s answer, not a delivery', (
      tester,
    ) async {
      final at = DateTime(2026, 11, 15, 9, 5);
      await tester.pumpWidget(
        testApp(
          DeclinedOfferTile(
            record: DeclinedOfferRecord(
              offerId: 'a',
              merchantName: 'مطعم a',
              kind: OrderOfferKind.instant,
              declinedAt: at,
            ),
          ),
        ),
      );
      expect(find.text('مطعم a'), findsOneWidget);
      expect(
        find.text(l10n.declinedOfferOutcomeWithKind(l10n.offerKindInstant)),
        findsOneWidget,
      );
      expect(find.text(ltrIsolate(formatLocalDateTime(at))), findsOneWidget);
      await tester.pumpWidget(
        testApp(
          const DeclinedOfferTile(record: DeclinedOfferRecord(offerId: 'b')),
        ),
      );
      expect(find.text(l10n.declinedOfferGenericTitle), findsOneWidget);
      expect(find.text(l10n.declinedOfferOutcome), findsOneWidget);
    });
  });

  group('real app', () {
    late FakeOffers offers;
    late FakeActiveOrderRepository orders;
    late FakeAuthRepository auth;

    Future<void> launch(
      WidgetTester tester, {
      List<CaptainOrderOffer>? initial,
      OrderHistoryRepository? history,
    }) async {
      offers = FakeOffers(initial ?? [offer('old')]);
      orders = FakeActiveOrderRepository();
      auth = FakeAuthRepository(hasSession: true);
      await tester.pumpWidget(
        MainApp(
          connectivityService: FakeInternetConnectionService(),
          authRepository: auth,
          orderOfferRepository: offers,
          activeOrderRepository: orders,
          orderHistoryRepository:
              history ?? const OrderHistoryRepositoryPlaceholder(),
        ),
      );
      await tester.pumpAndSettle();
      // Startup resolved the active order once (D-A73); count from here.
      orders.calls = 0;
    }

    // skipOffstage: the shell is offstage under a page pushed above it.
    final navBar = find.byType(AppNavBar, skipOffstage: false);

    PendingOffersCubit cubit(WidgetTester tester) =>
        tester.element(navBar).read<PendingOffersCubit>();

    int branch(WidgetTester tester) =>
        tester.widget<AppNavBar>(navBar).navigationShell.currentIndex;

    Future<void> tapTab(WidgetTester tester, MainNavDestination d) async {
      await tester.tap(find.byKey(MainNavigationBar.itemKey(d)));
      await tester.pumpAndSettle();
    }

    /// A new offer reaches the server list and something (a future push,
    /// Home, resume) makes the shell's Cubit read it.
    Future<void> arrive(WidgetTester tester, CaptainOrderOffer o) async {
      offers.offers = [...offers.offers, o];
      await cubit(tester).load();
      await tester.pumpAndSettle();
    }

    testWidgets('offers already listed when the shell opens get no sheet '
        '(Home shows them)', (tester) async {
      await launch(tester);
      expect(find.byType(AppOrderOfferCard), findsOneWidget);
      expect(sheet, findsNothing);
    });

    testWidgets('the placeholder backend never shows a sheet', (tester) async {
      await tester.pumpWidget(
        MainApp(
          connectivityService: FakeInternetConnectionService(),
          authRepository: FakeAuthRepository(hasSession: true),
        ),
      );
      await tester.pumpAndSettle();
      final c = tester
          .element(find.byType(AppNavBar))
          .read<PendingOffersCubit>();
      await c.load();
      await tester.pumpAndSettle();
      expect(c.state.status, PendingOffersStatus.notConfigured);
      expect(sheet, findsNothing);
    });

    testWidgets('no sheet before sign-in (Login)', (tester) async {
      await tester.pumpWidget(
        MainApp(
          connectivityService: FakeInternetConnectionService(),
          authRepository: FakeAuthRepository(hasSession: false),
          orderOfferRepository: FakeOffers([offer('a')]),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(NewOfferSheetHost), findsNothing);
      expect(sheet, findsNothing);
    });

    for (final d in MainNavDestination.values) {
      testWidgets('a new offer opens one sheet over ${d.name}; closing is '
          'not a decline and it never reopens', (tester) async {
        await launch(tester);
        await tapTab(tester, d);
        await arrive(tester, offer('n1'));
        expect(sheet, findsOneWidget);
        expect(branch(tester), d.index);
        await tester.tap(find.text(l10n.offerLater));
        await tester.pumpAndSettle();
        expect(sheet, findsNothing);
        expect(offers.declined, isEmpty);
        expect(offers.accepted, isEmpty);
        // Tab switches, rebuilds and the same server list: not again.
        await tapTab(tester, MainNavDestination.home);
        await tapTab(tester, d);
        await cubit(tester).load();
        await tester.pumpAndSettle();
        expect(sheet, findsNothing);
        // Still eligible: Home's list (the same Cubit) still has it.
        expect(cubit(tester).state.offers.map((o) => o.id), contains('n1'));
      });
    }

    testWidgets('over a page above the shell too (Current Order)', (
      tester,
    ) async {
      await launch(tester);
      GoRouter.of(
        tester.element(find.byType(AppNavBar)),
      ).push(RoutesString.currentOrder);
      await tester.pumpAndSettle();
      await arrive(tester, offer('n1'));
      expect(sheet, findsOneWidget);
    });

    testWidgets('two new offers: one sheet at a time, then the next', (
      tester,
    ) async {
      await launch(tester);
      offers.offers = [...offers.offers, offer('n1'), offer('n2')];
      await cubit(tester).load();
      await tester.pumpAndSettle();
      expect(sheet, findsOneWidget);
      expect(find.text('مطعم n1'), findsWidgets);
      await tester.tap(find.text(l10n.offerLater));
      await tester.pumpAndSettle();
      expect(sheet, findsOneWidget);
      expect(
        find.descendant(of: sheet, matching: find.text('مطعم n2')),
        findsOneWidget,
      );
      await tester.tap(find.text(l10n.offerLater));
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
    });

    testWidgets('in the background: no sheet; resume re-reads once and '
        'then shows it', (tester) async {
      await launch(tester);
      await tapTab(tester, MainNavDestination.wallet);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await arrive(tester, offer('n1'));
      expect(sheet, findsNothing);
      final before = offers.loadCalls;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(offers.loadCalls, before + 1);
      expect(sheet, findsOneWidget);
    });

    testWidgets('instant accept confirmed for the matching active order → '
        'Current Order; one command for a double tap; no closing meanwhile', (
      tester,
    ) async {
      await launch(tester);
      await tapTab(tester, MainNavDestination.wallet);
      offers.commandPending = Completer();
      offers.onAccepted = (_) => orders.order = const ActiveOrder(
        orderId: 'order-n1',
        restaurantName: 'مطعم n1',
      );
      await arrive(tester, offer('n1'));
      await tester.tap(find.text(l10n.offerAcceptFull));
      await tester.pump();
      await tester.tap(find.text(l10n.offerAcceptFull), warnIfMissed: false);
      await tester.pump();
      // Barrier and back are refused while the command runs.
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(sheet, findsOneWidget);
      expect(branch(tester), MainNavDestination.wallet.index);
      offers.commandPending!.complete();
      await tester.pumpAndSettle();
      expect(offers.accepted, ['n1']);
      expect(sheet, findsNothing);
      // D-A73: the standalone page is pushed above the Wallet tab (no
      // fifth tab); Back returns to the same tab.
      expect(find.byType(CurrentOrderScreen), findsOneWidget);
      expect(find.byType(MainNavigationBar), findsNothing);
      expect(branch(tester), MainNavDestination.wallet.index);
      final current = tester.element(navBar).read<CurrentOrderCubit>().state;
      expect((current as CurrentOrderActive).order.orderId, 'order-n1');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(CurrentOrderScreen), findsNothing);
      expect(branch(tester), MainNavDestination.wallet.index);
    });

    testWidgets('a Home card acceptance confirmed for the matching order also '
        'opens Current Order (same path as the sheet)', (tester) async {
      await launch(
        tester,
        initial: [
          CaptainOrderOffer(
            id: 'h1',
            orderId: 'order-h1',
            merchantName: 'مطعم h1',
            deliveryAreaName: 'ع',
            deliveryFeeFils: 2500,
            commission: const OfferCommissionSnapshot(
              amountFils: 500,
              rateBasisPoints: 2000,
            ),
          ),
        ],
      );
      offers.onAccepted = (_) => orders.order = const ActiveOrder(
        orderId: 'order-h1',
        restaurantName: 'مطعم h1',
      );
      final before = orders.calls;
      await tester.tap(find.text(l10n.offerAccept));
      await tester.pumpAndSettle();
      expect(offers.accepted, ['h1']);
      // A fresh authoritative read after the confirmation.
      expect(orders.calls, greaterThan(before));
      expect(find.byType(CurrentOrderScreen), findsOneWidget);
      // Back: Home, which now offers the way back to the order.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text(l10n.homeActiveOrderOpen), findsOneWidget);
    });

    for (final (name, active, orderId) in [
      (
        'a different active order',
        const ActiveOrder(orderId: 'other', restaurantName: 'آخر'),
        'order-n1',
      ),
      ('no active order', null, 'order-n1'),
      (
        'an offer without an order id',
        const ActiveOrder(orderId: 'order-n1', restaurantName: 'م'),
        null,
      ),
    ]) {
      testWidgets('accept confirmed but $name: popup, no navigation, no '
          'second accept', (tester) async {
        await launch(tester);
        await tapTab(tester, MainNavDestination.orderHistory);
        offers.onAccepted = (_) => orders.order = active;
        final o = CaptainOrderOffer(
          id: 'n1',
          orderId: orderId,
          merchantName: 'مطعم n1',
          deliveryAreaName: 'ع',
          deliveryFeeFils: 2500,
          commission: const OfferCommissionSnapshot(
            amountFils: 500,
            rateBasisPoints: 2000,
          ),
        );
        await arrive(tester, o);
        await tester.tap(find.text(l10n.offerAcceptFull));
        await tester.pumpAndSettle();
        expect(offers.accepted, ['n1']);
        expect(find.byType(AppPopup), findsOneWidget);
        expect(find.text(l10n.offerAcceptedNotOpened), findsOneWidget);
        expect(find.byType(CurrentOrderScreen), findsNothing);
        expect(branch(tester), MainNavDestination.orderHistory.index);
      });
    }

    for (final (error, notice, blocks) in [
      (const OrderOfferNoLongerAvailableException(), 'gone', true),
      (const OrderOfferRefusedException(), 'refused', false),
      (const OrderOfferNetworkUnavailableException(), 'unconfirmed', true),
    ]) {
      testWidgets('accept not confirmed ($notice): sheet stays with the '
          'reason, no navigation', (tester) async {
        await launch(tester);
        await tapTab(tester, MainNavDestination.wallet);
        offers.commandError = error;
        await arrive(tester, offer('n1'));
        await tester.tap(find.text(l10n.offerAcceptFull));
        await tester.pumpAndSettle();
        expect(sheet, findsOneWidget);
        expect(
          find.text(switch (notice) {
            'gone' => l10n.offerNoLongerAvailable,
            'refused' => l10n.offerRefused,
            _ => l10n.offerUnconfirmed,
          }),
          findsOneWidget,
        );
        final accept = tester.widget<AppButton>(
          find.widgetWithText(AppButton, l10n.offerAcceptFull),
        );
        expect(accept.onPressed == null, blocks);
        expect(branch(tester), MainNavDestination.wallet.index);
        expect(orders.calls, 0);
      });
    }

    testWidgets('decline confirmed: sheet closes, the captain stays put, no '
        'history row is invented', (tester) async {
      await launch(tester);
      await tapTab(tester, MainNavDestination.wallet);
      await arrive(tester, offer('n1'));
      await tester.tap(find.text(l10n.offerDeclineFull));
      await tester.pumpAndSettle();
      expect(offers.declined, ['n1']);
      expect(offers.accepted, isEmpty);
      expect(sheet, findsNothing);
      expect(branch(tester), MainNavDestination.wallet.index);
      expect(orders.calls, 0);
      await tapTab(tester, MainNavDestination.orderHistory);
      expect(find.text(l10n.declinedOffersNotConfigured), findsOneWidget);
      expect(find.byType(DeclinedOfferTile), findsNothing);
    });

    // Task 38: a server-confirmed decline from the sheet opened over the
    // visible Order History tab re-reads the history at once; nothing else
    // does.
    testWidgets('decline confirmed while Order History is visible: one '
        're-read, the new record first, no navigation or tab switch', (
      tester,
    ) async {
      final old = DeclinedOfferRecord(
        offerId: 'd1',
        merchantName: 'مطعم d1',
        declinedAt: DateTime.utc(2026, 11, 15, 7),
      );
      final history = FakeHistory(records: [old]);
      await launch(tester, history: history);
      await tapTab(tester, MainNavDestination.orderHistory);
      expect(find.byType(DeclinedOfferTile), findsOneWidget);
      final callsBefore = history.calls;

      // «لاحقاً»: no answer, so no re-read and no row.
      await arrive(tester, offer('n0'));
      await tester.tap(find.text(l10n.offerLater));
      await tester.pumpAndSettle();
      expect(history.calls, callsBefore);

      // An unconfirmed decline: the sheet stays with the reason, the
      // history is not read; then it is closed without an answer.
      offers.commandError = const OrderOfferNetworkUnavailableException();
      await arrive(tester, offer('n1'));
      await tester.tap(find.text(l10n.offerDeclineFull));
      await tester.pumpAndSettle();
      expect(sheet, findsOneWidget);
      expect(find.text(l10n.offerUnconfirmed), findsOneWidget);
      await tester.tap(find.text(l10n.offerLater));
      await tester.pumpAndSettle();
      expect(history.calls, callsBefore);
      expect(find.byType(DeclinedOfferTile), findsOneWidget);

      // Confirmed: the server now records it, and the open tab shows it.
      offers.commandError = null;
      await arrive(tester, offer('n2'));
      history.records = [
        old,
        DeclinedOfferRecord(
          offerId: 'n2',
          merchantName: 'مطعم n2',
          declinedAt: DateTime.utc(2026, 11, 15, 9),
        ),
      ];
      await tester.tap(find.text(l10n.offerDeclineFull));
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      expect(history.calls, callsBefore + 1);
      expect(branch(tester), MainNavDestination.orderHistory.index);
      final tiles = tester
          .widgetList<DeclinedOfferTile>(find.byType(DeclinedOfferTile))
          .map((t) => t.record.offerId);
      expect(tiles, ['n2', 'd1']);
      expect(orders.calls, 0);
    });

    testWidgets('a confirmed accept never re-reads the declined history', (
      tester,
    ) async {
      final history = FakeHistory();
      await launch(tester, history: history);
      await tapTab(tester, MainNavDestination.orderHistory);
      final callsBefore = history.calls;
      await arrive(tester, offer('n1'));
      await tester.tap(find.text(l10n.offerAcceptFull));
      await tester.pumpAndSettle();
      expect(offers.accepted, ['n1']);
      expect(history.calls, callsBefore);
    });

    testWidgets('server-recorded declines appear under «العروض التي '
        'رفضتها»; tab return re-reads', (tester) async {
      final history = FakeHistory(
        records: [
          DeclinedOfferRecord(
            offerId: 'd1',
            merchantName: 'مطعم d1',
            declinedAt: DateTime.utc(2026, 11, 15, 7),
          ),
        ],
      );
      await launch(tester, history: history);
      await tapTab(tester, MainNavDestination.orderHistory);
      expect(find.text(l10n.declinedOffersHeading), findsOneWidget);
      expect(find.byType(DeclinedOfferTile), findsOneWidget);
      expect(find.text('مطعم d1'), findsOneWidget);
      expect(history.calls, 1);
      await tapTab(tester, MainNavDestination.home);
      await tapTab(tester, MainNavDestination.orderHistory);
      expect(history.calls, 2);
    });

    testWidgets('scheduled offer: shown with its type; accept off with the '
        'Admin-confirmation reason; decline still possible', (tester) async {
      await launch(tester);
      await arrive(
        tester,
        offer(
          's1',
          kind: OrderOfferKind.scheduled,
          scheduledPickupAt: DateTime(2026, 11, 16, 13, 30),
        ),
      );
      expect(find.text(l10n.offerKindScheduled), findsOneWidget);
      expect(find.text(l10n.offerScheduledAdminOnly), findsOneWidget);
      AppButton button(String label) =>
          tester.widget<AppButton>(find.widgetWithText(AppButton, label));
      expect(button(l10n.offerAcceptFull).onPressed, isNull);
      expect(button(l10n.offerDeclineFull).onPressed, isNotNull);
      await tester.tap(find.text(l10n.offerAcceptFull), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(offers.accepted, isEmpty);
    });

    testWidgets('missing commission snapshot: accept off with the reason', (
      tester,
    ) async {
      await launch(tester);
      await arrive(tester, offer('m1', commission: null));
      expect(find.text(l10n.offerEarningsMissing), findsOneWidget);
      expect(
        tester
            .widget<AppButton>(
              find.widgetWithText(AppButton, l10n.offerAcceptFull),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('an offer that leaves the server list while open: actions '
        'off, "no longer available"', (tester) async {
      await launch(tester);
      await arrive(tester, offer('n1'));
      offers.offers = [offer('old')];
      await cubit(tester).load();
      await tester.pumpAndSettle();
      expect(sheet, findsOneWidget);
      expect(find.text(l10n.offerNoLongerAvailable), findsOneWidget);
      expect(
        tester
            .widget<AppButton>(
              find.widgetWithText(AppButton, l10n.offerDeclineFull),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('sign-out while a command runs: the sheet is gone, Login '
        'shows, the late answer changes nothing', (tester) async {
      await launch(tester);
      offers.commandPending = Completer();
      await arrive(tester, offer('n1'));
      await tester.tap(find.text(l10n.offerAcceptFull));
      await tester.pump();
      await tester
          .element(find.byType(AppNavBar))
          .read<AppSessionCubit>()
          .endSession();
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
      offers.commandPending!.complete();
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      expect(find.byType(AppPopup), findsNothing);
    });

    testWidgets('Wallet app bar: title text only; no recharge action', (
      tester,
    ) async {
      await launch(tester);
      Future<void> expectTitleOnly() async {
        final bar = find.descendant(
          of: find.byType(WalletScreen),
          matching: find.byType(AppBar),
        );
        expect(tester.widget<AppBar>(bar).title, isA<Text>());
        expect(
          find.descendant(of: bar, matching: find.byType(Icon)),
          findsNothing,
        );
        expect(
          find.descendant(of: bar, matching: find.text(l10n.walletTitle)),
          findsOneWidget,
        );
        expect(tester.widget<AppBar>(bar).actions, isNull);
        // D-A76: the recharge action is gone entirely.
        expect(find.byIcon(Icons.phone_in_talk_outlined), findsNothing);
      }

      await tapTab(tester, MainNavDestination.wallet);
      await expectTitleOnly();
    });
  });

  group('CurrentOrderCubit.refreshed (coalesced recovery, D-A73)', () {
    CurrentOrderCubit build(ActiveOrderRepository repo) {
      final cubit = CurrentOrderCubit(
        GetActiveOrder(repo),
        GetCaptainLocation(FakeCaptainLocationRepository()),
      );
      addTearDown(cubit.close);
      return cubit;
    }

    test('a request during a running lookup gets exactly one fresh '
        'follow-up and its settled answer', () async {
      final repo = FakeActiveOrderRepository(order: testActiveOrder)
        ..pending = Completer();
      final cubit = build(repo);
      unawaited(cubit.load());
      final a = cubit.refreshed();
      final b = cubit.refreshed();
      repo.pending!.complete();
      expect(await a, isA<CurrentOrderActive>());
      expect(await b, isA<CurrentOrderActive>());
      // One running lookup + one coalesced follow-up, not one per caller.
      expect(repo.calls, 2);
    });

    test('an older "none" cannot hide an order accepted meanwhile', () async {
      final repo = _SequencedOrders();
      final cubit = build(repo);
      unawaited(cubit.load()); // started before the acceptance
      final accepted = cubit.refreshed(); // after a confirmed acceptance
      repo.answer(null); // the older lookup still says "none"
      await Future<void>.delayed(Duration.zero);
      expect(repo.pendingCalls, 1); // the fresh follow-up is running
      repo.answer(testActiveOrder);
      final state = await accepted;
      expect(state, isA<CurrentOrderActive>());
      expect(cubit.state, isA<CurrentOrderActive>());
    });

    test('a confirmed absence replaces a previous active order', () async {
      final repo = FakeActiveOrderRepository(order: testActiveOrder);
      final cubit = build(repo);
      expect(await cubit.refreshed(), isA<CurrentOrderActive>());
      repo.order = null; // completed or reassigned elsewhere
      expect(await cubit.refreshed(), isA<CurrentOrderEmpty>());
    });

    test('a failure is never "none"', () async {
      final repo = FakeActiveOrderRepository()
        ..error = const OrderNetworkUnavailableException();
      final cubit = build(repo);
      final state = await cubit.refreshed();
      expect(state, isA<CurrentOrderFailure>());
      expect(state, isNot(isA<CurrentOrderEmpty>()));
    });

    test('reset (sign-out) drops a running lookup and returns null', () async {
      final repo = FakeActiveOrderRepository(order: testActiveOrder)
        ..pending = Completer();
      final cubit = build(repo);
      final answer = cubit.refreshed();
      cubit.reset();
      repo.pending!.complete();
      expect(await answer, isNull);
      expect(cubit.state, isA<CurrentOrderInitial>());
    });
  });

  group('design preview', () {
    testWidgets('opens the real sheet with sample data and the app gating', (
      tester,
    ) async {
      await tester.pumpWidget(
        const NewOfferSheetPreviewApp(autoOpen: OrderOfferKind.scheduled),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.previewCaption), findsOneWidget);
      expect(sheet, findsOneWidget);
      expect(find.text(l10n.offerScheduledAdminOnly), findsOneWidget);
    });

    test('nothing in the app imports the preview', () {
      final imports = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.contains('lib/preview/'))
          .where(
            (f) => f.readAsStringSync().contains(
              'preview/new_offer_sheet_preview.dart',
            ),
          );
      expect(imports, isEmpty);
    });
  });
}

/// Answers each active-order lookup only when the test calls [answer], in
/// order, so the race between an older lookup and a newer one can be
/// staged exactly.
class _SequencedOrders implements ActiveOrderRepository {
  final List<Completer<ActiveOrder?>> _calls = [];

  void answer(ActiveOrder? order) =>
      _calls.firstWhere((c) => !c.isCompleted).complete(order);

  int get pendingCalls => _calls.where((c) => !c.isCompleted).length;

  @override
  Future<ActiveOrder?> getActiveOrder() {
    final call = Completer<ActiveOrder?>();
    _calls.add(call);
    return call.future;
  }
}
