// Widget tests for the visual MainNavigationBar in isolation (D-A69,
// D-A70): four items in logical order, RTL, black/gray selected state with
// a neutral pill, no indicator inputs, accessibility, safe area, label
// growth and responsive widths.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:ui' show Tristate;
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/util/fonts.dart';
import 'package:mobile_frontend/view/widget/navigation/main_nav_destination.dart';
import 'package:mobile_frontend/view/widget/navigation/main_navigation_bar.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import 'test_app.dart';

void main() {
  const destinations = MainNavDestination.values;

  Finder item(MainNavDestination d) => find.byKey(MainNavigationBar.itemKey(d));
  Finder pill(MainNavDestination d) =>
      find.byKey(MainNavigationBar.indicatorKey(d));

  /// Pumps the bar at the bottom of the shared Arabic test host.
  Future<void> pumpBar(
    WidgetTester tester, {
    int selectedIndex = 0,
    ValueChanged<int>? onSelected,
    TextDirection? direction,
    double textScale = 1,
  }) async {
    Widget bar = MainNavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected ?? (_) {},
    );
    if (direction != null) {
      bar = Directionality(textDirection: direction, child: bar);
    }
    await tester.pumpWidget(
      testApp(
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [bar],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Icon iconOf(WidgetTester tester, MainNavDestination d) => tester.widget<Icon>(
    find.descendant(of: item(d), matching: find.byType(Icon)),
  );

  Text labelOf(WidgetTester tester, MainNavDestination d) =>
      tester.widget<Text>(find.text(d.label(l10n)));

  testWidgets('exactly four items in logical order with icon and label', (
    tester,
  ) async {
    await pumpBar(tester);
    expect(destinations, [
      MainNavDestination.home,
      MainNavDestination.orderHistory,
      MainNavDestination.wallet,
      MainNavDestination.profile,
    ]);
    expect(
      [for (final d in destinations) d.label(l10n)],
      ['الرئيسية', 'طلباتي', 'المحفظة', 'حسابي'],
    );
    for (final d in destinations) {
      expect(item(d), findsOneWidget);
      expect(find.text(d.label(l10n)), findsOneWidget);
    }
    // No retired destinations or indicators.
    expect(find.text('الإشعارات'), findsNothing);
    expect(find.text('الطلب الحالي'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(MainNavigationBar),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsNothing,
    );
  });

  testWidgets('RTL: Home on the right, My Account on the left', (tester) async {
    setScreenSize(tester, 400, 800);
    await pumpBar(tester);
    final xs = [for (final d in destinations) tester.getCenter(item(d)).dx];
    for (var i = 1; i < xs.length; i++) {
      expect(xs[i], lessThan(xs[i - 1]));
    }
    // Equal widths.
    final widths = {
      for (final d in destinations) tester.getSize(item(d)).width.round(),
    };
    expect(widths.length, 1);
  });

  testWidgets('LTR: order flips with Directionality', (tester) async {
    setScreenSize(tester, 400, 800);
    await pumpBar(tester, direction: TextDirection.ltr);
    final xs = [for (final d in destinations) tester.getCenter(item(d)).dx];
    for (var i = 1; i < xs.length; i++) {
      expect(xs[i], greaterThan(xs[i - 1]));
    }
  });

  testWidgets('selected: dark Fill icon, bold dark label and neutral pill; '
      'unselected: gray Regular icon; never red', (tester) async {
    await pumpBar(tester, selectedIndex: MainNavDestination.wallet.index);
    final selected = MainNavDestination.wallet;
    expect(iconOf(tester, selected).icon, PhosphorIconsFill.wallet);
    expect(iconOf(tester, selected).color, AppColor.navSelected);
    expect(labelOf(tester, selected).style!.fontWeight, FontWeight.w700);
    expect(labelOf(tester, selected).style!.color, AppColor.navSelected);
    final selectedPill = tester.widget<Container>(pill(selected));
    expect(
      (selectedPill.decoration! as BoxDecoration).color,
      AppColor.selectedTabContainer,
    );
    for (final d in destinations.where((d) => d != selected)) {
      expect(iconOf(tester, d).icon, d.icon);
      expect(iconOf(tester, d).color, AppColor.navUnselected);
      expect(labelOf(tester, d).style!.fontWeight, FontWeight.w400);
      final p = tester.widget<Container>(pill(d));
      expect((p.decoration! as BoxDecoration).color, Colors.transparent);
    }
    for (final d in destinations) {
      expect(iconOf(tester, d).color, isNot(AppColor.primary));
      expect(labelOf(tester, d).style!.color, isNot(AppColor.primary));
    }
    // The surface is white with a light divider.
    final surface = tester.widget<DecoratedBox>(
      find.byKey(MainNavigationBar.surfaceKey),
    );
    final decoration = surface.decoration as BoxDecoration;
    expect(decoration.color, AppColor.surface);
    expect(decoration.border!.top.color, AppColor.divider);
  });

  testWidgets('selecting does not move anything', (tester) async {
    setScreenSize(tester, 400, 800);
    await pumpBar(tester);
    final before = [for (final d in destinations) tester.getRect(item(d))];
    await pumpBar(tester, selectedIndex: 3);
    expect([for (final d in destinations) tester.getRect(item(d))], before);
  });

  testWidgets('tapping an item reports its index (also when selected)', (
    tester,
  ) async {
    final taps = <int>[];
    await pumpBar(tester, onSelected: taps.add);
    for (final d in destinations) {
      await tester.tap(item(d));
    }
    await tester.tap(item(MainNavDestination.home));
    expect(taps, [0, 1, 2, 3, 0]);
  });

  testWidgets('accessibility: labelled buttons with selected state', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpBar(tester, selectedIndex: 1);
    expect(find.bySemanticsLabel(l10n.mainNavigationLabel), findsOneWidget);
    for (final d in destinations) {
      final node = tester.getSemantics(item(d));
      expect(node.label, d.label(l10n));
      expect(node.flagsCollection.isButton, isTrue);
      expect(
        node.flagsCollection.isSelected,
        d.index == 1 ? Tristate.isTrue : Tristate.isFalse,
      );
      expect(tester.getSize(item(d)).shortestSide, greaterThanOrEqualTo(48));
    }
    handle.dispose();
  });

  testWidgets('bottom safe area: added once; surface reaches the edge', (
    tester,
  ) async {
    setScreenSize(tester, 375, 800);
    await pumpBar(tester);
    final plainHeight = tester.getSize(find.byType(MainNavigationBar)).height;
    expect(plainHeight, greaterThanOrEqualTo(MainNavigationBar.barHeight));

    tester.view.padding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.resetPadding);
    await pumpBar(tester);
    expect(
      tester.getSize(find.byType(MainNavigationBar)).height,
      plainHeight + 34,
    );
    for (final d in destinations) {
      expect(
        tester.getRect(find.text(d.label(l10n))).bottom,
        lessThanOrEqualTo(800 - 34),
      );
    }
    expect(
      tester.getRect(find.byKey(MainNavigationBar.surfaceKey)).bottom,
      800,
    );
  });

  testWidgets('labels keep their font size; the bar grows instead', (
    tester,
  ) async {
    setScreenSize(tester, 320, 700);
    await pumpBar(tester);
    final normal = tester.getSize(find.byType(MainNavigationBar)).height;
    expect(labelOf(tester, MainNavDestination.wallet).style!.fontSize, 12);
    expect(
      find.descendant(
        of: find.byType(MainNavigationBar),
        matching: find.byType(FittedBox),
      ),
      findsNothing,
    );
    await pumpBar(tester, textScale: 1.6);
    expect(labelOf(tester, MainNavDestination.wallet).style!.fontSize, 12);
    expect(
      tester.getSize(find.byType(MainNavigationBar)).height,
      greaterThan(normal),
    );
    await pumpBar(tester, textScale: 3);
    expect(
      MediaQuery.textScalerOf(tester.element(find.text(l10n.walletTitle))),
      const TextScaler.linear(MainNavigationBar.maxTextScale),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('icons and labels share one line across all items', (
    tester,
  ) async {
    setScreenSize(tester, 400, 800);
    await pumpBar(tester, selectedIndex: 2);
    final labelTops = {
      for (final d in destinations)
        tester.getRect(find.text(d.label(l10n))).top,
    };
    final pillTops = {
      for (final d in destinations) tester.getRect(pill(d)).top,
    };
    expect(labelTops.length, 1);
    expect(pillTops.length, 1);
  });

  group('input contract', () {
    testWidgets('an out-of-range selectedIndex asserts', (tester) async {
      expect(
        () =>
            MainNavigationBar(selectedIndex: -1, onDestinationSelected: (_) {}),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('selectedIndex'),
          ),
        ),
      );
      await tester.pumpWidget(
        testApp(
          MainNavigationBar(
            selectedIndex: destinations.length,
            onDestinationSelected: (_) {},
          ),
        ),
      );
      expect(
        tester.takeException(),
        isA<AssertionError>().having(
          (e) => e.message,
          'message',
          contains('selectedIndex'),
        ),
      );
    });
  });

  group('real font', () {
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

    List<String> truncated(WidgetTester tester) => [
      for (final d in destinations)
        for (final p in tester.renderObjectList<RenderParagraph>(
          find.descendant(of: item(d), matching: find.byType(RichText)),
        ))
          if (p.didExceedMaxLines) p.text.toPlainText(),
    ];

    for (final direction in TextDirection.values) {
      for (final width in [320.0, 375.0, 450.0]) {
        for (final scale in [1.0, 2.0, 3.0]) {
          testWidgets('$direction $width px × $scale: labels whole, 48 px', (
            tester,
          ) async {
            setScreenSize(tester, width, 800);
            await pumpBar(tester, direction: direction, textScale: scale);
            expect(tester.takeException(), isNull);
            expect(truncated(tester), isEmpty);
            for (final d in destinations) {
              expect(
                tester.getSize(item(d)).shortestSide,
                greaterThanOrEqualTo(48),
              );
            }
          });
        }
      }
    }
  });
}
