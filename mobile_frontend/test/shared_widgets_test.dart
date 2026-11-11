// Widget tests for the repaired shared components: text widgets keep their
// original defaults, and AppTools loading/dialog helpers work without GetX.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/util/tools/android_loading.dart';
import 'package:mobile_frontend/util/tools/ios_loading.dart';
import 'package:mobile_frontend/util/tools/tools.dart';
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
    testWidgets('BodyText1 defaults: 15, bold, black, 1 line, ellipsis', (
      tester,
    ) async {
      await tester.pumpWidget(host(const BodyText1(title: 'نص')));
      final text = renderedText(tester);
      expect(text.style!.fontSize, 15);
      expect(text.style!.fontWeight, FontWeight.bold);
      expect(text.style!.color, AppColor.black);
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

  group('AppTools loading', () {
    Future<BuildContext> pumpHost(
      WidgetTester tester,
      TargetPlatform platform,
    ) async {
      late BuildContext captured;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              captured = context;
              return const SizedBox();
            },
          ),
          platform: platform,
        ),
      );
      return captured;
    }

    testWidgets('Android: AndroidLoading in a dialog, then hidden', (
      tester,
    ) async {
      final context = await pumpHost(tester, TargetPlatform.android);
      appTools.showLoading(context);
      await tester.pump();
      expect(find.byType(AndroidLoading), findsOneWidget);
      expect(find.text(l10n.loading), findsOneWidget);

      appTools.hideLoading(context);
      await tester.pumpAndSettle();
      expect(find.byType(AndroidLoading), findsNothing);
    });

    testWidgets('iOS: IosLoading HUD, then hidden', (tester) async {
      final context = await pumpHost(tester, TargetPlatform.iOS);
      appTools.showLoading(context);
      await tester.pump();
      expect(find.byType(IosLoading), findsOneWidget);
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);

      appTools.hideLoading(context);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(IosLoading), findsNothing);
    });

    testWidgets('confirm dialog default buttons close it', (tester) async {
      final context = await pumpHost(tester, TargetPlatform.android);
      appTools.showAlertDialogTwoFun(context);
      await tester.pumpAndSettle();
      expect(find.text(l10n.proceedQuestion), findsOneWidget);

      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();
      expect(find.text(l10n.proceedQuestion), findsNothing);
    });
  });

  test('timeFormatter formats seconds as mm:ss', () {
    expect(appTools.timeFormatter(0), '00:00');
    expect(appTools.timeFormatter(75), '01:15');
  });
}
