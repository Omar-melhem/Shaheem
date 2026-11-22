// Widget tests for the repaired shared text widgets: they keep their
// original defaults. (The AppTools loading/dialog/time helpers and their
// tests were removed in R05 as verified-dead code.)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/util/fonts.dart';
import 'package:mobile_frontend/view/widget/text/body_text1.dart';
import 'package:mobile_frontend/view/widget/text/caption.dart';
import 'package:mobile_frontend/view/widget/text/headline4.dart';
import 'package:mobile_frontend/view/widget/text/headline5.dart';

import 'test_app.dart';

/// Uses the shared test host (localization, theme, breakpoints).
Widget host(Widget child, {TargetPlatform? platform}) =>
    testApp(child, platform: platform);

/// The rendered Text for the only text widget under test.
Text renderedText(WidgetTester tester) =>
    tester.widget<Text>(find.byType(Text));

void main() {
  group('text widgets', () {
    testWidgets('BodyText1 defaults: 15, bold, Ink, 1 line, ellipsis, Plex', (
      tester,
    ) async {
      await tester.pumpWidget(host(const BodyText1(title: 'نص')));
      final text = renderedText(tester);
      expect(text.style!.fontSize, 15);
      expect(text.style!.fontWeight, FontWeight.bold);
      expect(text.style!.color, AppColor.textPrimary);
      expect(text.style!.fontFamily, AppFonts.ibmPlexSansArabic);
      expect(text.style!.height, 1.2);
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(text.textAlign, TextAlign.start);
    });

    testWidgets('overrides: color, size, weight, lines, align', (tester) async {
      await tester.pumpWidget(
        host(
          const Headline4(
            title: 'عنوان',
            color: AppColor.primary,
            fontSize: 30,
            fontWeight: FontWeight.w300,
            maxLines: 3,
            textAlign: TextAlign.center,
          ),
        ),
      );
      final text = renderedText(tester);
      expect(text.style!.color, AppColor.primary);
      expect(text.style!.fontSize, 30);
      expect(text.style!.fontWeight, FontWeight.w300);
      expect(text.maxLines, 3);
      expect(text.textAlign, TextAlign.center);
    });

    testWidgets('Headline5 keeps theme weight w400 when none given', (
      tester,
    ) async {
      await tester.pumpWidget(host(const Headline5(title: 'x')));
      expect(renderedText(tester).style!.fontWeight, FontWeight.w400);
    });

    testWidgets('style replaces the default; textDecoration now applied', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const Caption(
            title: 'x',
            style: TextStyle(fontSize: 22),
            textDecoration: TextDecoration.underline,
          ),
        ),
      );
      final style = renderedText(tester).style!;
      expect(style.fontSize, 22);
      expect(style.decoration, TextDecoration.underline);
    });
  });
}
