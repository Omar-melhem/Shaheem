// Home screen (Task 24): app bar wallet total, greeting and the
// availability card, rendered with the real IBM Plex Sans Arabic glyphs.
// Backend and permissions are fakes here only.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_frontend/data/repositories/availability_permission_gateway_placeholder.dart';
import 'package:mobile_frontend/data/repositories/captain_availability_repository_placeholder.dart';
import 'package:mobile_frontend/domain/entities/app_user.dart';
import 'package:mobile_frontend/domain/entities/captain_availability.dart';
import 'package:mobile_frontend/domain/repositories/availability_permission_gateway.dart';
import 'package:mobile_frontend/domain/repositories/captain_availability_repository.dart';
import 'package:mobile_frontend/domain/use_cases/captain_availability.dart';
import 'package:mobile_frontend/domain/use_cases/sign_out.dart';
import 'package:mobile_frontend/helper/money/jod_format.dart';
import 'package:mobile_frontend/main.dart';
import 'package:mobile_frontend/util/fonts.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';
import 'package:mobile_frontend/view/screens/home_screen/cubit/home_availability_cubit.dart';
import 'package:mobile_frontend/view/screens/home_screen/view/home_screen.dart';
import 'package:mobile_frontend/view/widget/toggle/app_availability_toggle.dart';

import 'availability_fakes.dart';
import 'fakes.dart';
import 'test_app.dart';

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

  final toggle = find.byType(AppAvailabilityToggle);

  /// Pumps Home with a session ([user] null: none, like the debug preview).
  Future<void> pumpHome(
    WidgetTester tester, {
    AppUser? user = const AppUser(id: 'c1', displayName: 'أحمد'),
    int? walletTotalFils,
    CaptainAvailabilityRepository? repository,
    AvailabilityPermissionGateway? permissions,
  }) async {
    final session = AppSessionCubit(SignOut(FakeAuthRepository()));
    if (user != null) session.authenticate(user, session.beginAttempt());
    final repo = repository ?? const CaptainAvailabilityRepositoryPlaceholder();
    final cubit = HomeAvailabilityCubit(
      GetCaptainAvailability(repo),
      ChangeCaptainAvailability(repo),
      permissions ?? const AvailabilityPermissionGatewayPlaceholder(),
      () => session.state is SessionAuthenticated,
    );
    addTearDown(cubit.close);
    addTearDown(session.close);
    await tester.pumpWidget(
      testApp(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: session),
            BlocProvider.value(value: cubit),
          ],
          child: HomeScreen(walletTotalFils: walletTotalFils),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Finder appBarText(String text) =>
      find.descendant(of: find.byType(AppBar), matching: find.text(text));

  group('app bar', () {
    testWidgets('unknown balance: «—» and an unavailable label, never 0.000', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpHome(tester);
      expect(appBarText(l10n.walletBalanceUnknownValue), findsOneWidget);
      expect(find.textContaining('0.000'), findsNothing);
      expect(
        find.bySemanticsLabel(l10n.walletBalanceUnavailableSemantics),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('read-only: no wallet or profile action in the app bar', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpHome(tester, walletTotalFils: 1500);
      final chip = tester.getSemantics(
        find.bySemanticsLabel(l10n.walletBalanceSemantics('1.500')),
      );
      expect(chip.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      for (final type in [IconButton, InkWell, GestureDetector]) {
        expect(
          find.descendant(of: find.byType(AppBar), matching: find.byType(type)),
          findsNothing,
          reason: '$type',
        );
      }
      semantics.dispose();
    });

    for (final fils in [0, 1500, -1000, -12345678, 987654321000]) {
      testWidgets('$fils fils: exact JOD text, LTR-isolated, spoken', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await pumpHome(tester, walletTotalFils: fils);
        final amount = formatJodFils(fils);
        expect(
          appBarText('${ltrIsolate(amount)} ${l10n.walletCurrencySymbol}'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(l10n.walletBalanceSemantics(amount)),
          findsOneWidget,
        );
        semantics.dispose();
      });
    }

    for (final width in [320.0, 375.0, 450.0]) {
      for (final scale in [1.0, 2.0, 3.0]) {
        testWidgets('$width px × $scale: balance whole, inside the bar', (
          tester,
        ) async {
          final semantics = tester.ensureSemantics();
          setScreenSize(tester, width, 800);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          const fils = -12345678;
          await pumpHome(tester, walletTotalFils: fils);
          expect(tester.takeException(), isNull);
          final text =
              '${ltrIsolate(formatJodFils(fils))} '
              '${l10n.walletCurrencySymbol}';
          final paragraph = tester.renderObject<RenderParagraph>(
            appBarText(text),
          );
          expect(paragraph.didExceedMaxLines, isFalse);
          final bar = tester.getRect(find.byType(AppBar));
          final chip = tester.getRect(appBarText(text));
          expect(bar.contains(chip.topLeft), isTrue);
          expect(bar.contains(chip.bottomRight), isTrue);
          // The title shows only when it fits whole; it is always there for
          // screen readers.
          final title = appBarText(l10n.homeTitle);
          if (title.evaluate().isNotEmpty) {
            expect(
              tester.renderObject<RenderParagraph>(title).didExceedMaxLines,
              isFalse,
            );
          }
          expect(find.bySemanticsLabel(l10n.homeTitle), findsOneWidget);
          semantics.dispose();
        });
      }
    }

    testWidgets('RTL: title at the start (right), balance at the end', (
      tester,
    ) async {
      setScreenSize(tester, 375, 800);
      await pumpHome(tester, walletTotalFils: 1500);
      final title = tester.getCenter(appBarText(l10n.homeTitle)).dx;
      final chip = tester
          .getCenter(
            appBarText('${ltrIsolate('1.500')} ${l10n.walletCurrencySymbol}'),
          )
          .dx;
      expect(title, greaterThan(chip));
    });
  });

  group('greeting', () {
    testWidgets('uses the session display name', (tester) async {
      await pumpHome(tester);
      expect(find.text(l10n.homeGreeting('أحمد')), findsOneWidget);
    });

    for (final name in [null, '', '   ']) {
      testWidgets(
        'name ${name == null ? 'absent' : 'blank'}: no-name greeting',
        (tester) async {
          await pumpHome(
            tester,
            user: AppUser(id: 'c1', displayName: name),
          );
          expect(find.text(l10n.homeGreetingNoName), findsOneWidget);
        },
      );
    }

    testWidgets('no session (debug preview): no invented user, no prompts', (
      tester,
    ) async {
      final permissions = FakePermissionGateway(prerequisites());
      final repo = FakeAvailabilityRepository();
      await pumpHome(
        tester,
        user: null,
        repository: repo,
        permissions: permissions,
      );
      expect(find.text(l10n.homeGreetingNoName), findsOneWidget);
      expect(find.text(l10n.availabilityNoSession), findsOneWidget);
      await tester.tap(toggle);
      await tester.pump();
      expect(repo.getCalls, 0);
      expect(permissions.checkCalls + permissions.requestCalls, 0);
    });

    testWidgets('a long name wraps without overflow at 320 px × 3', (
      tester,
    ) async {
      setScreenSize(tester, 320, 800);
      tester.platformDispatcher.textScaleFactorTestValue = 3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      const name = 'عبد الرحمن محمد عبد الله الخطيب';
      await pumpHome(
        tester,
        user: const AppUser(id: 'c1', displayName: name),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester
            .renderObject<RenderParagraph>(find.text(l10n.homeGreeting(name)))
            .didExceedMaxLines,
        isFalse,
      );
    });
  });

  group('availability card', () {
    testWidgets('default app (no backend): truthful notice, toggle disabled, '
        'off', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpHome(tester);
      expect(find.text(l10n.availabilityCardTitle), findsOneWidget);
      expect(find.text(l10n.availabilityNotConfigured), findsOneWidget);
      expect(
        tester.getSemantics(toggle),
        isSemantics(
          label: l10n.availabilityToggleLabel,
          value: l10n.availabilityStatusUnknown,
          hasToggledState: true,
          isToggled: false,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      semantics.dispose();
    });

    testWidgets('first time: explanation, then prompts, then confirmed on', (
      tester,
    ) async {
      final repo = FakeAvailabilityRepository();
      final permissions = FakePermissionGateway(
        prerequisites(base: RequirementStatus.notDetermined),
        afterRequest: prerequisites(),
      );
      await pumpHome(tester, repository: repo, permissions: permissions);
      expect(find.text(l10n.availabilityStatusUnavailable), findsOneWidget);

      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.text(l10n.availabilityRationaleTitle), findsOneWidget);
      expect(permissions.requestCalls, 0);

      await tester.tap(find.text(l10n.availabilityContinue));
      await tester.pumpAndSettle();
      expect(permissions.requestCalls, 1);
      expect(repo.setCalls, [CaptainAvailability.available]);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      expect(find.text(l10n.availabilityStatusAvailable), findsOneWidget);
    });

    testWidgets('cancel or back on the explanation requests nothing', (
      tester,
    ) async {
      final permissions = FakePermissionGateway(
        prerequisites(base: RequirementStatus.notDetermined),
      );
      await pumpHome(
        tester,
        repository: FakeAvailabilityRepository(),
        permissions: permissions,
      );
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();
      expect(permissions.requestCalls, 0);
      expect(find.text(l10n.availabilityMissingIntro), findsOneWidget);

      // Again, closed with the system back button this time.
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.text(l10n.availabilityRationaleTitle), findsOneWidget);
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      navigator.pop();
      await tester.pumpAndSettle();
      expect(permissions.requestCalls, 0);
      // The toggle accepts a new intent (not stuck waiting).
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.text(l10n.availabilityRationaleTitle), findsOneWidget);
    });

    testWidgets('settings-only denial lists what is missing; Settings opens '
        'only on tap', (tester) async {
      final permissions = FakePermissionGateway(
        prerequisites(
          overrides: {
            AvailabilityRequirement.backgroundLocation:
                RequirementStatus.permanentlyDenied,
            AvailabilityRequirement.notifications:
                RequirementStatus.permanentlyDenied,
          },
        ),
      );
      await pumpHome(
        tester,
        repository: FakeAvailabilityRepository(),
        permissions: permissions,
      );
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(
        find.text('• ${l10n.availabilityNeedBackgroundLocation}'),
        findsOneWidget,
      );
      expect(
        find.text('• ${l10n.availabilityNeedNotifications}'),
        findsOneWidget,
      );
      expect(permissions.settingsCalls, 0);
      await tester.tap(find.text(l10n.availabilityOpenSettings));
      await tester.pump();
      expect(permissions.settingsCalls, 1);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    });

    testWidgets('returning to the foreground re-reads the server status', (
      tester,
    ) async {
      final repo = FakeAvailabilityRepository();
      final permissions = FakePermissionGateway(prerequisites());
      await pumpHome(tester, repository: repo, permissions: permissions);
      final reads = repo.getCalls;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(repo.getCalls, reads + 1);
      expect(permissions.requestCalls, 0);
    });

    for (final width in [320.0, 375.0, 450.0]) {
      for (final scale in [1.0, 2.0, 3.0]) {
        testWidgets('short screen $width×480 × $scale: toggle reachable', (
          tester,
        ) async {
          setScreenSize(tester, width, 480);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final repo = FakeAvailabilityRepository();
          await pumpHome(
            tester,
            walletTotalFils: -12345678,
            repository: repo,
            permissions: FakePermissionGateway(prerequisites()),
          );
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(toggle);
          await tester.pumpAndSettle();
          expect(tester.getSize(toggle).height, greaterThanOrEqualTo(48));
          // At scale 3 the row can be taller than the visible body; any
          // visible part of it is the tap target.
          final rect = tester.getRect(toggle);
          final visibleBottom = rect.bottom.clamp(0.0, 480.0);
          await tester.tapAt(
            Offset(rect.center.dx, (rect.top + visibleBottom) / 2),
          );
          await tester.pumpAndSettle();
          expect(repo.setCalls, [CaptainAvailability.available]);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('in the real app (default placeholders)', () {
    testWidgets('signed-in captain: name, «—» balance, not-configured card', (
      tester,
    ) async {
      await tester.pumpWidget(
        MainApp(
          connectivityService: FakeInternetConnectionService(),
          authRepository: FakeAuthRepository(hasSession: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        find.text(l10n.homeGreeting(testUser.displayName!)),
        findsOneWidget,
      );
      expect(appBarText(l10n.walletBalanceUnknownValue), findsOneWidget);
      expect(find.text(l10n.availabilityNotConfigured), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      // Nothing to tap that could prompt: the toggle is disabled.
      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    });
  });
}
