// Tests for the D-A63 visual foundation: exact brand colors, the bundled
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

  group('brand tokens (D-A63)', () {
    test('the five approved base values are exact', () {
      expect(AppColor.primary, const Color(0xFF8C2335));
      expect(AppColor.secondary, const Color(0xFF263D34));
      expect(AppColor.cream, const Color(0xFFF5F0E8));
      expect(AppColor.background, const Color(0xFFF5F0E8));
      expect(AppColor.sand, const Color(0xFFC8A98A));
      expect(AppColor.ink, const Color(0xFF242424));
      expect(AppColor.textPrimary, AppColor.ink);
    });

    test('theme maps the brand values', () {
      final theme = AppTheme.light;
      expect(theme.colorScheme.primary, AppColor.primary);
      expect(theme.colorScheme.secondary, AppColor.secondary);
      expect(theme.colorScheme.onSurface, AppColor.ink);
      expect(theme.colorScheme.surface, AppColor.white);
      expect(theme.scaffoldBackgroundColor, AppColor.cream);
    });

    test('input border reaches 3:1 on the white fill and cream background', () {
      expect(
        contrast(AppColor.inputBorder, AppColor.surface),
        greaterThanOrEqualTo(3),
      );
      expect(
        contrast(AppColor.inputBorder, AppColor.background),
        greaterThanOrEqualTo(3),
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
        expect(style.color, AppColor.ink);
      }
      expect(AppFonts.ibmPlexSansArabic.contains('/'), isFalse);
    });

    testWidgets('Headline4 defaults to the family and Ink', (tester) async {
      await tester.pumpWidget(testApp(const Headline4(title: 'عنوان')));
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style!.fontFamily, AppFonts.ibmPlexSansArabic);
      expect(text.style!.color, AppColor.ink);
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
        expect(e.style.color, AppColor.ink);
      }

      final scaffold = tester.widget<Scaffold>(
        find.descendant(
          of: find.byType(LoginScreen),
          matching: find.byType(Scaffold),
        ),
      );
      expect(
        scaffold.backgroundColor ?? AppTheme.light.scaffoldBackgroundColor,
        AppColor.cream,
      );
      final title = tester.widget<Text>(find.text(l10n.loginTitle).first);
      expect(title.style?.color, AppColor.ink);

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
          AppColor.inputBorder,
        );
        expect(
          (d.focusedBorder! as OutlineInputBorder).borderSide.color,
          AppColor.primary,
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
