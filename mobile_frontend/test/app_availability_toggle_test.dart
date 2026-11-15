// Rendered contract of the shared AppAvailabilityToggle (controlled switch
// row), with the real IBM Plex Sans Arabic glyphs loaded.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/util/fonts.dart';
import 'package:mobile_frontend/view/widget/toggle/app_availability_toggle.dart';

import 'test_app.dart';

const label = 'استقبال عروض الطلبات الجديدة';
const status = 'أنت غير متاح، ولن تصلك عروض طلبات جديدة.';

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

  final row = find.byType(AppAvailabilityToggle);

  Future<void> pumpToggle(
    WidgetTester tester, {
    bool value = false,
    ValueChanged<bool>? onChanged,
    bool nullCallback = false,
    String? supportingText = status,
    bool isBusy = false,
    TextDirection? direction,
  }) {
    Widget toggle = AppAvailabilityToggle(
      value: value,
      onChanged: nullCallback ? null : (onChanged ?? (_) {}),
      label: label,
      supportingText: supportingText,
      isBusy: isBusy,
    );
    if (direction != null) {
      toggle = Directionality(textDirection: direction, child: toggle);
    }
    return tester.pumpWidget(
      testApp(Padding(padding: const EdgeInsets.all(16), child: toggle)),
    );
  }

  testWidgets('a blank label or blank supporting text asserts', (tester) async {
    await tester.pumpWidget(
      testApp(
        AppAvailabilityToggle(value: false, onChanged: (_) {}, label: '  '),
      ),
    );
    expect(tester.takeException(), isAssertionError);
    await tester.pumpWidget(
      testApp(
        AppAvailabilityToggle(
          value: false,
          onChanged: (_) {},
          label: label,
          supportingText: ' ',
        ),
      ),
    );
    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('controlled: a tap sends the intent, the switch does not move', (
    tester,
  ) async {
    final intents = <bool>[];
    await pumpToggle(tester, onChanged: intents.add);
    await tester.tap(row);
    await tester.pump();
    expect(intents, [true]);
    // Still off: only the owner changes `value`.
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

    await pumpToggle(tester, value: true, onChanged: intents.add);
    await tester.tap(find.byType(Switch));
    expect(intents, [true, false]);
  });

  testWidgets('null onChanged: disabled, taps do nothing', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpToggle(tester, nullCallback: true);
    await tester.tap(row);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    expect(
      tester.getSemantics(row),
      isSemantics(
        label: label,
        value: status,
        hasToggledState: true,
        isToggled: false,
        hasEnabledState: true,
        isEnabled: false,
        hasTapAction: false,
      ),
    );
    semantics.dispose();
  });

  testWidgets('busy: taps ignored, spinner shown, not actionable', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final intents = <bool>[];
    await pumpToggle(tester, value: true, onChanged: intents.add, isBusy: true);
    await tester.tap(row);
    await tester.tap(row);
    expect(intents, isEmpty);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // The current value stays visible while busy.
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(
      tester
          .getSemantics(row)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isFalse,
    );
    semantics.dispose();
  });

  testWidgets('semantics: one switch node with name, value and state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpToggle(tester, value: true);
    expect(
      tester.getSemantics(row),
      isSemantics(
        label: label,
        value: status,
        hasToggledState: true,
        isToggled: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    // Label and status are not read a second time by inner nodes.
    expect(find.bySemanticsLabel(label), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('no supporting text: no empty line', (tester) async {
    await pumpToggle(tester, supportingText: null);
    final texts = find.descendant(of: row, matching: find.byType(Text));
    expect(texts, findsOneWidget);
  });

  testWidgets('theme tokens: label Ink bold, status muted, theme switch', (
    tester,
  ) async {
    await pumpToggle(tester, value: true);
    final labelStyle = tester
        .renderObject<RenderParagraph>(find.text(label))
        .text
        .style!;
    expect(labelStyle.color, AppColor.textPrimary);
    expect(labelStyle.fontWeight, FontWeight.bold);
    expect(labelStyle.fontFamily, AppFonts.ibmPlexSansArabic);
    expect(
      tester.renderObject<RenderParagraph>(find.text(status)).text.style!.color,
      AppColor.textSecondary,
    );
    final toggle = tester.widget<Switch>(find.byType(Switch));
    // No per-call colors: the theme decides.
    expect(toggle.activeThumbColor, isNull);
    expect(toggle.activeTrackColor, isNull);
  });

  for (final direction in TextDirection.values) {
    testWidgets('$direction: text at the start, switch at the end', (
      tester,
    ) async {
      await pumpToggle(tester, direction: direction);
      final text = tester.getCenter(find.text(label)).dx;
      final toggle = tester.getCenter(find.byType(Switch)).dx;
      expect(
        direction == TextDirection.rtl ? text > toggle : text < toggle,
        isTrue,
      );
    });
  }

  for (final width in [320.0, 375.0, 450.0]) {
    for (final scale in [1.0, 2.0, 3.0]) {
      testWidgets('$width px × $scale: 48 px target, wraps, no overflow', (
        tester,
      ) async {
        setScreenSize(tester, width, 900);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final intents = <bool>[];
        await pumpToggle(tester, onChanged: intents.add);
        expect(tester.takeException(), isNull);
        expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
        for (final text in [label, status]) {
          expect(
            tester
                .renderObject<RenderParagraph>(find.text(text))
                .didExceedMaxLines,
            isFalse,
          );
        }
        await tester.tap(row);
        expect(intents, [true]);
      });
    }
  }
}
