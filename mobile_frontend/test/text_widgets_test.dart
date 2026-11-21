// Rendered contract of the shared text widget family (AppTextWidget and its
// eleven wrappers), with the real IBM Plex Sans Arabic glyphs loaded.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/theme/text_themes.dart';
import 'package:mobile_frontend/util/fonts.dart';
import 'package:mobile_frontend/view/widget/text/app_text_widget.dart';
import 'package:mobile_frontend/view/widget/text/body_text1.dart';
import 'package:mobile_frontend/view/widget/text/body_text2.dart';
import 'package:mobile_frontend/view/widget/text/caption.dart';
import 'package:mobile_frontend/view/widget/text/headline1.dart';
import 'package:mobile_frontend/view/widget/text/headline2.dart';
import 'package:mobile_frontend/view/widget/text/headline3.dart';
import 'package:mobile_frontend/view/widget/text/headline4.dart';
import 'package:mobile_frontend/view/widget/text/headline5.dart';
import 'package:mobile_frontend/view/widget/text/headline6.dart';
import 'package:mobile_frontend/view/widget/text/subtitle1.dart';
import 'package:mobile_frontend/view/widget/text/subtitle2.dart';

import 'test_app.dart';

/// Builds one wrapper with the shared parameters.
typedef TextBuilder =
    AppTextWidget Function({
      required String title,
      TextStyle? style,
      Color? color,
      double? fontSize,
      TextDecoration? textDecoration,
      int? maxLines,
      TextAlign? textAlign,
    });

/// One wrapper: how to build it and its approved defaults.
class Variant {
  const Variant(this.name, this.build, this.theme, this.size, this.weight);

  final String name;
  final TextBuilder build;

  /// The `TextThemeStyle` entry it is based on (family, height).
  final TextStyle theme;
  final double size;
  final FontWeight weight;
}

final variants = <Variant>[
  Variant(
    'Headline1',
    ({
      required title,
      style,
      color,
      fontSize,
      textDecoration,
      maxLines,
      textAlign,
    }) => Headline1(
      title: title,
      style: style,
      color: color,
      fontSize: fontSize,
      textDecoration: textDecoration,
      maxLines: maxLines,
      textAlign: textAlign,
    ),
    TextThemeStyle.headline1,
    36,
    FontWeight.bold,
  ),
  Variant(
    'Headline2',
    ({
      required title,
      style,
      color,
      fontSize,
      textDecoration,
      maxLines,
      textAlign,
    }) => Headline2(
      title: title,
      style: style,
      color: color,
      fontSize: fontSize,
      textDecoration: textDecoration,
      maxLines: maxLines,
      textAlign: textAlign,
    ),
    TextThemeStyle.headline2,
    26,
    FontWeight.bold,
  ),
  Variant(
    'Headline3',
    ({
      required title,
      style,
      color,
      fontSize,
      textDecoration,
      maxLines,
      textAlign,
    }) => Headline3(
      title: title,
      style: style,
      color: color,
      fontSize: fontSize,
      textDecoration: textDecoration,
      maxLines: maxLines,
      textAlign: textAlign,
    ),
    TextThemeStyle.headline3,
    24,
    FontWeight.bold,
  ),
  Variant(
    'Headline4',
    ({
      required title,
      style,
      color,
      fontSize,
      textDecoration,
      maxLines,
      textAlign,
    }) => Headline4(
      title: title,
      style: style,
      color: color,
      fontSize: fontSize,
      textDecoration: textDecoration,
      maxLines: maxLines,
      textAlign: textAlign,
    ),
    TextThemeStyle.headline4,
    20,
    FontWeight.bold,
  ),
  Variant(
    'Headline5',
    ({
      required title,
      style,
      color,
      fontSize,
      textDecoration,
      maxLines,
      textAlign,
    }) => Headline5(
      title: title,
      style: style,
      color: color,
      fontSize: fontSize,
      textDecoration: textDecoration,
      maxLines: maxLines,
      textAlign: textAlign,
    ),
    TextThemeStyle.headline5,
    16,
    FontWeight.w400,
  ),
  Variant(
    'Headline6',
    ({
      required title,
      style,
      color,
      fontSize,
      textDecoration,
      maxLines,
      textAlign,
    }) => Headline6(
      title: title,
      style: style,
      color: color,
      fontSize: fontSize,
      textDecoration: textDecoration,
      maxLines: maxLines,
      textAlign: textAlign,
    ),
    TextThemeStyle.headline6,
    14,
    FontWeight.normal,
  ),
  Variant(
    'BodyText1',
    ({
      required title,
      style,
      color,
      fontSize,
      textDecoration,
      maxLines,
      textAlign,
    }) => BodyText1(
      title: title,
      style: style,
      color: color,
      fontSize: fontSize,
      textDecoration: textDecoration,
      maxLines: maxLines,
      textAlign: textAlign,
    ),
    TextThemeStyle.bodyText1,
    15,
    FontWeight.bold,
  ),
  Variant(
    'BodyText2',
    ({
      required title,
      style,
      color,
      fontSize,
      textDecoration,
      maxLines,
      textAlign,
    }) => BodyText2(
      title: title,
      style: style,
      color: color,
      fontSize: fontSize,
      textDecoration: textDecoration,
      maxLines: maxLines,
      textAlign: textAlign,
    ),
    TextThemeStyle.bodyText2,
    13,
    FontWeight.bold,
  ),
  Variant(
    'Subtitle1',
    ({
      required title,
      style,
      color,
      fontSize,
      textDecoration,
      maxLines,
      textAlign,
    }) => Subtitle1(
      title: title,
      style: style,
      color: color,
      fontSize: fontSize,
      textDecoration: textDecoration,
      maxLines: maxLines,
      textAlign: textAlign,
    ),
    TextThemeStyle.subtitle1,
    10,
    FontWeight.bold,
  ),
  Variant(
    'Subtitle2',
    ({
      required title,
      style,
      color,
      fontSize,
      textDecoration,
      maxLines,
      textAlign,
    }) => Subtitle2(
      title: title,
      style: style,
      color: color,
      fontSize: fontSize,
      textDecoration: textDecoration,
      maxLines: maxLines,
      textAlign: textAlign,
    ),
    TextThemeStyle.subtitle2,
    12,
    FontWeight.bold,
  ),
  Variant(
    'Caption',
    ({
      required title,
      style,
      color,
      fontSize,
      textDecoration,
      maxLines,
      textAlign,
    }) => Caption(
      title: title,
      style: style,
      color: color,
      fontSize: fontSize,
      textDecoration: textDecoration,
      maxLines: maxLines,
      textAlign: textAlign,
    ),
    TextThemeStyle.caption,
    9,
    FontWeight.bold,
  ),
];

/// The style actually painted (after Text merges it with DefaultTextStyle).
TextStyle painted(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).text.style!;

RenderParagraph paragraph(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text));

void main() {
  setUpAll(() async {
    // Real glyph metrics (the default test font draws squares).
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

  const title = 'نص تجريبي';

  group('defaults (no overrides)', () {
    for (final v in variants) {
      testWidgets('${v.name}: Plex, ${v.size}, ${v.weight}, Ink, 1 line', (
        tester,
      ) async {
        await tester.pumpWidget(testApp(v.build(title: title)));
        final style = painted(tester, title);
        expect(style.fontFamily, AppFonts.ibmPlexSansArabic);
        expect(style.fontSize, v.size);
        expect(style.fontWeight, v.weight);
        expect(style.color, AppColor.textPrimary);
        expect(style.height, v.theme.height);
        // The theme's DefaultTextStyle supplies "none".
        expect(style.decoration, anyOf(isNull, TextDecoration.none));
        final text = tester.widget<Text>(find.byType(Text));
        expect(text.maxLines, 1);
        expect(text.overflow, TextOverflow.ellipsis);
        expect(text.textAlign, TextAlign.start);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('style precedence: dedicated > style > default', () {
    for (final v in variants) {
      testWidgets('${v.name}: a partial style keeps family, weight, color', (
        tester,
      ) async {
        await tester.pumpWidget(
          testApp(v.build(title: title, style: const TextStyle(fontSize: 22))),
        );
        final style = painted(tester, title);
        expect(style.fontSize, 22);
        expect(style.fontFamily, AppFonts.ibmPlexSansArabic);
        expect(style.fontWeight, v.weight);
        expect(style.color, AppColor.textPrimary);
        expect(style.height, v.theme.height);
      });

      testWidgets('${v.name}: style values win over defaults', (tester) async {
        await tester.pumpWidget(
          testApp(
            v.build(
              title: title,
              style: const TextStyle(
                color: AppColor.success,
                fontWeight: FontWeight.w300,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
        );
        final style = painted(tester, title);
        expect(style.color, AppColor.success);
        expect(style.fontWeight, FontWeight.w300);
        expect(style.decoration, TextDecoration.lineThrough);
        expect(style.fontSize, v.size);
      });

      testWidgets('${v.name}: dedicated color/size/decoration beat style', (
        tester,
      ) async {
        await tester.pumpWidget(
          testApp(
            v.build(
              title: title,
              style: const TextStyle(
                color: AppColor.success,
                fontSize: 22,
                decoration: TextDecoration.lineThrough,
              ),
              color: AppColor.primary,
              fontSize: 30,
              textDecoration: TextDecoration.underline,
            ),
          ),
        );
        final style = painted(tester, title);
        expect(style.color, AppColor.primary);
        expect(style.fontSize, 30);
        expect(style.decoration, TextDecoration.underline);
        expect(style.fontFamily, AppFonts.ibmPlexSansArabic);
      });

      testWidgets('${v.name}: dedicated overrides alone', (tester) async {
        await tester.pumpWidget(
          testApp(
            v.build(
              title: title,
              color: AppColor.primary,
              fontSize: 30,
              textDecoration: TextDecoration.underline,
            ),
          ),
        );
        final style = painted(tester, title);
        expect(style.color, AppColor.primary);
        expect(style.fontSize, 30);
        expect(style.decoration, TextDecoration.underline);
        expect(style.fontWeight, v.weight);
        expect(style.fontFamily, AppFonts.ibmPlexSansArabic);
      });
    }

    // The four wrappers that expose a dedicated fontWeight.
    final weighted =
        <
          String,
          AppTextWidget Function({TextStyle? style, FontWeight? fontWeight})
        >{
          'Headline4': ({style, fontWeight}) =>
              Headline4(title: title, style: style, fontWeight: fontWeight),
          'Headline5': ({style, fontWeight}) =>
              Headline5(title: title, style: style, fontWeight: fontWeight),
          'BodyText1': ({style, fontWeight}) =>
              BodyText1(title: title, style: style, fontWeight: fontWeight),
          'BodyText2': ({style, fontWeight}) =>
              BodyText2(title: title, style: style, fontWeight: fontWeight),
        };
    for (final MapEntry(key: name, value: build) in weighted.entries) {
      testWidgets('$name: dedicated fontWeight beats style fontWeight', (
        tester,
      ) async {
        await tester.pumpWidget(
          testApp(
            build(
              style: const TextStyle(fontWeight: FontWeight.w300),
              fontWeight: FontWeight.w600,
            ),
          ),
        );
        expect(painted(tester, title).fontWeight, FontWeight.w600);
      });

      testWidgets('$name: dedicated fontWeight alone', (tester) async {
        await tester.pumpWidget(testApp(build(fontWeight: FontWeight.w500)));
        expect(painted(tester, title).fontWeight, FontWeight.w500);
      });
    }

    testWidgets('a style with inherit: false replaces the default entirely', (
      tester,
    ) async {
      // Flutter's TextStyle.merge rule; dedicated values still apply.
      await tester.pumpWidget(
        testApp(
          const BodyText1(
            title: title,
            style: TextStyle(
              inherit: false,
              fontSize: 18,
              color: AppColor.selectedTabContainer,
            ),
            color: AppColor.primary,
          ),
        ),
      );
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style!.inherit, isFalse);
      expect(text.style!.fontSize, 18);
      expect(text.style!.color, AppColor.primary);
      expect(text.style!.fontWeight, isNull);
    });
  });

  group('direction, alignment, content', () {
    for (final direction in TextDirection.values) {
      testWidgets('$direction: TextAlign.start follows the direction', (
        tester,
      ) async {
        setScreenSize(tester, 375, 300);
        await tester.pumpWidget(
          testApp(
            Directionality(
              textDirection: direction,
              child: const SizedBox(
                width: 300,
                child: BodyText1(title: 'رقم 42 Order'),
              ),
            ),
          ),
        );
        final p = paragraph(tester, 'رقم 42 Order');
        expect(p.textDirection, direction);
        expect(p.textAlign, TextAlign.start);
        final box = tester.getRect(find.byType(SizedBox).last);
        final glyphs = tester.getRect(find.text('رقم 42 Order'));
        // The paragraph fills the box; the glyph run hugs the start side.
        final line = p.getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: 12),
        );
        final first = line
            .map((b) => b.toRect())
            .reduce((a, b) => a.expandToInclude(b));
        if (direction == TextDirection.rtl) {
          expect(
            glyphs.left + first.right,
            moreOrLessEquals(box.right, epsilon: 1),
          );
        } else {
          expect(
            glyphs.left + first.left,
            moreOrLessEquals(box.left, epsilon: 1),
          );
        }
      });
    }

    testWidgets('alignment, maxLines and overflow overrides are forwarded', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          const Headline6(
            title: title,
            textAlign: TextAlign.center,
            maxLines: 3,
          ),
        ),
      );
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.textAlign, TextAlign.center);
      expect(text.maxLines, 3);
      await tester.pumpWidget(
        testApp(const Caption(title: title, overflow: TextOverflow.fade)),
      );
      expect(
        tester.widget<Text>(find.byType(Text)).overflow,
        TextOverflow.fade,
      );
    });

    testWidgets('semantics: the visible text once; empty text is allowed', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(testApp(const Headline3(title: title)));
      expect(find.bySemanticsLabel(title), findsOneWidget);
      await tester.pumpWidget(testApp(const Headline3(title: '')));
      expect(tester.takeException(), isNull);
      expect(find.byType(Text), findsOneWidget);
      semantics.dispose();
    });
  });

  group('widths and text scales (real font)', () {
    const sentence =
        'تعذر الاتصال بالخادم، يرجى التحقق من الاتصال والمحاولة مرة أخرى';
    for (final width in [320.0, 375.0, 450.0]) {
      for (final scale in [1.0, 2.0, 3.0]) {
        testWidgets(
          '$width px × $scale: wraps when allowed; 1 line by default',
          (tester) async {
            setScreenSize(tester, width, 2000);
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            await tester.pumpWidget(
              testApp(
                const Column(
                  children: [
                    BodyText1(title: sentence, maxLines: 20),
                    Headline2(title: 'قصير'),
                  ],
                ),
              ),
            );
            expect(tester.takeException(), isNull);
            // With room for more lines, nothing is cut off.
            expect(paragraph(tester, sentence).didExceedMaxLines, isFalse);
            // A short headline fits on its one line at every size tested.
            expect(paragraph(tester, 'قصير').didExceedMaxLines, isFalse);
            expect(
              painted(tester, sentence).fontFamily,
              AppFonts.ibmPlexSansArabic,
            );
            // The default stays one line with an ellipsis (intended): a sentence
            // that does not fit is cut off rather than wrapped.
            await tester.pumpWidget(testApp(const BodyText1(title: sentence)));
            final oneLine = paragraph(tester, sentence);
            expect(oneLine.maxLines, 1);
            expect(oneLine.overflow, TextOverflow.ellipsis);
          },
        );
      }
    }
  });
}
