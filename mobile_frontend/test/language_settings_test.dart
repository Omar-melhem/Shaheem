// Arabic/English display language (owner-requested feature): Settings
// entry, immediate switch through the app-wide AppLocaleCubit, direction
// from localization, nothing else rebuilt from scratch, and complete
// English resources.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_frontend/domain/entities/app_user.dart';
import 'package:mobile_frontend/domain/entities/captain_account.dart';
import 'package:mobile_frontend/domain/errors/captain_account_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/captain_account_repository.dart';
import 'package:mobile_frontend/helper/money/jod_format.dart';
import 'package:mobile_frontend/helper/translation/generated/app_localizations.dart';
import 'package:mobile_frontend/main.dart';
import 'package:mobile_frontend/view/app_state/locale/app_locale_cubit.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/cubit/current_order_cubit.dart';
import 'package:mobile_frontend/view/screens/profile_screen/view/profile_screen.dart';
import 'package:mobile_frontend/view/screens/settings_screen/view/settings_screen.dart';
import 'package:mobile_frontend/view/widget/navigation/main_nav_destination.dart';
import 'package:mobile_frontend/view/widget/navigation/main_navigation_bar.dart';

import 'fakes.dart';
import 'test_app.dart';

/// English strings for assertions.
final AppLocalizations en = lookupAppLocalizations(const Locale('en'));

/// Rating source that counts reads (test data only).
class _CountingAccount implements CaptainAccountRepository {
  int ratingCalls = 0;

  @override
  Future<CaptainRating> getRating() async {
    ratingCalls++;
    return const CaptainRating(ratingsCount: 27, average: 4.3);
  }

  @override
  Future<AccountDeletionStatus> requestAccountDeletion() async =>
      throw const CaptainAccountBackendNotConfiguredException();
}

void main() {
  test(
    'AppLocaleCubit: Arabic by default; select applies; same is a no-op',
    () async {
      final cubit = AppLocaleCubit();
      addTearDown(cubit.close);
      expect(cubit.state, AppLanguage.arabic);
      expect(cubit.state.locale, const Locale('ar'));
      final emitted = <AppLanguage>[];
      final sub = cubit.stream.listen(emitted.add);
      cubit
        ..select(AppLanguage.arabic)
        ..select(AppLanguage.english)
        ..select(AppLanguage.english);
      await Future<void>.delayed(Duration.zero);
      expect(emitted, [AppLanguage.english]);
      expect(AppLanguage.english.locale, const Locale('en'));
      await sub.cancel();
    },
  );

  test('app_en.arb has every app_ar.arb message with the same '
      'placeholders; no extra keys', () {
    Map<String, dynamic> read(String name) =>
        jsonDecode(File('lib/helper/translation/$name').readAsStringSync())
            as Map<String, dynamic>;
    final ar = read('app_ar.arb');
    final enArb = read('app_en.arb');
    final keys = ar.keys.where((k) => !k.startsWith('@')).toSet();
    final enKeys = enArb.keys.where((k) => !k.startsWith('@')).toSet();
    expect(enKeys, keys);
    expect(enArb['@@locale'], 'en');
    for (final key in keys) {
      final placeholders =
          ((ar['@$key'] as Map<String, dynamic>?)?['placeholders']
                  as Map<String, dynamic>?)
              ?.keys
              .toSet() ??
          <String>{};
      final message = enArb[key] as String;
      expect(message.trim(), isNotEmpty, reason: key);
      for (final p in placeholders) {
        expect(message, contains('{$p'), reason: '$key: {$p}');
      }
    }
  });

  test('English plurals and formatting stay locale-independent', () {
    expect(en.profileRatingCount(0), 'No ratings');
    expect(en.profileRatingCount(1), '1 rating');
    expect(en.profileRatingCount(27), '27 ratings');
    expect(en.routeDistanceAndTime('2.5', 1), endsWith('1 minute'));
    expect(en.routeDistanceAndTime('2.5', 7), endsWith('7 minutes'));
    // Amounts keep the same Western-digit format in both languages.
    expect(formatJodFils(1500), '1.500');
    expect(en.walletCurrencySymbol, 'JOD');
  });

  group('Settings language entry', () {
    late FakeAuthRepository auth;
    late FakeActiveOrderRepository orders;
    late _CountingAccount account;

    setUp(() {
      auth = FakeAuthRepository(
        hasSession: true,
        user: const AppUser(
          id: 'c1',
          displayName: 'أحمد الشهم',
          phone: '0791234567',
        ),
      );
      orders = FakeActiveOrderRepository(order: testActiveOrder);
      account = _CountingAccount();
    });

    Future<void> openSettings(WidgetTester tester) async {
      setScreenSize(tester, 420, 1400);
      await tester.pumpWidget(
        MainApp(
          connectivityService: FakeInternetConnectionService(),
          authRepository: auth,
          activeOrderRepository: orders,
          captainLocationRepository: FakeCaptainLocationRepository(),
          captainAccountRepository: account,
        ),
      );
      await tester.pumpAndSettle();
      // The active order opens Current Order above the shell at startup.
      GoRouter.of(tester.element(find.byType(Navigator).first)).go('/profile');
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
      await tester.tap(find.text(l10n.settingsTitle));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
    }

    Finder option(AppLanguage language) =>
        find.byKey(Key('settings-language-${language.name}'));

    testWidgets('both languages, separate from deletion; Arabic marked', (
      tester,
    ) async {
      await openSettings(tester);
      expect(find.text(l10n.settingsLanguageSection), findsOneWidget);
      expect(find.text('العربية'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(
        tester.widget<ListTile>(option(AppLanguage.arabic)).selected,
        isTrue,
      );
      expect(
        tester.widget<ListTile>(option(AppLanguage.english)).selected,
        isFalse,
      );
      // Deletion is its own section, below the language choice.
      expect(
        tester.getRect(option(AppLanguage.english)).bottom,
        lessThan(tester.getTopLeft(find.text(l10n.accountDeletionEntry)).dy),
      );
    });

    testWidgets('switch to English applies at once, LTR; the same router, '
        'session, Cubits and active order stay; back to Arabic, RTL', (
      tester,
    ) async {
      await openSettings(tester);
      final element = tester.element(find.byType(SettingsScreen));
      final router = GoRouter.of(element);
      final session = element.read<AppSessionCubit>();
      final sessionState = session.state;
      final current = element.read<CurrentOrderCubit>();
      final currentState = current.state;
      expect(currentState, isA<CurrentOrderActive>());
      final ordersCalls = orders.calls;
      final ratingCalls = account.ratingCalls;

      await tester.tap(option(AppLanguage.english));
      await tester.pumpAndSettle();

      final after = tester.element(find.byType(SettingsScreen));
      expect(Localizations.localeOf(after), const Locale('en'));
      expect(Directionality.of(after), TextDirection.ltr);
      expect(find.text(en.settingsTitle), findsOneWidget);
      expect(find.text(en.settingsLanguageSection), findsOneWidget);
      expect(find.text(en.accountDeletionEntry), findsOneWidget);
      expect(
        tester.widget<ListTile>(option(AppLanguage.english)).selected,
        isTrue,
      );
      // Nothing rebuilt from scratch, nobody signed out, nothing re-read.
      expect(identical(GoRouter.of(after), router), isTrue);
      expect(identical(after.read<AppSessionCubit>(), session), isTrue);
      expect(identical(session.state, sessionState), isTrue);
      expect(identical(after.read<CurrentOrderCubit>(), current), isTrue);
      expect(identical(current.state, currentState), isTrue);
      expect(orders.calls, ordersCalls);
      expect(account.ratingCalls, ratingCalls);

      // Back keeps the stack: Profile in English with the same data.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text(en.profileTitle), findsWidgets);
      expect(find.text('أحمد الشهم'), findsOneWidget);
      expect(find.text(ltrIsolate('0791234567')), findsOneWidget);
      expect(
        find.text(ltrIsolate(en.profileRatingValue('4.3', '5'))),
        findsOneWidget,
      );
      // Only the existing re-show refresh (R03, the same as returning from
      // Settings without a language change); the switch itself read nothing.
      expect(account.ratingCalls, ratingCalls + 1);
      // Tabs keep their identities and order; labels are English.
      for (final d in MainNavDestination.values) {
        expect(find.byKey(MainNavigationBar.itemKey(d)), findsOneWidget);
      }
      final home = tester.getCenter(
        find.byKey(MainNavigationBar.itemKey(MainNavDestination.home)),
      );
      final profile = tester.getCenter(
        find.byKey(MainNavigationBar.itemKey(MainNavDestination.profile)),
      );
      // LTR: the first branch is on the left.
      expect(home.dx, lessThan(profile.dx));

      await tester.tap(find.text(en.settingsTitle));
      await tester.pumpAndSettle();
      await tester.tap(option(AppLanguage.arabic));
      await tester.pumpAndSettle();
      final ar = tester.element(find.byType(SettingsScreen));
      expect(Localizations.localeOf(ar), const Locale('ar'));
      expect(Directionality.of(ar), TextDirection.rtl);
      expect(find.text(l10n.settingsTitle), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      final homeAr = tester.getCenter(
        find.byKey(MainNavigationBar.itemKey(MainNavDestination.home)),
      );
      final profileAr = tester.getCenter(
        find.byKey(MainNavigationBar.itemKey(MainNavDestination.profile)),
      );
      // RTL: the first branch is on the right.
      expect(homeAr.dx, greaterThan(profileAr.dx));
      final shell = tester.element(find.byType(ProfileScreen));
      expect(identical(shell.read<AppSessionCubit>(), session), isTrue);
      expect(identical(shell.read<CurrentOrderCubit>(), current), isTrue);
      expect(identical(GoRouter.of(shell), router), isTrue);
      expect(orders.calls, ordersCalls);
    });

    testWidgets('a fresh app starts in Arabic again (no persistence)', (
      tester,
    ) async {
      await openSettings(tester);
      await tester.tap(option(AppLanguage.english));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await openSettings(tester);
      final context = tester.element(find.byType(SettingsScreen));
      expect(Localizations.localeOf(context), const Locale('ar'));
    });
  });
}
