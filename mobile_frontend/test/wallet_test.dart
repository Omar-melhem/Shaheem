// Wallet (client revision D-A74–D-A76): the single balance (no holds),
// the 7-day commission-debit display window, the two lifetime metric
// cards with independent states, the removed recharge UI, Wallet
// navigation through the real app and the Home chip from the same balance.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_frontend/data/repositories/wallet_repository_placeholder.dart';
import 'package:mobile_frontend/domain/entities/wallet.dart';
import 'package:mobile_frontend/domain/errors/wallet_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/wallet_repository.dart';
import 'package:mobile_frontend/domain/use_cases/get_wallet.dart';
import 'package:mobile_frontend/helper/date/date_time_format.dart';
import 'package:mobile_frontend/helper/money/jod_format.dart';
import 'package:mobile_frontend/main.dart';
import 'package:mobile_frontend/preview/wallet_preview.dart';
import 'package:mobile_frontend/util/fonts.dart';
import 'package:mobile_frontend/util/routes/routes_string.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';
import 'package:mobile_frontend/view/navigation/app_nav_bar.dart';
import 'package:mobile_frontend/view/screens/home_screen/widget/wallet_balance_chip.dart';
import 'package:mobile_frontend/view/screens/wallet_screen/cubit/wallet_cubit.dart';
import 'package:mobile_frontend/view/screens/wallet_screen/view/wallet_screen.dart';
import 'package:mobile_frontend/view/screens/wallet_screen/widget/wallet_debit_card.dart';
import 'package:mobile_frontend/view/screens/wallet_screen/widget/wallet_metric_cards.dart';
import 'package:mobile_frontend/view/widget/navigation/main_nav_destination.dart';
import 'package:mobile_frontend/view/widget/navigation/main_navigation_bar.dart';
import 'package:mobile_frontend/view/widget/pop_up_screen/app_popup.dart';

import 'fakes.dart';
import 'test_app.dart';

/// Wallet and statistics source whose answers each test controls (test
/// data only).
class FakeWalletRepository implements WalletRepository {
  FakeWalletRepository({this.overview, this.error, this.statistics});

  WalletOverview? overview;
  Object? error;
  Completer<WalletOverview>? pending;
  int calls = 0;
  DateTime? lastSince;

  CaptainDeliveryStatistics? statistics;
  Object? statisticsError;
  Completer<CaptainDeliveryStatistics>? statisticsPending;
  int statisticsCalls = 0;

  @override
  Future<WalletOverview> getWallet({required DateTime historySinceUtc}) async {
    calls++;
    lastSince = historySinceUtc;
    if (pending != null) return pending!.future;
    if (error != null) throw error!;
    return overview!;
  }

  @override
  Future<CaptainDeliveryStatistics> getDeliveryStatistics() async {
    statisticsCalls++;
    if (statisticsPending != null) return statisticsPending!.future;
    if (statisticsError != null) throw statisticsError!;
    final s = statistics;
    if (s == null) throw const WalletBackendNotConfiguredException();
    return s;
  }
}

final now = DateTime.utc(2026, 11, 15, 12);

WalletCommissionDebit debit(
  int i, {
  DateTime? at,
  String? merchant = 'مطعم السنابل',
  String? area = 'تلاع العلي',
  int fils = 500,
}) => WalletCommissionDebit(
  id: 'd$i',
  debitedAt: at ?? now.subtract(Duration(hours: i)),
  commissionFils: fils,
  merchantName: merchant,
  deliveryAreaName: area,
);

WalletOverview overview({
  int balance = 4000,
  List<WalletCommissionDebit>? debits,
}) => WalletOverview(
  summary: WalletSummary(balanceFils: balance),
  debits: debits ?? [debit(1)],
);

/// The currency symbol as the app shows it.
String walletCurrency() => l10n.walletCurrencySymbol;

String money(int fils) =>
    '${ltrIsolate(formatJodFils(fils))} ${walletCurrency()}';

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

  group('model: one balance, no holds (D-A74)', () {
    test('WalletSummary carries only the balance', () {
      final src = File('lib/domain/entities/wallet.dart').readAsStringSync();
      for (final retired in [
        'heldFils',
        'availableFils',
        'totalFils',
        'WalletCredit',
      ]) {
        expect(src.contains(retired), isFalse, reason: retired);
      }
      expect(const WalletSummary(balanceFils: -1000).balanceFils, -1000);
    });

    test('no hold-derived or recharge-UI symbols remain in live code', () {
      final files = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.contains('generated'));
      for (final f in files) {
        final src = f.readAsStringSync();
        for (final retired in [
          'heldFils',
          'availableFils',
          'RechargeContact',
          'showRechargeContactPopup',
          'WalletCreditCard',
          'walletRechargeRequest',
        ]) {
          expect(src.contains(retired), isFalse, reason: '${f.path}: $retired');
        }
      }
      expect(
        File('lib/helper/contact/recharge_contact.dart').existsSync(),
        isFalse,
      );
      expect(
        File(
          'lib/view/screens/wallet_screen/widget/recharge_contact_popup.dart',
        ).existsSync(),
        isFalse,
      );
    });
  });

  group('GetWallet: last 7 days of commission debits', () {
    Future<WalletOverview> run(WalletOverview o, {DateTime? at}) async {
      final repo = FakeWalletRepository(overview: o);
      final result = await GetWallet(repo, now: () => at ?? now)();
      expect(repo.lastSince, (at ?? now).subtract(const Duration(days: 7)));
      return (result as WalletLoaded).overview;
    }

    test('start inclusive, just outside excluded, future excluded, newest '
        'first, balance untouched', () async {
      final start = now.subtract(const Duration(days: 7));
      final o = await run(
        overview(
          balance: -1500,
          debits: [
            debit(1, at: start), // boundary: shown
            debit(2, at: start.subtract(const Duration(seconds: 1))),
            debit(3, at: now.subtract(const Duration(hours: 1))),
            debit(4, at: now.add(const Duration(minutes: 5))), // future
            debit(5, at: now.subtract(const Duration(days: 8))),
          ],
        ),
      );
      expect(o.debits.map((d) => d.id), ['d3', 'd1']);
      expect(o.summary.balanceFils, -1500);
    });

    test(
      'compares instants, not local dates (Amman offset, new year)',
      () async {
        final newYear = DateTime.utc(2027, 1, 2, 0, 30);
        final o = await run(
          overview(
            debits: [
              debit(1, at: DateTime.utc(2026, 12, 25, 22)),
              debit(2, at: DateTime.utc(2026, 12, 26, 0, 30)), // boundary
              debit(3, at: DateTime.utc(2026, 12, 31, 23, 59)),
            ],
          ),
          at: newYear,
        );
        expect(o.debits.map((d) => d.id), ['d3', 'd2']);
      },
    );

    test('failures map to typed results; nothing is invented', () async {
      Future<WalletResult> with_(Object error) =>
          GetWallet(FakeWalletRepository(error: error), now: () => now)();
      expect(
        await with_(const WalletBackendNotConfiguredException()),
        isA<WalletNotConfigured>(),
      );
      expect(
        await with_(const WalletNetworkUnavailableException()),
        isA<WalletNoInternet>(),
      );
      expect(await with_(StateError('x')), isA<WalletFailure>());
      expect(
        await GetWallet(const WalletRepositoryPlaceholder())(),
        isA<WalletNotConfigured>(),
      );
    });

    test('local date/time: yyyy/MM/dd HH:mm, Western digits', () {
      expect(
        formatLocalDateTime(DateTime(2026, 1, 5, 9, 7)),
        '2026/01/05 09:07',
      );
    });
  });

  group('GetDeliveryStatistics: lifetime, typed outcomes (D-A76)', () {
    test('loaded passes the server values through; earnings may be '
        'unavailable (null), never zero', () async {
      final repo = FakeWalletRepository(
        statistics: const CaptainDeliveryStatistics(deliveredCount: 3),
      );
      final r = await GetDeliveryStatistics(repo)();
      final s = (r as DeliveryStatisticsLoaded).statistics;
      expect(s.deliveredCount, 3);
      expect(s.earningsFils, isNull);
    });

    test(
      'failures stay distinct; the placeholder says not configured',
      () async {
        Future<DeliveryStatisticsResult> with_(Object e) =>
            GetDeliveryStatistics(
              FakeWalletRepository()..statisticsError = e,
            )();
        expect(
          await with_(const WalletNetworkUnavailableException()),
          isA<DeliveryStatisticsNoInternet>(),
        );
        expect(await with_(StateError('x')), isA<DeliveryStatisticsFailure>());
        expect(
          await GetDeliveryStatistics(const WalletRepositoryPlaceholder())(),
          isA<DeliveryStatisticsNotConfigured>(),
        );
      },
    );
  });

  group('WalletCubit', () {
    WalletCubit build(FakeWalletRepository repo, {bool Function()? session}) {
      final cubit = WalletCubit(
        GetWallet(repo, now: () => now),
        GetDeliveryStatistics(repo),
        session ?? () => true,
      );
      addTearDown(cubit.close);
      return cubit;
    }

    // R02 (API-05): one shared, session-safe source for Home and Wallet.
    group('shared source (R02)', () {
      WalletCubit owned(FakeWalletRepository repo, Object? Function() owner) {
        final cubit = WalletCubit(
          GetWallet(repo, now: () => now),
          GetDeliveryStatistics(repo),
          () => owner() != null,
          sessionOwner: owner,
        );
        addTearDown(cubit.close);
        return cubit;
      }

      test('loadBalance reads only the balance; ensureLoaded then reads '
          'only the statistics', () async {
        final repo = FakeWalletRepository(
          overview: overview(),
          statistics: const CaptainDeliveryStatistics(deliveredCount: 2),
        );
        final cubit = owned(repo, () => 'a');
        await cubit.loadBalance();
        expect((repo.calls, repo.statisticsCalls), (1, 0));
        expect(cubit.state.balanceFils, 4000);
        await cubit.ensureLoaded();
        expect((repo.calls, repo.statisticsCalls), (1, 1));
        await cubit.ensureLoaded();
        expect((repo.calls, repo.statisticsCalls), (1, 1));
      });

      test('overlapping triggers send one read', () async {
        final repo = FakeWalletRepository(overview: overview())
          ..pending = Completer<WalletOverview>();
        final cubit = owned(repo, () => 'a');
        final first = cubit.loadBalance();
        unawaited(cubit.loadBalance());
        unawaited(cubit.ensureLoaded());
        repo.pending!.complete(overview());
        await first;
        expect(repo.calls, 1);
      });

      for (final (label, fils) in [
        ('zero', 0),
        ('negative', -1000),
        ('over the 5,000 ceiling', 6200),
      ]) {
        test('$label is kept exactly as returned', () async {
          final repo = FakeWalletRepository(overview: overview(balance: fils));
          final cubit = owned(repo, () => 'a');
          await cubit.loadBalance();
          expect(cubit.state.balanceFils, fils);
        });
      }

      test('unknown is null, never a substitute zero', () async {
        final repo = FakeWalletRepository(
          error: const WalletServiceUnavailableException(),
        );
        final cubit = owned(repo, () => 'a');
        expect(cubit.state.balanceFils, isNull);
        await cubit.loadBalance();
        expect(cubit.state.status, WalletStatus.failure);
        expect(cubit.state.balanceFils, isNull);
      });

      test('an old captain\'s late answer is dropped after an account '
          'replacement, and the new captain is read', () async {
        Object? owner = 'a';
        final repo = FakeWalletRepository(overview: overview(balance: 4000))
          ..pending = Completer<WalletOverview>();
        final cubit = owned(repo, () => owner);
        final stale = cubit.loadBalance();

        owner = 'b';
        final oldAnswer = repo.pending!;
        repo.pending = null;
        repo.overview = overview(balance: 1200);
        await cubit.syncSession();
        expect(cubit.state.balanceFils, 1200);

        oldAnswer.complete(overview(balance: 4000));
        await stale;
        expect(cubit.state.balanceFils, 1200);
        expect(repo.calls, 2);
      });

      test('an owner change clears values before any new read finishes', () {
        Object? owner = 'a';
        final repo = FakeWalletRepository(overview: overview());
        final cubit = owned(repo, () => owner);
        return cubit.loadBalance().then((_) {
          expect(cubit.state.balanceFils, 4000);
          owner = 'b';
          repo.pending = Completer<WalletOverview>();
          unawaited(cubit.syncSession());
          expect(cubit.state.balanceFils, isNull);
          expect(cubit.state.status, WalletStatus.loading);
        });
      });

      test('sign-out clears everything and reads nothing', () async {
        Object? owner = 'a';
        final repo = FakeWalletRepository(overview: overview());
        final cubit = owned(repo, () => owner);
        await cubit.loadBalance();
        owner = null;
        await cubit.syncSession();
        expect(cubit.state.status, WalletStatus.noSession);
        expect(cubit.state.balanceFils, isNull);
        expect(repo.calls, 1);
      });

      test('the same owner re-emitted does not reset or re-read', () async {
        final repo = FakeWalletRepository(overview: overview());
        final cubit = owned(repo, () => 'a');
        await cubit.loadBalance();
        await cubit.syncSession();
        expect(cubit.state.balanceFils, 4000);
        expect(repo.calls, 1);
      });
    });

    test('no session: nothing is read', () async {
      final repo = FakeWalletRepository(overview: overview());
      final cubit = build(repo, session: () => false);
      await cubit.load();
      expect(cubit.state.status, WalletStatus.noSession);
      expect(cubit.state.statisticsStatus, WalletStatus.noSession);
      expect(repo.calls + repo.statisticsCalls, 0);
    });

    test(
      'a statistics failure never clears the balance, and vice versa',
      () async {
        final repo = FakeWalletRepository(overview: overview(balance: 4000))
          ..statisticsError = const WalletServiceUnavailableException();
        final cubit = build(repo);
        await cubit.load();
        expect(cubit.state.status, WalletStatus.loaded);
        expect(cubit.state.overview!.summary.balanceFils, 4000);
        expect(cubit.state.statisticsStatus, WalletStatus.failure);
        expect(cubit.state.statistics, isNull);
        expect(cubit.state.canRetryStatistics, isTrue);

        repo
          ..statisticsError = null
          ..statistics = const CaptainDeliveryStatistics(deliveredCount: 9)
          ..error = const WalletServiceUnavailableException();
        await cubit.load();
        expect(cubit.state.status, WalletStatus.failure);
        expect(cubit.state.overview, isNull);
        expect(cubit.state.statisticsStatus, WalletStatus.loaded);
        expect(cubit.state.statistics!.deliveredCount, 9);
      },
    );

    test('retryStatistics reads only the statistics', () async {
      final repo = FakeWalletRepository(overview: overview())
        ..statisticsError = const WalletNetworkUnavailableException();
      final cubit = build(repo);
      await cubit.load();
      repo
        ..statisticsError = null
        ..statistics = const CaptainDeliveryStatistics(deliveredCount: 1);
      await cubit.retryStatistics();
      expect(repo.calls, 1);
      expect(repo.statisticsCalls, 2);
      expect(cubit.state.statisticsStatus, WalletStatus.loaded);
    });

    test('a load while one runs sends nothing; a late answer after sign-out '
        'is dropped', () async {
      var signedIn = true;
      final repo = FakeWalletRepository(overview: overview())
        ..pending = Completer();
      final cubit = build(repo, session: () => signedIn);
      unawaited(cubit.load());
      unawaited(cubit.load());
      expect(repo.calls, 1);
      signedIn = false;
      repo.pending!.complete(overview());
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.status, WalletStatus.noSession);
      expect(cubit.state.overview, isNull);
    });
  });

  group('Wallet screen', () {
    late FakeWalletRepository repo;

    Future<void> pumpWallet(
      WidgetTester tester, {
      WalletOverview? data,
      Object? error,
      CaptainDeliveryStatistics? statistics,
      Object? statisticsError,
    }) async {
      repo = FakeWalletRepository(
        overview: data,
        error: error,
        statistics: statistics,
      )..statisticsError = statisticsError;
      final cubit = WalletCubit(
        GetWallet(repo, now: () => now),
        GetDeliveryStatistics(repo),
        () => true,
      );
      addTearDown(cubit.close);
      await tester.pumpWidget(
        testApp(BlocProvider.value(value: cubit, child: const WalletScreen())),
      );
      await tester.pumpAndSettle();
    }

    final metricCards = find.byType(WalletMetricCards);

    testWidgets('not configured: «—» balance and metrics, truthful lines, no '
        'list, no recharge action anywhere', (tester) async {
      await pumpWallet(
        tester,
        error: const WalletBackendNotConfiguredException(),
      );
      expect(find.text(l10n.walletBalanceUnknownValue), findsNWidgets(3));
      expect(find.textContaining('0.000'), findsNothing);
      expect(find.text(l10n.walletNotConfigured), findsOneWidget);
      expect(find.text(l10n.walletMetricsNotConfigured), findsNWidgets(2));
      expect(find.byType(WalletDebitCard), findsNothing);
      // D-A76: no recharge button, popup, selector or credit list.
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.byIcon(Icons.phone_in_talk_outlined), findsNothing);
      expect(find.byType(AppPopup), findsNothing);
    });

    for (final balance in [0, -1000, 4000, 5000, 7250]) {
      testWidgets('balance $balance fils shown exactly (no clamp, sign kept)', (
        tester,
      ) async {
        await pumpWallet(tester, data: overview(balance: balance));
        expect(find.text(money(balance)), findsOneWidget);
      });
    }

    testWidgets('exactly two metric cards: lifetime delivered count; earnings '
        'unavailable until the formula exists (D-P36)', (tester) async {
      await pumpWallet(
        tester,
        data: overview(),
        statistics: const CaptainDeliveryStatistics(deliveredCount: 42),
      );
      expect(
        find.descendant(of: metricCards, matching: find.byType(Semantics)),
        findsWidgets,
      );
      expect(find.text(l10n.walletDeliveredCount), findsOneWidget);
      expect(find.text(l10n.walletEarnings), findsOneWidget);
      expect(find.text(ltrIsolate('42')), findsOneWidget);
      expect(find.text(l10n.walletMetricsLifetimeNote), findsOneWidget);
      expect(find.text(l10n.walletEarningsUnavailable), findsOneWidget);
      // Earnings never read as zero.
      expect(find.text(money(0)), findsNothing);
    });

    testWidgets('statistics failure: Retry on the metrics; the balance and '
        'debits stay', (tester) async {
      await pumpWallet(
        tester,
        data: overview(balance: 3500),
        statisticsError: const WalletServiceUnavailableException(),
      );
      expect(find.text(money(3500)), findsOneWidget);
      expect(find.byType(WalletDebitCard), findsOneWidget);
      expect(find.text(l10n.walletMetricsLoadFailed), findsNWidgets(2));
      repo
        ..statisticsError = null
        ..statistics = const CaptainDeliveryStatistics(deliveredCount: 5);
      await tester.tap(
        find.descendant(of: metricCards, matching: find.text(l10n.retry)),
      );
      await tester.pumpAndSettle();
      expect(find.text(ltrIsolate('5')), findsOneWidget);
      expect(repo.calls, 1);
    });

    testWidgets('debit card: merchant, area, date and the commission (never '
        'the fee); missing fields say «غير متوفر»', (tester) async {
      final at = DateTime.utc(2026, 11, 14, 7, 5);
      await pumpWallet(
        tester,
        data: overview(
          debits: [
            debit(1, at: at, fils: 600),
            debit(2, at: at, merchant: null, area: ' '),
          ],
        ),
      );
      final date = ltrIsolate(formatLocalDateTime(at));
      expect(find.text(l10n.walletDebitHistory), findsOneWidget);
      expect(
        find.text(l10n.walletDebitMerchantLine('مطعم السنابل')),
        findsOneWidget,
      );
      expect(find.text(l10n.walletDebitDateLine(date)), findsNWidgets(2));
      expect(
        find.text(
          l10n.walletDebitAmountLine(
            ltrIsolate(formatJodFils(600)),
            walletCurrency(),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text(l10n.walletDebitMerchantLine(l10n.walletFieldUnavailable)),
        findsOneWidget,
      );
    });

    testWidgets('confirmed empty history differs from not configured', (
      tester,
    ) async {
      await pumpWallet(tester, data: overview(debits: const []));
      expect(find.text(l10n.walletDebitsEmpty), findsOneWidget);
      expect(find.text(l10n.walletNotConfigured), findsNothing);
    });

    testWidgets('network failure: message and Retry that reloads', (
      tester,
    ) async {
      await pumpWallet(
        tester,
        error: const WalletNetworkUnavailableException(),
      );
      expect(find.text(l10n.walletNoInternet), findsWidgets);
      repo
        ..error = null
        ..overview = overview(balance: 1250);
      await tester.tap(find.text(l10n.retry).last);
      await tester.pumpAndSettle();
      expect(find.text(money(1250)), findsOneWidget);
    });

    testWidgets('one screen-reader summary for the balance', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpWallet(tester, data: overview(balance: 4000));
      expect(
        find.bySemanticsLabel(
          l10n.walletBalanceCardSemantics('4.000 ${walletCurrency()}'),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    for (final width in [320.0, 375.0, 450.0]) {
      for (final scale in [1.0, 2.0, 3.0]) {
        testWidgets('$width px × $scale: large amounts and Arabic wrap, no '
            'overflow; metric cards stack when narrow', (tester) async {
          setScreenSize(tester, width, 800);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await pumpWallet(
            tester,
            data: overview(
              balance: -987654321,
              debits: [
                debit(
                  1,
                  merchant: 'مخبز وحلويات الياسمين الشرقية للمناسبات والأفراح',
                  area: 'دابوق — الحي الغربي قرب المدارس الخاصة والحديقة',
                ),
              ],
            ),
            statistics: const CaptainDeliveryStatistics(deliveredCount: 12345),
          );
          expect(tester.takeException(), isNull);
          for (final p in tester.renderObjectList<RenderParagraph>(
            find.byType(RichText),
          )) {
            expect(p.didExceedMaxLines, isFalse);
          }
        });
      }
    }
  });

  group('navigation through the real app', () {
    late FakeWalletRepository repo;

    Future<void> launch(WidgetTester tester, {bool signedIn = true}) async {
      repo = FakeWalletRepository(
        overview: overview(),
        statistics: const CaptainDeliveryStatistics(deliveredCount: 3),
      );
      await tester.pumpWidget(
        MainApp(
          connectivityService: FakeInternetConnectionService(),
          authRepository: FakeAuthRepository(hasSession: signedIn),
          walletRepository: repo,
        ),
      );
      await tester.pumpAndSettle();
    }

    int branch(WidgetTester tester) => tester
        .widget<AppNavBar>(find.byType(AppNavBar))
        .navigationShell
        .currentIndex;

    Finder tab(MainNavDestination d) =>
        find.byKey(MainNavigationBar.itemKey(d));

    testWidgets('Wallet is tab 3 of 4 (D-A70)', (tester) async {
      await launch(tester);
      expect(MainNavDestination.wallet.index, 2);
      expect(MainNavDestination.values.length, 4);
    });

    testWidgets('Home balance chip (shared balance) → the Wallet tab; the bar '
        'tab → the same Wallet; never two Wallet pages', (tester) async {
      await launch(tester);
      // R02: the shell read the balance once; Home never reads statistics.
      expect(
        find.bySemanticsLabel(l10n.walletBalanceSemantics(formatJodFils(4000))),
        findsOneWidget,
      );
      expect(repo.calls, 1);
      expect(repo.statisticsCalls, 0);
      await tester.tap(find.byType(WalletBalanceChip));
      await tester.pumpAndSettle();
      expect(branch(tester), MainNavDestination.wallet.index);
      final first = tester.state(find.byType(WalletScreen));
      // Wallet's first show reads only what was still unread.
      expect(repo.calls, 1);
      expect(repo.statisticsCalls, 1);

      await tester.tap(tab(MainNavDestination.home));
      await tester.pumpAndSettle();
      await tester.tap(tab(MainNavDestination.wallet));
      await tester.pumpAndSettle();
      expect(identical(tester.state(find.byType(WalletScreen)), first), isTrue);
      expect(find.byType(WalletScreen, skipOffstage: false), findsOneWidget);
      expect(repo.calls, 2);
      expect(repo.statisticsCalls, 2);
    });

    testWidgets('R02: a statistics failure on Wallet leaves the Home chip '
        'and the Wallet balance in agreement', (tester) async {
      await launch(tester);
      repo.statisticsError = const WalletServiceUnavailableException();
      await tester.tap(tab(MainNavDestination.wallet));
      await tester.pumpAndSettle();
      final cubit = BlocProvider.of<WalletCubit>(
        tester.element(find.byType(WalletScreen)),
      );
      expect(cubit.state.statisticsStatus, WalletStatus.failure);
      expect(cubit.state.balanceFils, 4000);
      await tester.tap(tab(MainNavDestination.home));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(l10n.walletBalanceSemantics(formatJodFils(4000))),
        findsOneWidget,
      );
    });

    testWidgets('R02: an unreadable wallet shows «—» on Home, never zero', (
      tester,
    ) async {
      repo = FakeWalletRepository(
        error: const WalletServiceUnavailableException(),
      );
      await tester.pumpWidget(
        MainApp(
          connectivityService: FakeInternetConnectionService(),
          authRepository: FakeAuthRepository(hasSession: true),
          walletRepository: repo,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.walletBalanceUnknownValue), findsOneWidget);
      expect(
        find.bySemanticsLabel(l10n.walletBalanceUnavailableSemantics),
        findsOneWidget,
      );
    });

    testWidgets('R02: sign-out closes the shared source with the shell and '
        'reads nothing more', (tester) async {
      await launch(tester);
      expect(repo.calls, 1);
      final session = BlocProvider.of<AppSessionCubit>(
        tester.element(find.byType(AppNavBar)),
      );
      await session.endSession();
      await tester.pumpAndSettle();
      expect(find.byType(AppNavBar), findsNothing);
      expect(repo.calls, 1);
    });

    testWidgets('Wallet app bar: text title, no actions', (tester) async {
      await launch(tester);
      await tester.tap(tab(MainNavDestination.wallet));
      await tester.pumpAndSettle();
      final walletBar = find.descendant(
        of: find.byType(WalletScreen),
        matching: find.byType(AppBar),
      );
      expect(tester.widget<AppBar>(walletBar).actions, isNull);
      expect(
        find.descendant(of: walletBar, matching: find.byType(IconButton)),
        findsNothing,
      );
    });

    testWidgets('deep link /wallet selects the Wallet tab', (tester) async {
      await launch(tester);
      GoRouter.of(
        tester.element(find.byType(AppNavBar)),
      ).go(RoutesString.wallet);
      await tester.pumpAndSettle();
      expect(branch(tester), MainNavDestination.wallet.index);
    });

    testWidgets('sign-out from Wallet, then a new session: no previous '
        'captain balance; a late answer is dropped', (tester) async {
      await launch(tester);
      await tester.tap(tab(MainNavDestination.wallet));
      await tester.pumpAndSettle();
      expect(find.textContaining(formatJodFils(4000)), findsOneWidget);
      repo.pending = Completer();
      await tester.tap(tab(MainNavDestination.home));
      await tester.pumpAndSettle();
      await tester.tap(tab(MainNavDestination.wallet));
      await tester.pump();
      final session = tester
          .element(find.byType(WalletScreen))
          .read<AppSessionCubit>();
      await session.endSession();
      await tester.pumpAndSettle();
      repo.pending!.complete(overview(balance: 99000));
      repo.pending = null;
      await tester.pumpAndSettle();

      repo.overview = overview(balance: 1700);
      session.authenticate(testUser, session.beginAttempt());
      await tester.pumpAndSettle();
      await tester.tap(tab(MainNavDestination.wallet));
      await tester.pumpAndSettle();
      expect(find.textContaining(formatJodFils(1700)), findsOneWidget);
      expect(find.textContaining(formatJodFils(4000)), findsNothing);
      expect(find.textContaining(formatJodFils(99000)), findsNothing);
    });

    testWidgets('debug preview (no session): Wallet reads nothing and says '
        'so', (tester) async {
      await launch(tester, signedIn: false);
      final button = find.text(l10n.debugPreviewButton);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.tap(tab(MainNavDestination.wallet));
      await tester.pumpAndSettle();
      expect(repo.calls + repo.statisticsCalls, 0);
      expect(find.text(l10n.walletNoSession), findsWidgets);
    });
  });

  group('design preview', () {
    testWidgets('renders the real Wallet screen with labelled sample data', (
      tester,
    ) async {
      await tester.pumpWidget(const WalletPreviewApp());
      await tester.pumpAndSettle();
      expect(find.text(l10n.previewCaption), findsOneWidget);
      expect(find.byType(WalletScreen), findsOneWidget);
      expect(find.byType(WalletDebitCard), findsWidgets);
      expect(find.text(l10n.walletEarningsUnavailable), findsOneWidget);
    });

    test('the preview is not imported by the app', () {
      final appFiles = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.contains('${Platform.pathSeparator}preview'));
      for (final f in appFiles) {
        expect(
          f.readAsStringSync().contains('preview/wallet_preview.dart'),
          isFalse,
          reason: f.path,
        );
      }
    });
  });

  group('Home app bar sizes (real font)', () {
    for (final width in [320.0, 375.0, 450.0]) {
      for (final scale in [1.0, 2.0, 3.0]) {
        for (final fils in [null, -12345678]) {
          testWidgets('$width px × $scale, balance $fils: chip reachable, '
              'amount not clipped', (tester) async {
            setScreenSize(tester, width, 800);
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            await tester.pumpWidget(
              testApp(
                Scaffold(
                  body: Column(
                    children: [
                      Builder(
                        builder: (context) => _HomeBarHarness(fils: fils),
                      ),
                    ],
                  ),
                ),
              ),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
            final screen = Offset.zero & Size(width, 800);
            final chip = tester.getRect(find.byType(WalletBalanceChip));
            expect(screen.contains(chip.topLeft), isTrue);
            expect(
              screen.contains(chip.bottomRight - const Offset(1, 1)),
              isTrue,
            );
            for (final p in tester.renderObjectList<RenderParagraph>(
              find.descendant(
                of: find.byType(WalletBalanceChip),
                matching: find.byType(RichText),
              ),
            )) {
              expect(p.didExceedMaxLines, isFalse);
              expect(p.size.width, lessThanOrEqualTo(chip.width));
            }
          });
        }
      }
    }
  });
}

/// The Home AppBar's balance chip on its own (the full bar, with the
/// availability Cubit, is covered by `home_screen_test.dart`).
class _HomeBarHarness extends StatelessWidget {
  const _HomeBarHarness({required this.fils});

  final int? fils;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Wrap(
      children: [WalletBalanceChip(balanceFils: fils, onPressed: () {})],
    ),
  );
}
