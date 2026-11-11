// Tests for the app-wide foundations: Arabic-first localization and the
// central responsive breakpoints.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_frontend/helper/translation/generated/app_localizations.dart';
import 'package:mobile_frontend/main.dart';
import 'package:mobile_frontend/util/responsive/app_breakpoints.dart';
import 'package:mobile_frontend/view/screens/authentication/view/login_screen.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'fakes.dart';
import 'test_app.dart';

void main() {
  group('localization', () {
    test('Arabic is the only supported locale', () {
      expect(AppLocalizations.supportedLocales, [const Locale('ar')]);
    });

    testWidgets('app runs in Arabic, RTL, with Arabic strings', (tester) async {
      await tester.pumpWidget(
        MainApp(
          connectivityService: FakeInternetConnectionService(),
          authRepository: FakeAuthRepository(),
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(LoginScreen));
      expect(Localizations.localeOf(context), const Locale('ar'));
      expect(Directionality.of(context), TextDirection.rtl);
      // Heading and button share the same Arabic text («تسجيل الدخول»).
      expect(find.text(l10n.loginTitle), findsNWidgets(2));
      // Material's own strings are Arabic too (built-in delegates).
      expect(MaterialLocalizations.of(context).okButtonLabel, isNot('OK'));
    });

    test('generated Arabic resources are non-empty', () {
      for (final value in [
        l10n.appName,
        l10n.loginTitle,
        l10n.usernameLabel,
        l10n.passwordLabel,
        l10n.loginInvalidCredentials,
        l10n.forgotPasswordMessage,
        l10n.offlineBanner,
        l10n.retry,
      ]) {
        expect(value.trim(), isNotEmpty);
      }
    });
  });

  group('breakpoints', () {
    /// Breakpoint name at [width], from the real central configuration.
    Future<String?> nameAt(WidgetTester tester, double width) async {
      setScreenSize(tester, width, 800);
      late String? name;
      await tester.pumpWidget(
        testApp(
          Builder(
            builder: (context) {
              name = ResponsiveBreakpoints.of(context).breakpoint.name;
              return const SizedBox();
            },
          ),
        ),
      );
      // The package measures the screen after the first frame, then rebuilds.
      await tester.pump();
      return name;
    }

    // Includes fractional widths just past every boundary (450.5, 800.5,
    // 1920.5): each must land in the next range, never in an uncovered gap.
    final cases = <double, String>{
      1: MOBILE,
      320: MOBILE,
      450: MOBILE,
      450.5: TABLET,
      451: TABLET,
      800: TABLET,
      800.5: DESKTOP,
      801: DESKTOP,
      1920: DESKTOP,
      1920.5: AppBreakpoints.fourK,
      1921: AppBreakpoints.fourK,
      3000: AppBreakpoints.fourK,
    };
    cases.forEach((width, expected) {
      testWidgets('$width → $expected (no gaps between ranges)', (
        tester,
      ) async {
        expect(await nameAt(tester, width), expected);
      });
    });
  });
}
