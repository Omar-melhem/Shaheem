// «حسابي», Settings, About and account deletion (client revision D-A77,
// D-A78): identity from the session, the rating read model and its
// states, the three entries without a Wallet shortcut, the shared Terms
// flow, sign-out, and the confirmed deletion flow with typed outcomes.
// A fake repository stands in for the (unspecified) backend; no real
// deletion request is ever sent.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_frontend/data/repositories/captain_account_repository_placeholder.dart';
import 'package:mobile_frontend/domain/entities/app_user.dart';
import 'package:mobile_frontend/domain/entities/captain_account.dart';
import 'package:mobile_frontend/domain/errors/captain_account_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/captain_account_repository.dart';
import 'package:mobile_frontend/domain/use_cases/captain_account.dart';
import 'package:mobile_frontend/domain/use_cases/sign_out.dart';
import 'package:mobile_frontend/helper/legal/legal_page_launcher.dart';
import 'package:mobile_frontend/helper/money/jod_format.dart';
import 'package:mobile_frontend/main.dart';
import 'package:mobile_frontend/util/fonts.dart';
import 'package:mobile_frontend/util/routes/routes_string.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';
import 'package:mobile_frontend/view/screens/about_screen/view/about_screen.dart';
import 'package:mobile_frontend/view/screens/authentication/view/login_screen.dart';
import 'package:mobile_frontend/view/screens/profile_screen/cubit/profile_rating_cubit.dart';
import 'package:mobile_frontend/view/screens/profile_screen/view/profile_screen.dart';
import 'package:mobile_frontend/view/screens/settings_screen/view/settings_screen.dart';
import 'package:mobile_frontend/view/widget/navigation/main_nav_destination.dart';
import 'package:mobile_frontend/view/widget/navigation/main_navigation_bar.dart';
import 'package:mobile_frontend/view/widget/pop_up_screen/app_popup.dart';

import 'fakes.dart';
import 'test_app.dart';

/// Account source whose answers each test controls (test data only).
class FakeCaptainAccountRepository implements CaptainAccountRepository {
  CaptainRating? rating;
  Object? ratingError = const CaptainAccountBackendNotConfiguredException();
  int ratingCalls = 0;

  AccountDeletionStatus? deletion;
  Object? deletionError;
  Completer<void>? deletionPending;
  int deletionCalls = 0;

  @override
  Future<CaptainRating> getRating() async {
    ratingCalls++;
    final r = rating;
    if (r != null) return r;
    throw ratingError!;
  }

  @override
  Future<AccountDeletionStatus> requestAccountDeletion() async {
    deletionCalls++;
    if (deletionPending != null) await deletionPending!.future;
    if (deletionError != null) throw deletionError!;
    return deletion!;
  }
}

void main() {
  setUpAll(() async {
    // Real glyph metrics, so the large-text checks are meaningful.
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

  late FakeCaptainAccountRepository account;
  late FakeAuthRepository auth;

  setUp(() {
    account = FakeCaptainAccountRepository();
    auth = FakeAuthRepository(
      hasSession: true,
      user: const AppUser(
        id: 'c1',
        displayName: 'أحمد الشهم',
        phone: '0791234567',
      ),
    );
  });

  Future<void> launchProfile(WidgetTester tester) async {
    await tester.pumpWidget(
      MainApp(
        connectivityService: FakeInternetConnectionService(),
        authRepository: auth,
        captainAccountRepository: account,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(MainNavigationBar.itemKey(MainNavDestination.profile)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
  }

  Future<void> openSettings(WidgetTester tester) async {
    await launchProfile(tester);
    // The list is lazy: at large text the entry may not be built yet.
    await tester.scrollUntilVisible(
      find.text(l10n.settingsTitle),
      100,
      scrollable: find
          .descendant(
            of: find.byType(ProfileScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.settingsTitle));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  }

  group('Profile tab («حسابي»)', () {
    testWidgets('name and phone from the session; phone LTR-isolated; a root '
        'tab without a back button', (tester) async {
      await launchProfile(tester);
      expect(find.text('أحمد الشهم'), findsOneWidget);
      expect(find.text(ltrIsolate('0791234567')), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
    });

    testWidgets('missing name and phone: honest fallbacks, nothing invented', (
      tester,
    ) async {
      auth.user = const AppUser(id: 'c1', displayName: ' ');
      await launchProfile(tester);
      expect(find.text(l10n.profileNameUnavailable), findsOneWidget);
      expect(find.text(l10n.profilePhoneUnavailable), findsOneWidget);
    });

    testWidgets('three entries — Settings, Terms, About — plus sign-out; no '
        'Wallet entry (D-A77)', (tester) async {
      await launchProfile(tester);
      for (final label in [
        l10n.settingsTitle,
        l10n.termsAndConditions,
        l10n.aboutTitle,
        l10n.profileSignOut,
      ]) {
        expect(
          find.widgetWithText(ListTile, label),
          findsOneWidget,
          reason: label,
        );
      }
      expect(find.widgetWithText(ListTile, l10n.walletTitle), findsNothing);
    });

    group('rating', () {
      // R03 (STATE-01): refresh on re-show and on resume while visible.
      group('refresh', () {
        void resume(WidgetTester tester) {
          for (final s in const [
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

        Finder tab(MainNavDestination d) =>
            find.byKey(MainNavigationBar.itemKey(d));

        setUp(() {
          account.rating = const CaptainRating(
            ratingsCount: 4,
            average: 4.5,
            scaleMax: 5,
          );
        });

        testWidgets('first show reads once; rebuilds read nothing', (
          tester,
        ) async {
          await launchProfile(tester);
          expect(account.ratingCalls, 1);
          tester.platformDispatcher.textScaleFactorTestValue = 1.3;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await tester.pumpAndSettle();
          expect(account.ratingCalls, 1);
        });

        testWidgets('another tab → Profile reads once more and keeps the '
            'confirmed value on screen meanwhile', (tester) async {
          await launchProfile(tester);
          await tester.tap(tab(MainNavDestination.home));
          await tester.pumpAndSettle();
          expect(account.ratingCalls, 1);
          await tester.tap(tab(MainNavDestination.profile));
          await tester.pump();
          expect(find.text(l10n.profileRatingLoading), findsNothing);
          await tester.pumpAndSettle();
          expect(account.ratingCalls, 2);
          expect(find.text(l10n.profileRatingCount(4)), findsOneWidget);
        });

        testWidgets('resume while visible reads once; while hidden reads '
            'nothing', (tester) async {
          await launchProfile(tester);
          resume(tester);
          await tester.pumpAndSettle();
          expect(account.ratingCalls, 2);

          await tester.tap(tab(MainNavDestination.wallet));
          await tester.pumpAndSettle();
          resume(tester);
          await tester.pumpAndSettle();
          expect(account.ratingCalls, 2);
        });

        testWidgets('sign-out: no read after the tab is gone', (tester) async {
          await launchProfile(tester);
          await BlocProvider.of<AppSessionCubit>(
            tester.element(find.byType(ProfileScreen)),
          ).endSession();
          await tester.pumpAndSettle();
          resume(tester);
          await tester.pumpAndSettle();
          expect(find.byType(ProfileScreen), findsNothing);
          expect(account.ratingCalls, 1);
        });
      });

      testWidgets('not configured: «التقييم غير متوفر», no Retry, no value', (
        tester,
      ) async {
        await launchProfile(tester);
        expect(find.text(l10n.profileRatingUnavailable), findsOneWidget);
        expect(account.ratingCalls, 1);
      });

      testWidgets('offline: unavailable with Retry that reads again', (
        tester,
      ) async {
        account.ratingError = const CaptainAccountNetworkUnavailableException();
        await launchProfile(tester);
        expect(find.text(l10n.profileRatingUnavailable), findsOneWidget);
        account.rating = const CaptainRating(
          ratingsCount: 12,
          average: 4.25,
          scaleMax: 5,
        );
        await tester.tap(find.text(l10n.retry));
        await tester.pumpAndSettle();
        expect(
          find.text(
            l10n.profileRatingOutOf(ltrIsolate('4.3'), ltrIsolate('5')),
          ),
          findsOneWidget,
        );
        expect(find.text(l10n.profileRatingCount(12)), findsOneWidget);
      });

      testWidgets('confirmed no ratings is distinct from unknown', (
        tester,
      ) async {
        account.rating = const CaptainRating(ratingsCount: 0);
        await launchProfile(tester);
        expect(find.text(l10n.profileRatingNone), findsOneWidget);
        expect(find.text(l10n.profileRatingUnavailable), findsNothing);
      });

      testWidgets('no scale stated: the value alone, never «من 5»', (
        tester,
      ) async {
        account.rating = const CaptainRating(ratingsCount: 3, average: 87);
        await launchProfile(tester);
        expect(find.text(ltrIsolate('87')), findsOneWidget);
        expect(find.textContaining('من'), findsNothing);
      });
    });

    testWidgets('Terms reuses the Login legal flow: no URL → truthful popup', (
      tester,
    ) async {
      final web = FakeInAppWebPageLauncher();
      final session = AppSessionCubit(SignOut(FakeAuthRepository()));
      addTearDown(session.close);
      await tester.pumpWidget(
        testApp(
          MultiBlocProvider(
            providers: [
              BlocProvider.value(value: session),
              BlocProvider(create: (_) => _profileRatingCubitForWidgetTests()),
            ],
            child: ProfileScreen(
              legalPageLauncher: LegalPageLauncher(launcher: web),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.termsAndConditions));
      await tester.pumpAndSettle();
      expect(find.text(l10n.termsUnavailableMessage), findsOneWidget);
      expect(web.opened, isEmpty);
    });

    testWidgets('About: app identity; version honestly unavailable; Back '
        'returns to «حسابي»', (tester) async {
      await launchProfile(tester);
      await tester.tap(find.text(l10n.aboutTitle));
      await tester.pumpAndSettle();
      expect(find.byType(AboutScreen), findsOneWidget);
      expect(find.text(l10n.appName), findsOneWidget);
      expect(find.text(l10n.aboutVersionUnavailable), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('sign-out: Cancel keeps the session; confirm → Login', (
      tester,
    ) async {
      await launchProfile(tester);
      await tester.tap(find.text(l10n.profileSignOut));
      await tester.pumpAndSettle();
      expect(find.byType(AppPopup), findsOneWidget);
      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
      await tester.tap(find.text(l10n.profileSignOut));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, l10n.profileSignOut));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(auth.clearCalls, 1);
    });

    for (final scale in [1.0, 3.0]) {
      testWidgets('320 px × $scale: Profile and Settings readable, no '
          'overflow', (tester) async {
        setScreenSize(tester, 320, 640);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        account.rating = const CaptainRating(
          ratingsCount: 1200,
          average: 4.8,
          scaleMax: 5,
        );
        await openSettings(tester);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (final p in tester.renderObjectList<RenderParagraph>(
          find.byType(RichText),
        )) {
          expect(p.didExceedMaxLines, isFalse, reason: p.text.toPlainText());
        }
      });
    }
  });

  group('Settings: account deletion (D-A78)', () {
    Future<void> tapEntry(WidgetTester tester) async {
      await tester.tap(find.text(l10n.accountDeletionEntry));
      await tester.pumpAndSettle();
    }

    Future<void> confirm(WidgetTester tester) async {
      await tester.tap(find.text(l10n.accountDeletionConfirmAction));
      await tester.pumpAndSettle();
    }

    testWidgets('the entry only opens the confirmation; Cancel sends nothing', (
      tester,
    ) async {
      account.deletion = AccountDeletionStatus.completed;
      await openSettings(tester);
      await tapEntry(tester);
      expect(find.text(l10n.accountDeletionConfirmTitle), findsOneWidget);
      expect(find.text(l10n.accountDeletionConfirmMessage), findsOneWidget);
      expect(account.deletionCalls, 0);
      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();
      expect(account.deletionCalls, 0);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('production placeholder: says nothing was sent or deleted; '
        'the session stays', (tester) async {
      account.deletionError =
          const CaptainAccountBackendNotConfiguredException();
      await openSettings(tester);
      await tapEntry(tester);
      await confirm(tester);
      expect(find.text(l10n.accountDeletionNotConfigured), findsOneWidget);
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(auth.clearCalls, 0);
      expect(
        await RequestAccountDeletion(
          const CaptainAccountRepositoryPlaceholder(),
        )(),
        isA<AccountDeletionNotConfigured>(),
      );
    });

    testWidgets('confirmed submission is sent once (double tap); offline '
        'allows retry; then pending is not "deleted"', (tester) async {
      account
        ..deletionPending = Completer()
        ..deletionError = const CaptainAccountNetworkUnavailableException();
      await openSettings(tester);
      await tapEntry(tester);
      // The spinner never settles while the request is pending: pump.
      await tester.tap(find.text(l10n.accountDeletionConfirmAction));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // Busy: the entry ignores taps.
      expect(find.text(l10n.accountDeletionSubmitting), findsOneWidget);
      await tester.tap(find.text(l10n.accountDeletionSubmitting));
      await tester.pump();
      expect(account.deletionCalls, 1);
      account.deletionPending!.complete();
      account.deletionPending = null;
      await tester.pumpAndSettle();
      expect(find.text(l10n.accountDeletionNoInternet), findsOneWidget);

      account
        ..deletionError = null
        ..deletion = AccountDeletionStatus.pending;
      await tapEntry(tester);
      await confirm(tester);
      expect(account.deletionCalls, 2);
      expect(find.text(l10n.accountDeletionPending), findsOneWidget);
      // Pending keeps the session and blocks a second request.
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(auth.clearCalls, 0);
      await tester.tap(find.text(l10n.accountDeletionEntry));
      await tester.pumpAndSettle();
      expect(find.text(l10n.accountDeletionConfirmTitle), findsNothing);
    });

    testWidgets('failure: nothing assumed deleted; retry allowed', (
      tester,
    ) async {
      account.deletionError = const CaptainAccountServiceUnavailableException();
      await openSettings(tester);
      await tapEntry(tester);
      await confirm(tester);
      expect(find.text(l10n.accountDeletionFailed), findsOneWidget);
      await tapEntry(tester);
      expect(find.text(l10n.accountDeletionConfirmTitle), findsOneWidget);
    });

    testWidgets('reauthentication required → the real sign-in flow', (
      tester,
    ) async {
      account.deletionError =
          const CaptainAccountReauthenticationRequiredException();
      await openSettings(tester);
      await tapEntry(tester);
      await confirm(tester);
      expect(find.text(l10n.accountDeletionReauthRequired), findsOneWidget);
      await tester.tap(find.text(l10n.accountDeletionSignInAgain));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('server-confirmed completion clears the session → Login; Back '
        'and deep links cannot resurrect protected pages', (tester) async {
      account.deletion = AccountDeletionStatus.completed;
      await openSettings(tester);
      await tapEntry(tester);
      await confirm(tester);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(auth.clearCalls, 1);
      final session = tester
          .element(find.byType(LoginScreen))
          .read<AppSessionCubit>();
      expect(session.state, isA<SessionUnauthenticated>());

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsNothing);
      for (final path in [
        RoutesString.settings,
        RoutesString.profile,
        RoutesString.currentOrder,
      ]) {
        GoRouter.of(tester.element(find.byType(LoginScreen))).go(path);
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget, reason: path);
      }
    });
  });
}

/// A rating Cubit over the "not configured" placeholder, for widget tests
/// that pump [ProfileScreen] alone.
ProfileRatingCubit _profileRatingCubitForWidgetTests() => ProfileRatingCubit(
  const GetCaptainRating(CaptainAccountRepositoryPlaceholder()),
  () => true,
);
