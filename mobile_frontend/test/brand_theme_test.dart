// Tests for the visual foundation: the D-A69 red/white/neutral palette, the bundled
// IBM Plex Sans Arabic family, Ink default text, the input border contrast,
// and the Login screen rendered with them (including large text sizes).

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_frontend/main.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/theme/app_theme.dart';
import 'package:mobile_frontend/util/fonts.dart';
import 'package:mobile_frontend/view/screens/authentication/view/login_screen.dart';
import 'package:mobile_frontend/view/widget/text/headline4.dart';
import 'package:mobile_frontend/view/widget/text_field/app_text_form_field.dart';

import 'fakes.dart';
import 'test_app.dart';

/// Bundled weights and their file names.
const _weights = {
  300: 'Light',
  400: 'Regular',
  500: 'Medium',
  600: 'SemiBold',
  700: 'Bold',
};

String _asset(String name) =>
    'assets/fonts/ibm_plex_sans_arabic/IBMPlexSansArabic-$name.ttf';

/// WCAG contrast ratio between two opaque colors.
double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  setUpAll(() async {
    // Real glyph metrics, so the large-text layout checks are meaningful.
    final loader = FontLoader(AppFonts.ibmPlexSansArabic);
    for (final name in _weights.values) {
      loader.addFont(rootBundle.load(_asset(name)));
    }
    await loader.load();
  });

  group('palette (D-A69, red/white/neutral)', () {
    test('semantic roles have the approved values', () {
      expect(AppColor.primary, const Color(0xFFC62828));
      expect(AppColor.onPrimary, const Color(0xFFFFFFFF));
      expect(AppColor.primaryPressed, const Color(0xFFA61B1B));
      expect(AppColor.primaryContainer, const Color(0xFFFDECEC));
      expect(AppColor.onPrimaryContainer, const Color(0xFF8F1D1D));
      expect(AppColor.background, const Color(0xFFFFFFFF));
      expect(AppColor.surface, const Color(0xFFFFFFFF));
      expect(AppColor.surfaceContainer, const Color(0xFFF5F5F5));
      expect(AppColor.textPrimary, const Color(0xFF171717));
      expect(AppColor.textSecondary, const Color(0xFF616161));
      expect(AppColor.navSelected, AppColor.textPrimary);
      expect(AppColor.navUnselected, AppColor.textSecondary);
      expect(AppColor.inputOutline, const Color(0xFF737373));
      expect(AppColor.divider, const Color(0xFFE5E5E5));
      expect(AppColor.selectedTabContainer, const Color(0xFFEEEEEE));
      expect(AppColor.disabledBackground, const Color(0xFFF0F0F0));
      expect(AppColor.disabledForeground, const Color(0xFF767676));
      expect(AppColor.success, const Color(0xFF166534));
      expect(AppColor.error, const Color(0xFFB91C1C));
      expect(AppColor.warning, const Color(0xFF92400E));
      expect(AppColor.focus, const Color(0xFF171717));
    });

    test('theme maps the roles; secondary is neutral, not success', () {
      final theme = AppTheme.light;
      final c = theme.colorScheme;
      expect(c.primary, AppColor.primary);
      expect(c.onPrimary, AppColor.onPrimary);
      expect(c.primaryContainer, AppColor.primaryContainer);
      expect(c.secondary, AppColor.textPrimary);
      expect(c.secondary, isNot(AppColor.success));
      expect(c.onSurface, AppColor.textPrimary);
      expect(c.surface, AppColor.white);
      expect(c.error, AppColor.error);
      expect(c.outline, AppColor.inputOutline);
      expect(c.outlineVariant, AppColor.divider);
      expect(c.surfaceTint, Colors.transparent);
      expect(theme.scaffoldBackgroundColor, AppColor.white);
      expect(theme.appBarTheme.backgroundColor, AppColor.white);
      expect(theme.appBarTheme.scrolledUnderElevation, 0);
      expect(theme.appBarTheme.surfaceTintColor, Colors.transparent);
    });

    test('contrast on white meets the text and non-text minimums', () {
      expect(contrast(AppColor.primary, AppColor.white), greaterThan(5.5));
      expect(contrast(AppColor.onPrimary, AppColor.primary), greaterThan(5.5));
      expect(
        contrast(AppColor.onPrimary, AppColor.primaryPressed),
        greaterThan(7),
      );
      expect(contrast(AppColor.textPrimary, AppColor.white), greaterThan(17));
      expect(contrast(AppColor.textSecondary, AppColor.white), greaterThan(6));
      expect(
        contrast(AppColor.onPrimaryContainer, AppColor.primaryContainer),
        greaterThanOrEqualTo(4.5),
      );
      expect(contrast(AppColor.inputOutline, AppColor.white), greaterThan(4.5));
      expect(
        contrast(AppColor.success, AppColor.white),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(AppColor.warning, AppColor.white),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(AppColor.error, AppColor.white),
        greaterThanOrEqualTo(4.5),
      );
      // Disabled controls are exempt from WCAG 1.4.3; still kept legible
      // (3.99:1 measured).
      expect(
        contrast(AppColor.disabledForeground, AppColor.disabledBackground),
        greaterThan(3.9),
      );
      // Selected tab content on its neutral pill.
      expect(
        contrast(AppColor.navSelected, AppColor.selectedTabContainer),
        greaterThan(15),
      );
    });

    test('field border states stay distinct', () {
      final d = AppTextFieldStyle.defaultsOf(AppTheme.light);
      final states = {
        d.borderColor,
        d.focusedBorderColor,
        d.errorBorderColor,
        d.disabledBorderColor,
      };
      expect(states.length, 4);
      expect(d.focusedErrorBorderColor, d.errorBorderColor);
      expect(d.focusedErrorBorderWidth, greaterThan(d.errorBorderWidth!));
      // Error text stays legible on both surfaces.
      final error = AppTheme.light.colorScheme.error;
      expect(contrast(error, AppColor.background), greaterThanOrEqualTo(4.5));
      expect(contrast(error, AppColor.surface), greaterThanOrEqualTo(4.5));
    });
  });

  group('typography', () {
    test('font family is registered with every bundled weight', () async {
      final manifest =
          jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
      final family = manifest.cast<Map<String, dynamic>>().singleWhere(
        (f) => f['family'] == AppFonts.ibmPlexSansArabic,
      );
      final fonts = (family['fonts'] as List).cast<Map<String, dynamic>>();
      expect(
        {for (final f in fonts) f['weight']: f['asset']},
        {for (final e in _weights.entries) e.key: _asset(e.value)},
      );
      for (final name in _weights.values) {
        expect((await rootBundle.load(_asset(name))).lengthInBytes, isNonZero);
      }
    });

    test('theme text styles use the family name, not an asset path', () {
      final t = AppTheme.light.textTheme;
      for (final style in [
        t.displayLarge,
        t.headlineSmall,
        t.titleMedium,
        t.bodyLarge,
        t.bodyMedium,
        t.bodySmall,
        t.labelLarge,
      ]) {
        expect(style!.fontFamily, AppFonts.ibmPlexSansArabic);
        expect(style.color, AppColor.textPrimary);
      }
      expect(AppFonts.ibmPlexSansArabic.contains('/'), isFalse);
    });

    testWidgets('Headline4 defaults to the family and Ink', (tester) async {
      await tester.pumpWidget(testApp(const Headline4(title: 'عنوان')));
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style!.fontFamily, AppFonts.ibmPlexSansArabic);
      expect(text.style!.color, AppColor.textPrimary);
      expect(text.style!.fontWeight, FontWeight.bold);
    });
  });

  group('Login', () {
    Future<void> launch(WidgetTester tester) async {
      await tester.pumpWidget(
        MainApp(
          connectivityService: FakeInternetConnectionService(),
          authRepository: FakeAuthRepository(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    }

    testWidgets('every text uses IBM Plex Sans Arabic; brand colors apply', (
      tester,
    ) async {
      await launch(tester);
      final texts = tester
          .widgetList<RichText>(find.byType(RichText))
          .where((t) => t.text.style?.fontFamily != 'MaterialIcons')
          .toList();
      expect(texts, isNotEmpty);
      for (final t in texts) {
        expect(
          t.text.style?.fontFamily,
          AppFonts.ibmPlexSansArabic,
          reason: t.text.toPlainText(),
        );
      }
      for (final e in tester.widgetList<EditableText>(
        find.byType(EditableText),
      )) {
        expect(e.style.fontFamily, AppFonts.ibmPlexSansArabic);
        expect(e.style.color, AppColor.textPrimary);
      }

      final scaffold = tester.widget<Scaffold>(
        find.descendant(
          of: find.byType(LoginScreen),
          matching: find.byType(Scaffold),
        ),
      );
      expect(
        scaffold.backgroundColor ?? AppTheme.light.scaffoldBackgroundColor,
        AppColor.white,
      );
      final title = tester.widget<Text>(find.text(l10n.loginTitle).first);
      expect(title.style?.color, AppColor.textPrimary);

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, l10n.loginButton),
      );
      expect(button.style!.backgroundColor!.resolve({}), AppColor.primary);

      for (final d
          in tester
              .widgetList<InputDecorator>(find.byType(InputDecorator))
              .map((i) => i.decoration)) {
        expect(d.fillColor, AppColor.surface);
        expect(
          (d.enabledBorder! as OutlineInputBorder).borderSide.color,
          AppColor.inputOutline,
        );
        expect(
          (d.focusedBorder! as OutlineInputBorder).borderSide.color,
          AppColor.focus,
        );
      }
    });

    for (final scale in [2.0, 3.0]) {
      testWidgets('320 px at text scale $scale with errors: no overflow, '
          'button label not clipped', (tester) async {
        setScreenSize(tester, 320, 640);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await launch(tester);

        final submit = find.widgetWithText(FilledButton, l10n.loginButton);
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(find.text(l10n.usernameRequired), findsOneWidget);
        expect(tester.takeException(), isNull);

        final buttonHeight = tester.getSize(submit).height;
        final labelHeight = tester
            .getSize(
              find.descendant(
                of: submit,
                matching: find.text(l10n.loginButton),
              ),
            )
            .height;
        expect(buttonHeight, greaterThanOrEqualTo(48));
        expect(labelHeight, lessThanOrEqualTo(buttonHeight));
        final para = tester.renderObject<RenderParagraph>(
          find.descendant(of: submit, matching: find.byType(RichText)),
        );
        // Not clipped: the label gets its full natural height.
        expect(
          para.size.height,
          greaterThanOrEqualTo(para.getMaxIntrinsicHeight(para.size.width)),
        );
      });
    }
  });
}
