// Home architecture (Task 27): file boundaries, one load per mount and per
// resume, and rebuild scope of the Home sections.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_frontend/domain/entities/app_user.dart';
import 'package:mobile_frontend/domain/entities/order_offer.dart';
import 'package:mobile_frontend/domain/repositories/order_offer_repository.dart';
import 'package:mobile_frontend/domain/use_cases/captain_availability.dart';
import 'package:mobile_frontend/domain/use_cases/order_offers.dart';
import 'package:mobile_frontend/domain/use_cases/sign_out.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';
import 'package:mobile_frontend/view/screens/home_screen/cubit/home_availability_cubit.dart';
import 'package:mobile_frontend/view/screens/home_screen/cubit/pending_offers_cubit.dart';
import 'package:mobile_frontend/view/screens/home_screen/view/home_screen.dart';
import 'package:mobile_frontend/view/widget/order/app_order_offer_card.dart';
import 'package:mobile_frontend/view/widget/toggle/app_availability_toggle.dart';

import 'availability_fakes.dart';
import 'fakes.dart';
import 'test_app.dart';

/// Offers source that counts loads.
class CountingOfferRepository implements OrderOfferRepository {
  CountingOfferRepository(this.offers);

  List<CaptainOrderOffer> offers;
  int loadCalls = 0;

  @override
  Future<List<CaptainOrderOffer>> getEligibleOffers() async {
    loadCalls++;
    return [...offers];
  }

  @override
  Future<void> acceptOffer(String offerId) async {}

  @override
  Future<void> declineOffer(String offerId) async {}
}

CaptainOrderOffer offer(int i) => CaptainOrderOffer(
  id: 'offer-$i',
  merchantName: 'مطعم $i',
  deliveryAreaName: 'منطقة $i',
  deliveryFeeFils: 2500,
);

void main() {
  const homeDir = 'lib/view/screens/home_screen';

  group('file boundaries', () {
    test('HomeScreen is a thin StatelessWidget with no side effects', () {
      final src = File('$homeDir/view/home_screen.dart').readAsStringSync();
      expect(src, contains('class HomeScreen extends StatelessWidget'));
      for (final forbidden in [
        'StatefulWidget',
        'AppLifecycleListener',
        'showAppPopup',
        'context.watch',
        '.load()',
        'TextPainter',
      ]) {
        expect(src.contains(forbidden), isFalse, reason: forbidden);
      }
    });

    test('each Home section lives in its own file', () {
      const sections = {
        'home_app_bar.dart': 'HomeAppBar',
        'wallet_balance_chip.dart': 'WalletBalanceChip',
        'home_greeting.dart': 'HomeGreeting',
        'home_availability_card.dart': 'HomeAvailabilityCard',
        'home_availability_notice.dart': 'HomeAvailabilityNotice',
        'home_availability_rationale_listener.dart':
            'HomeAvailabilityRationaleListener',
        'pending_offers_header.dart': 'PendingOffersHeader',
        'pending_offers_sliver.dart': 'PendingOffersSliver',
        'home_lifecycle_bridge.dart': 'HomeLifecycleBridge',
      };
      for (final MapEntry(key: file, value: widget) in sections.entries) {
        final src = File('$homeDir/widget/$file').readAsStringSync();
        final publicClasses = RegExp(
          r'^class ([A-Z]\w*)',
          multiLine: true,
        ).allMatches(src).map((m) => m.group(1)).toList();
        expect(publicClasses, [widget], reason: file);
      }
    });

    test('the Home Cubits hold no UI (no widgets, context or popups)', () {
      for (final file in Directory('$homeDir/cubit').listSync()) {
        final src = (file as File).readAsStringSync();
        for (final forbidden in [
          'package:flutter/material.dart',
          'BuildContext',
          'showAppPopup',
          'l10n',
        ]) {
          expect(
            src.contains(forbidden),
            isFalse,
            reason: '${file.path}: $forbidden',
          );
        }
      }
    });
  });

  group('lifecycle and rebuild scope', () {
    late AppSessionCubit session;
    late FakeAvailabilityRepository availabilityRepo;
    late FakePermissionGateway permissions;
    late CountingOfferRepository offersRepo;
    late HomeAvailabilityCubit availability;
    late PendingOffersCubit offers;

    Future<void> pumpHome(WidgetTester tester) async {
      session = AppSessionCubit(SignOut(FakeAuthRepository()));
      session.authenticate(
        const AppUser(id: 'c1', displayName: 'أحمد'),
        session.beginAttempt(),
      );
      availabilityRepo = FakeAvailabilityRepository();
      permissions = FakePermissionGateway(prerequisites());
      offersRepo = CountingOfferRepository([offer(1), offer(2), offer(3)]);
      availability = HomeAvailabilityCubit(
        GetCaptainAvailability(availabilityRepo),
        ChangeCaptainAvailability(availabilityRepo),
        permissions,
        () => session.state is SessionAuthenticated,
      );
      offers = PendingOffersCubit(
        GetEligibleOffers(offersRepo),
        AcceptOrderOffer(offersRepo),
        DeclineOrderOffer(offersRepo),
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
            ],
            child: const HomeScreen(),
          ),
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

    testWidgets('one load per mount; rebuilds do not reload; one reload per '
        'resume; nothing after teardown', (tester) async {
      await pumpHome(tester);
      expect(availabilityRepo.getCalls, 1);
      expect(offersRepo.loadCalls, 1);

      // Rebuilds (session change, state changes) never reload.
      session.authenticate(
        const AppUser(id: 'c1', displayName: 'سارة'),
        session.beginAttempt(),
      );
      await tester.pumpAndSettle();
      expect(availabilityRepo.getCalls, 1);
      expect(offersRepo.loadCalls, 1);

      resume(tester);
      await tester.pumpAndSettle();
      expect(availabilityRepo.getCalls, 2);
      expect(offersRepo.loadCalls, 2);
      // Resume never asks for permissions.
      expect(permissions.requestCalls, 0);

      // Home leaves the tree (e.g. sign-out closes the shell).
      await tester.pumpWidget(const SizedBox());
      resume(tester);
      await tester.pump();
      expect(availabilityRepo.getCalls, 2);
      expect(offersRepo.loadCalls, 2);
    });

    testWidgets('a greeting change rebuilds only the greeting', (tester) async {
      await pumpHome(tester);
      final appBar = tester.widget(find.byType(AppBar));
      final toggle = tester.widget(find.byType(AppAvailabilityToggle));
      final card = tester.widget(find.byKey(const ValueKey('offer-1')));

      session.authenticate(
        const AppUser(id: 'c1', displayName: 'سارة'),
        session.beginAttempt(),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.homeGreeting('سارة')), findsOneWidget);
      // Same widget instances: those sections did not rebuild.
      expect(identical(tester.widget(find.byType(AppBar)), appBar), isTrue);
      expect(
        identical(tester.widget(find.byType(AppAvailabilityToggle)), toggle),
        isTrue,
      );
      expect(
        identical(tester.widget(find.byKey(const ValueKey('offer-1'))), card),
        isTrue,
      );
    });

    testWidgets('an offers change does not rebuild the availability card or '
        'the app bar', (tester) async {
      await pumpHome(tester);
      final appBar = tester.widget(find.byType(AppBar));
      final toggle = tester.widget(find.byType(AppAvailabilityToggle));
      offersRepo.offers = [offer(1)];
      await offers.load();
      await tester.pumpAndSettle();
      expect(find.byType(AppOrderOfferCard), findsOneWidget);
      expect(identical(tester.widget(find.byType(AppBar)), appBar), isTrue);
      expect(
        identical(tester.widget(find.byType(AppAvailabilityToggle)), toggle),
        isTrue,
      );
    });

    testWidgets('an availability change does not rebuild the offer cards', (
      tester,
    ) async {
      await pumpHome(tester);
      final card = tester.widget(find.byKey(const ValueKey('offer-1')));
      final toggle = tester.widget(find.byType(AppAvailabilityToggle));
      await availability.requestChange(true);
      await tester.pumpAndSettle();
      expect(
        identical(tester.widget(find.byType(AppAvailabilityToggle)), toggle),
        isFalse,
      );
      expect(
        identical(tester.widget(find.byKey(const ValueKey('offer-1'))), card),
        isTrue,
      );
    });

    testWidgets('100 offers: only the visible part is built', (tester) async {
      setScreenSize(tester, 375, 800);
      await pumpHome(tester);
      offersRepo.offers = [for (var i = 1; i <= 100; i++) offer(i)];
      await offers.load();
      await tester.pumpAndSettle();
      expect(
        tester.widgetList(find.byType(AppOrderOfferCard)).length,
        lessThan(10),
      );
    });
  });
}
