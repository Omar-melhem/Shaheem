// Widget tests for the visual MainNavigationBar in isolation: order, RTL,
// selected state, the central button, the two indicators, accessibility,
// safe area and responsive widths. Indicator values are injected here only;
// the app itself never invents them.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/theme/app_theme.dart';
import 'package:mobile_frontend/util/fonts.dart';
import 'package:mobile_frontend/view/widget/navigation/main_nav_destination.dart';
import 'package:mobile_frontend/view/widget/navigation/main_navigation_bar.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import 'test_app.dart';

void main() {
  const destinations = MainNavDestination.values;
  final scheme = AppTheme.light.colorScheme;

  Finder item(MainNavDestination d) => find.byKey(MainNavigationBar.itemKey(d));
  final center = find.byKey(MainNavigationBar.centerButtonKey);
  final dot = find.byKey(MainNavigationBar.notificationDotKey);
  final badge = find.byKey(MainNavigationBar.activeOrderBadgeKey);

  /// Pumps the bar at the bottom of the shared Arabic test host.
  Future<void> pumpBar(
    WidgetTester tester, {
    int selectedIndex = 0,
    int unreadCount = 0,
    bool hasActiveOrder = false,
    bool isChecking = false,
    ValueChanged<int>? onSelected,
    TextDirection? direction,
    double textScale = 1,
  }) async {
    Widget bar = MainNavigationBar(
      selectedIndex: selectedIndex,
      unreadCount: unreadCount,
      hasActiveOrder: hasActiveOrder,
      isCheckingActiveOrder: isChecking,
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
    // responsive_framework measures after the first frame; Material
    // finishes its implicit color animation. The loading spinner never
    // settles, so fixed pumps are used for it.
    if (isChecking) {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    } else {
      await tester.pumpAndSettle();
    }
  }

  Material centerMaterial(WidgetTester tester) =>
      tester.widget<Material>(center);

  testWidgets('five items in logical order, each with icon and label', (
    tester,
  ) async {
    await pumpBar(tester);
    expect(destinations.map((d) => d.name), [
      'home',
      'notifications',
      'currentOrder',
      'orderHistory',
      'profile',
    ]);
    expect(
      find.descendant(
        of: find.byType(MainNavigationBar),
        matching: find.byType(InkWell),
      ),
      findsNWidgets(5),
    );
    for (final d in destinations) {
      expect(item(d), findsOneWidget);
      expect(
        find.descendant(of: item(d), matching: find.text(d.label(l10n))),
        findsOneWidget,
      );
      expect(
        find.descendant(of: item(d), matching: find.byType(PhosphorIcon)),
        findsOneWidget,
      );
    }
    // The center opens the current order; it is not a "create" action.
    expect(l10n.currentOrderTitle, 'الطلب الحالي');
    for (final plus in [
      PhosphorIconsRegular.plus,
      PhosphorIconsBold.plus,
      PhosphorIconsFill.plus,
      PhosphorIconsRegular.plusCircle,
      Icons.add,
    ]) {
      expect(find.byIcon(plus), findsNothing);
    }
    expect(find.byIcon(PhosphorIconsRegular.mapPin), findsOneWidget);
  });

  testWidgets('RTL: Home on the right, Profile on the left, center centered', (
    tester,
  ) async {
    setScreenSize(tester, 400, 800);
    await pumpBar(tester);
    final xs = [for (final d in destinations) tester.getCenter(item(d)).dx];
    for (var i = 1; i < xs.length; i++) {
      expect(xs[i], lessThan(xs[i - 1]));
    }
    expect(tester.getCenter(center).dx, moreOrLessEquals(200));
  });

  testWidgets('LTR: order flips with Directionality, center stays centered', (
    tester,
  ) async {
    setScreenSize(tester, 400, 800);
    await pumpBar(tester, direction: TextDirection.ltr);
    final xs = [for (final d in destinations) tester.getCenter(item(d)).dx];
    for (var i = 1; i < xs.length; i++) {
      expect(xs[i], greaterThan(xs[i - 1]));
    }
    expect(tester.getCenter(center).dx, moreOrLessEquals(200));
  });

  testWidgets('selected item differs by icon style and label weight', (
    tester,
  ) async {
    await pumpBar(tester, selectedIndex: MainNavDestination.home.index);
    // Home selected: filled icon, bold primary label.
    expect(find.byIcon(PhosphorIconsFill.house), findsOneWidget);
    expect(find.byIcon(PhosphorIconsRegular.house), findsNothing);
    final home = tester.widget<Text>(find.text(l10n.homeTitle));
    expect(home.style!.fontWeight, FontWeight.w700);
    expect(home.style!.color, scheme.primary);
    // Profile not selected: regular icon, regular muted label.
    expect(find.byIcon(PhosphorIconsRegular.userCircle), findsOneWidget);
    final profile = tester.widget<Text>(find.text(l10n.profileTitle));
    expect(profile.style!.fontWeight, FontWeight.w400);
    expect(profile.style!.color, AppColor.textSecondary);

    await pumpBar(tester, selectedIndex: MainNavDestination.profile.index);
    expect(find.byIcon(PhosphorIconsFill.userCircle), findsOneWidget);
    expect(find.byIcon(PhosphorIconsRegular.house), findsOneWidget);
  });

  testWidgets('tapping an item reports its index', (tester) async {
    final taps = <int>[];
    await pumpBar(tester, onSelected: taps.add);
    for (final d in destinations) {
      await tester.tap(item(d));
    }
    // Tapping the circle itself works too (including its raised part).
    await tester.tapAt(tester.getRect(center).topCenter + const Offset(0, 4));
    expect(taps, [0, 1, 2, 3, 4, 2]);
  });

  testWidgets('center item is circular, raised, larger and above the bar', (
    tester,
  ) async {
    await pumpBar(tester);
    final material = centerMaterial(tester);
    expect(material.shape, isA<CircleBorder>());
    expect(material.elevation, greaterThan(0));
    expect(
      tester.getSize(center),
      const Size.square(MainNavigationBar.centerButtonSize),
    );
    // Rises above the bar surface without leaving the widget's bounds.
    final surfaceTop = tester
        .getRect(find.byKey(MainNavigationBar.surfaceKey))
        .top;
    final circle = tester.getRect(center);
    expect(circle.top, lessThan(surfaceTop));
    expect(
      circle.top,
      greaterThanOrEqualTo(tester.getRect(find.byType(MainNavigationBar)).top),
    );
    // Its label is below the circle.
    expect(
      tester.getRect(find.text(l10n.currentOrderTitle)).top,
      greaterThanOrEqualTo(circle.bottom),
    );
  });

  testWidgets('center: selected and active-order are independent states', (
    tester,
  ) async {
    const centerIndex = 2;
    Color ring(WidgetTester t) =>
        (centerMaterial(t).shape! as CircleBorder).side.color;

    // Neither.
    await pumpBar(tester);
    expect(centerMaterial(tester).color, scheme.primary);
    expect(ring(tester), scheme.surface);
    expect(badge, findsNothing);
    expect(find.byIcon(PhosphorIconsRegular.mapPin), findsOneWidget);

    // Selected only: ring and icon weight change, background does not.
    await pumpBar(tester, selectedIndex: centerIndex);
    expect(centerMaterial(tester).color, scheme.primary);
    expect(ring(tester), AppColor.sand);
    expect(badge, findsNothing);
    expect(find.byIcon(PhosphorIconsFill.mapPin), findsOneWidget);

    // Active order only: background and badge change, ring does not.
    await pumpBar(tester, hasActiveOrder: true);
    expect(centerMaterial(tester).color, scheme.secondary);
    expect(ring(tester), scheme.surface);
    expect(badge, findsOneWidget);
    expect(find.byIcon(PhosphorIconsRegular.mapPin), findsOneWidget);

    // Both at once.
    await pumpBar(tester, selectedIndex: centerIndex, hasActiveOrder: true);
    expect(centerMaterial(tester).color, scheme.secondary);
    expect(ring(tester), AppColor.sand);
    expect(badge, findsOneWidget);
  });

  testWidgets('notification dot only when unread > 0; layout does not shift', (
    tester,
  ) async {
    final bell = find.descendant(
      of: item(MainNavDestination.notifications),
      matching: find.byType(PhosphorIcon),
    );
    final label = find.text(l10n.notificationsTitle);

    await pumpBar(tester, unreadCount: 0);
    expect(dot, findsNothing);
    final iconAt = tester.getCenter(bell);
    final labelAt = tester.getCenter(label);

    await pumpBar(tester, unreadCount: 3);
    expect(dot, findsOneWidget);
    expect(tester.getCenter(bell), iconAt);
    expect(tester.getCenter(label), labelAt);
    // Error color token; in RTL the "end" corner is the icon's left side.
    final decoration =
        tester.widget<Container>(dot).decoration! as BoxDecoration;
    expect(decoration.color, scheme.error);
    expect(tester.getCenter(dot).dx, lessThan(iconAt.dx));
    expect(tester.getCenter(dot).dy, lessThan(iconAt.dy));

    await pumpBar(tester, unreadCount: 3, direction: TextDirection.ltr);
    expect(tester.getCenter(dot).dx, greaterThan(tester.getCenter(bell).dx));
  });

  testWidgets('accessibility: labels, selected state and indicators', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpBar(
      tester,
      selectedIndex: MainNavDestination.orderHistory.index,
      unreadCount: 2,
      hasActiveOrder: true,
    );
    expect(
      tester.getSemantics(item(MainNavDestination.home)),
      isSemantics(
        label: l10n.homeTitle,
        isButton: true,
        isSelected: false,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(item(MainNavDestination.orderHistory)),
      isSemantics(
        label: l10n.orderHistoryTitle,
        isButton: true,
        isSelected: true,
      ),
    );
    expect(
      tester.getSemantics(item(MainNavDestination.notifications)),
      isSemantics(
        label: l10n.notificationsTitle,
        value: l10n.navUnreadNotifications,
      ),
    );
    expect(
      tester.getSemantics(item(MainNavDestination.currentOrder)),
      isSemantics(
        label: l10n.currentOrderTitle,
        hint: l10n.navCurrentOrderHint,
        value: l10n.navActiveOrder,
        isButton: true,
        hasTapAction: true,
      ),
    );
    expect(find.bySemanticsLabel(l10n.mainNavigationLabel), findsOneWidget);

    // Without indicators nothing extra is announced.
    await pumpBar(tester);
    expect(
      tester.getSemantics(item(MainNavDestination.notifications)).value,
      isEmpty,
    );
    expect(
      tester.getSemantics(item(MainNavDestination.currentOrder)).value,
      isEmpty,
    );
    handle.dispose();
  });

  testWidgets('bottom safe area: bar grows and content stays above it', (
    tester,
  ) async {
    setScreenSize(tester, 375, 800);
    await pumpBar(tester);
    final plainHeight = tester.getSize(find.byType(MainNavigationBar)).height;
    expect(
      plainHeight,
      greaterThanOrEqualTo(
        MainNavigationBar.barHeight + MainNavigationBar.centerButtonRise,
      ),
    );

    tester.view.padding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.resetPadding);
    await pumpBar(tester);
    // The inset is added exactly once, not by both the bar and a parent.
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
    // The surface still reaches the screen's bottom edge.
    expect(
      tester.getRect(find.byKey(MainNavigationBar.surfaceKey)).bottom,
      800,
    );
  });

  testWidgets('loading: spinner replaces the icon, size and states unchanged', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final progress = find.byKey(MainNavigationBar.centerProgressKey);
    await pumpBar(tester);
    expect(progress, findsNothing);
    final idleCircle = tester.getRect(center);
    final idleBar = tester.getSize(find.byType(MainNavigationBar));

    await pumpBar(tester, isChecking: true);
    expect(progress, findsOneWidget);
    expect(find.byIcon(PhosphorIconsRegular.mapPin), findsNothing);
    expect(tester.getRect(center), idleCircle);
    expect(tester.getSize(find.byType(MainNavigationBar)), idleBar);
    // Loading alone never looks like an active order.
    expect(centerMaterial(tester).color, scheme.primary);
    expect(badge, findsNothing);
    expect(
      tester.getSemantics(item(MainNavDestination.currentOrder)),
      isSemantics(
        label: l10n.currentOrderTitle,
        value: l10n.navCheckingActiveOrder,
      ),
    );
    handle.dispose();
  });

  testWidgets('labels keep their font size; the bar grows instead', (
    tester,
  ) async {
    setScreenSize(tester, 320, 700);
    await pumpBar(tester);
    final normal = tester.getSize(find.byType(MainNavigationBar)).height;
    Text label() => tester.widget<Text>(find.text(l10n.profileTitle));
    expect(label().style!.fontSize, 12);
    // Never shrunk to fit.
    expect(
      find.descendant(
        of: find.byType(MainNavigationBar),
        matching: find.byType(FittedBox),
      ),
      findsNothing,
    );

    await pumpBar(tester, textScale: 1.6);
    expect(label().style!.fontSize, 12);
    expect(
      MediaQuery.textScalerOf(tester.element(find.text(l10n.profileTitle))),
      const TextScaler.linear(1.6),
    );
    expect(
      tester.getSize(find.byType(MainNavigationBar)).height,
      greaterThan(normal),
    );
    expect(tester.takeException(), isNull);

    // Very large settings are honored up to the documented cap.
    await pumpBar(tester, textScale: 3);
    expect(
      MediaQuery.textScalerOf(tester.element(find.text(l10n.profileTitle))),
      const TextScaler.linear(MainNavigationBar.maxTextScale),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('icon, label and edges keep the same rhythm on every item', (
    tester,
  ) async {
    setScreenSize(tester, 400, 800);
    await pumpBar(tester);
    final barBottom = tester.getRect(find.byType(MainNavigationBar)).bottom;
    final tops = <double>{};
    final iconBottoms = <double>{};
    for (final d in destinations) {
      final label = tester.getRect(find.text(d.label(l10n)));
      tops.add(label.top);
      expect(barBottom - label.bottom, greaterThanOrEqualTo(8), reason: '$d');
      if (d != MainNavDestination.currentOrder) {
        iconBottoms.add(
          tester
              .getRect(
                find.descendant(
                  of: item(d),
                  matching: find.byType(PhosphorIcon),
                ),
              )
              .bottom,
        );
      }
    }
    // All labels start on one line; all four regular icons sit on one line.
    expect(tops.length, 1);
    expect(iconBottoms.length, 1);
    // The circle ends above its own label.
    expect(tester.getRect(center).bottom, lessThanOrEqualTo(tops.single));
  });

  group('responsive', () {
    /// No overflow, usable targets, labels inside their own item, and the
    /// circle clear of its neighbors.
    void expectSound(WidgetTester tester, double width) {
      expect(tester.takeException(), isNull);
      final circle = tester.getRect(center);
      for (final d in destinations) {
        final rect = tester.getRect(item(d));
        expect(rect.width, greaterThanOrEqualTo(48), reason: '$d width');
        expect(rect.height, greaterThanOrEqualTo(48), reason: '$d height');
        final label = tester.getRect(find.text(d.label(l10n)));
        expect(label.left, greaterThanOrEqualTo(rect.left), reason: '$d');
        expect(label.right, lessThanOrEqualTo(rect.right), reason: '$d');
        if (d != MainNavDestination.currentOrder) {
          expect(rect.overlaps(circle), isFalse, reason: '$d under circle');
        }
      }
      expect(circle.center.dx, moreOrLessEquals(width / 2));
      expect(circle.left, greaterThanOrEqualTo(0));
    }

    for (final width in [
      320.0,
      375.0,
      450.5,
      600.0,
      800.5,
      840.0,
      1024.0,
      1440.0,
      1920.5,
    ]) {
      testWidgets('width $width: all indicator states fit', (tester) async {
        setScreenSize(tester, width, 800);
        for (final unread in [0, 5]) {
          for (final active in [false, true]) {
            await pumpBar(
              tester,
              selectedIndex: 2,
              unreadCount: unread,
              hasActiveOrder: active,
            );
            expectSound(tester, width);
          }
        }
        // Content is capped on wide screens instead of spreading out.
        final span =
            tester.getRect(item(MainNavDestination.home)).right -
            tester.getRect(item(MainNavDestination.profile)).left;
        expect(
          span,
          lessThanOrEqualTo(MainNavigationBar.maxContentWidth + 0.01),
        );
      });
    }

    testWidgets('landscape short screen', (tester) async {
      setScreenSize(tester, 740, 320);
      await pumpBar(tester, unreadCount: 1, hasActiveOrder: true);
      expectSound(tester, 740);
    });

    testWidgets('large accessibility text on the narrowest width', (
      tester,
    ) async {
      setScreenSize(tester, 320, 640);
      await pumpBar(tester, textScale: 2.5);
      expectSound(tester, 320);
    });
  });

  group('input contract', () {
    testWidgets('an out-of-range selectedIndex asserts', (tester) async {
      // Negative: rejected by the constructor.
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
      // Past the last destination: rejected when the bar builds.
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

    testWidgets('a negative unreadCount asserts', (tester) async {
      expect(
        () => MainNavigationBar(
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          unreadCount: -1,
        ),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('unreadCount'),
          ),
        ),
      );
    });

    testWidgets('checking and active together: both visible, checking named', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpBar(tester, hasActiveOrder: true, isChecking: true);
      expect(find.byKey(MainNavigationBar.centerProgressKey), findsOneWidget);
      expect(badge, findsOneWidget);
      expect(
        tester
            .getSemantics(item(MainNavDestination.currentOrder))
            .getSemanticsData()
            .value,
        l10n.navCheckingActiveOrder,
      );
      semantics.dispose();
    });

    testWidgets('repeated taps are each reported; the bar keeps no state', (
      tester,
    ) async {
      final taps = <int>[];
      await pumpBar(tester, onSelected: taps.add);
      for (var i = 0; i < 3; i++) {
        await tester.tap(item(MainNavDestination.home));
      }
      await tester.tap(item(MainNavDestination.currentOrder));
      await tester.tap(item(MainNavDestination.currentOrder));
      expect(taps, [0, 0, 0, 2, 2]);
    });
  });

  // Last in the file: loads the real IBM Plex Sans Arabic glyphs, so label
  // widths are real (the default test font draws every glyph as a square).
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

    /// Labels that end in an ellipsis (did not fit their lines).
    List<String> truncated(WidgetTester tester) => [
      for (final d in destinations)
        for (final p in tester.renderObjectList<RenderParagraph>(
          find.descendant(of: item(d), matching: find.byType(RichText)),
        ))
          if (p.didExceedMaxLines) p.text.toPlainText(),
    ];

    /// Cases where every label fits today (see PROJECT_STATUS for the
    /// 320/375 px × text scale ≥ 2 owner decision).
    const fitting = [
      (320.0, 1.0),
      (375.0, 1.0),
      (450.0, 1.0),
      (450.0, 2.0),
      (450.0, 3.0),
    ];
    for (final direction in TextDirection.values) {
      for (final (width, scale) in fitting) {
        testWidgets('$direction $width px × $scale: labels whole, 48 px', (
          tester,
        ) async {
          setScreenSize(tester, width, 800);
          await pumpBar(
            tester,
            direction: direction,
            textScale: scale,
            unreadCount: 1,
            hasActiveOrder: true,
          );
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

    testWidgets('text scale is capped at 2: scale 3 renders like scale 2', (
      tester,
    ) async {
      setScreenSize(tester, 450, 800);
      await pumpBar(tester, textScale: 2);
      final atTwo = tester.getSize(find.byType(MainNavigationBar));
      final labelAtTwo = tester.getSize(find.text(l10n.homeTitle));
      await pumpBar(tester, textScale: 3);
      expect(tester.getSize(find.byType(MainNavigationBar)), atTwo);
      expect(tester.getSize(find.text(l10n.homeTitle)), labelAtTwo);
    });
  });
}
