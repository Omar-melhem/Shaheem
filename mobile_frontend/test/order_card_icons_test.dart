// The one order card, `AppOrderOfferCard` (Tasks 31 and 33: the owner's
// design — icons, spacing, soft divider, forest fee, outlined «رفض»), with
// the real font.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_frontend/domain/entities/order_offer.dart';
import 'package:mobile_frontend/domain/repositories/order_offer_repository.dart';
import 'package:mobile_frontend/domain/use_cases/order_offers.dart';
import 'package:mobile_frontend/helper/money/jod_format.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/theme/app_theme.dart';
import 'package:mobile_frontend/util/fonts.dart';
import 'package:mobile_frontend/view/screens/home_screen/cubit/pending_offers_cubit.dart';
import 'package:mobile_frontend/view/screens/home_screen/widget/pending_offers_sliver.dart';
import 'package:mobile_frontend/view/widget/buttons/app_button.dart';
import 'package:mobile_frontend/view/widget/order/app_order_offer_card.dart';

import 'test_app.dart';

/// The four detail icons, in reading order.
const icons = [
  Icons.storefront_outlined,
  Icons.location_on_outlined,
  Icons.flag_outlined,
  Icons.payments_outlined,
];

/// Offers source with a fixed list (test data only).
class FixedOfferRepository implements OrderOfferRepository {
  FixedOfferRepository(this.offers);
  final List<CaptainOrderOffer> offers;
  @override
  Future<List<CaptainOrderOffer>> getEligibleOffers() async => offers;
  @override
  Future<void> acceptOffer(String offerId) async {}
  @override
  Future<void> declineOffer(String offerId) async {}
}

CaptainOrderOffer offer(
  int i, {
  String merchant = 'مطعم السنابل',
  String area = 'تلاع العلي',
  int fee = 2500,
}) => CaptainOrderOffer(
  id: 'o$i',
  merchantName: merchant,
  pickupLabel: 'الشميساني - عمّان',
  deliveryAreaName: area,
  deliveryFeeFils: fee,
);

const longMerchant =
    'مطعم السنابل للمأكولات الشعبية والمشاوي والحلويات العربية الأصيلة';
const longArea = 'تلاع العلي الشمالي بالقرب من دوار المدينة الرياضية';

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

  Future<void> pump(
    WidgetTester tester,
    Widget card, {
    TextDirection? direction,
  }) => tester.pumpWidget(
    testApp(
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: direction == null
            ? card
            : Directionality(textDirection: direction, child: card),
      ),
    ),
  );

  /// Expects [icon] once, decorative, [size] px, forest, [gap] px on the
  /// logical start side of [text] (right in RTL, left in LTR).
  void expectIconBeside(
    WidgetTester tester,
    IconData icon,
    Finder text,
    TextDirection direction, {
    required double size,
    required double gap,
  }) {
    final iconFinder = find.byIcon(icon);
    expect(iconFinder, findsOneWidget);
    final widget = tester.widget<Icon>(iconFinder);
    expect(widget.size, size);
    expect(widget.color, AppColor.secondary);
    expect(widget.semanticLabel, isNull);
    final iconRect = tester.getRect(iconFinder);
    final textRect = tester.getRect(text);
    if (direction == TextDirection.rtl) {
      expect(iconRect.left, greaterThanOrEqualTo(textRect.right));
      expect(iconRect.left - textRect.right, closeTo(gap, 0.5));
    } else {
      expect(iconRect.right, lessThanOrEqualTo(textRect.left));
      expect(textRect.left - iconRect.right, closeTo(gap, 0.5));
    }
    // Same line as the text's first line.
    expect((iconRect.center.dy - textRect.center.dy).abs(), lessThan(14));
  }

  /// The line above the fee is the softened sand border token, thin.
  void expectSoftDivider(WidgetTester tester) {
    final divider = tester.widget<Divider>(find.byType(Divider));
    expect(divider.thickness, 0.7);
    expect(divider.color, AppColor.border.withValues(alpha: 0.45));
    // Clearly softer than the previous default line: the theme's
    // outlineVariant at 1 px.
    final previous = Theme.of(
      tester.element(find.byType(Divider)),
    ).colorScheme.outlineVariant;
    // ColorScheme.light's default outlineVariant: black.
    expect(previous, const Color(0xFF000000));
    expect(
      divider.color!.computeLuminance(),
      greaterThan(previous.computeLuminance() + 0.5),
    );
  }

  group('AppOrderOfferCard (production)', () {
    Widget card(
      CaptainOrderOffer o, {
      VoidCallback? onAccept,
      VoidCallback? onDecline,
      AppOfferCardAction? busy,
    }) => AppOrderOfferCard(
      offer: o,
      onAccept: onAccept,
      onDecline: onDecline,
      busyAction: busy,
    );

    for (final direction in TextDirection.values) {
      testWidgets('icons beside their texts at the logical start '
          '(${direction.name})', (tester) async {
        await pump(
          tester,
          card(offer(1), onAccept: () {}, onDecline: () {}),
          direction: direction,
        );
        expectIconBeside(
          tester,
          Icons.storefront_outlined,
          find.text('مطعم السنابل'),
          direction,
          size: 24,
          gap: 10,
        );
        expectIconBeside(
          tester,
          Icons.location_on_outlined,
          find.text('${l10n.offerPickupLabel}: الشميساني - عمّان'),
          direction,
          size: 22,
          gap: 10,
        );
        expectIconBeside(
          tester,
          Icons.flag_outlined,
          find.text('${l10n.offerDeliveryAreaLabel}: تلاع العلي'),
          direction,
          size: 22,
          gap: 10,
        );
        expectIconBeside(
          tester,
          Icons.payments_outlined,
          find.text(l10n.offerDeliveryFeeLabel),
          direction,
          size: 22,
          gap: 8,
        );
      });
    }

    testWidgets('soft divider above the fee; fee unchanged (2.500 د.أ)', (
      tester,
    ) async {
      await pump(tester, card(offer(1), onAccept: () {}, onDecline: () {}));
      expectSoftDivider(tester);
      final fee = find.textContaining('2.500');
      expect(fee, findsOneWidget);
      expect(
        tester.widget<Text>(fee).data,
        '${ltrIsolate('2.500')} ${l10n.walletCurrencySymbol}',
      );
      // The amount is forest and bold, as in the owner design.
      expect(tester.widget<Text>(fee).style?.color, AppColor.secondary);
      expect(tester.widget<Text>(fee).style?.fontWeight, FontWeight.bold);
      // Owner spacing: 20 px on both sides of the line.
      final dividerRect = tester.getRect(find.byType(Divider));
      // The area row is as tall as its taller child (22 px icon or text).
      final areaBottom = [
        tester.getRect(find.textContaining('تلاع العلي')).bottom,
        tester.getRect(find.byIcon(Icons.flag_outlined)).bottom,
      ].reduce((a, b) => a > b ? a : b);
      expect(dividerRect.top - areaBottom, closeTo(20, 0.5));
      expect(tester.getRect(fee).top, greaterThan(dividerRect.bottom + 19));
      // Divider between the delivery area and the fee.
      final dividerY = tester.getCenter(find.byType(Divider)).dy;
      expect(
        dividerY,
        greaterThan(tester.getRect(find.textContaining('تلاع العلي')).bottom),
      );
      expect(dividerY, lessThan(tester.getRect(fee).top));
    });

    testWidgets('icons add no screen-reader text; summary and buttons kept', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, card(offer(1), onAccept: () {}, onDecline: () {}));
      expect(
        find.bySemanticsLabel(
          l10n.offerCardSemantics(
            'مطعم السنابل',
            'الشميساني - عمّان',
            'تلاع العلي',
            '2.500',
          ),
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(l10n.offerAccept), findsOneWidget);
      expect(find.bySemanticsLabel(l10n.offerDecline), findsOneWidget);
      handle.dispose();
    });

    testWidgets('buttons: taps, disabled and busy behave as before', (
      tester,
    ) async {
      var accepted = 0;
      var declined = 0;
      await pump(
        tester,
        card(offer(1), onAccept: () => accepted++, onDecline: () => declined++),
      );
      await tester.tap(find.text(l10n.offerAccept));
      await tester.tap(find.text(l10n.offerDecline));
      expect((accepted, declined), (1, 1));

      // Busy: spinner, no taps reach either callback.
      await pump(
        tester,
        card(
          offer(1),
          onAccept: () => accepted++,
          onDecline: () => declined++,
          busy: AppOfferCardAction.accept,
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text(l10n.offerDecline), warnIfMissed: false);
      expect((accepted, declined), (1, 1));

      // Disabled: null callbacks.
      await pump(tester, card(offer(1)));
      await tester.tap(find.text(l10n.offerAccept), warnIfMissed: false);
      expect((accepted, declined), (1, 1));
    });

    testWidgets('«رفض» is outlined in the error color while it can act; '
        'disabled falls back to the shared disabled look', (tester) async {
      AppButton decline() => tester.widget<AppButton>(
        find.widgetWithText(AppButton, l10n.offerDecline),
      );
      final scheme = AppTheme.light.colorScheme;

      await pump(tester, card(offer(1), onAccept: () {}, onDecline: () {}));
      expect(decline().backgroundColor, scheme.surface);
      expect(decline().foregroundColor, scheme.error);
      expect(decline().border, BorderSide(color: scheme.error));
      // «قبول» stays the filled brand action.
      expect(
        tester
            .widget<AppButton>(find.widgetWithText(AppButton, l10n.offerAccept))
            .backgroundColor,
        isNull,
      );

      // Its own command running: still outlined, spinner in error color.
      await pump(
        tester,
        card(
          offer(1),
          onAccept: () {},
          onDecline: () {},
          busy: AppOfferCardAction.decline,
        ),
      );
      expect(decline().border, BorderSide(color: scheme.error));
      expect(decline().isLoading, isTrue);

      // «قبول» running, or no callback: disabled, no red outline.
      await pump(
        tester,
        card(
          offer(1),
          onAccept: () {},
          onDecline: () {},
          busy: AppOfferCardAction.accept,
        ),
      );
      expect(decline().onPressed, isNull);
      expect(decline().border, isNull);
      await pump(tester, card(offer(1)));
      expect(decline().border, isNull);

      // Error text on the white surface stays readable (WCAG AA).
      double contrast(Color a, Color b) {
        final la = a.computeLuminance(), lb = b.computeLuminance();
        return ((la > lb ? la : lb) + 0.05) / ((la > lb ? lb : la) + 0.05);
      }

      expect(contrast(scheme.error, scheme.surface), greaterThan(4.5));
    });

    for (final width in [320.0, 375.0, 450.0]) {
      for (final scale in [1.0, 2.0, 3.0]) {
        for (final direction in TextDirection.values) {
          testWidgets('$width px × $scale ${direction.name}: long names wrap, '
              'nothing overflows, the fee is whole', (tester) async {
            setScreenSize(tester, width, 1600);
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            await pump(
              tester,
              card(
                offer(1, merchant: longMerchant, area: longArea, fee: 12345),
                onAccept: () {},
                onDecline: () {},
              ),
              direction: direction,
            );
            expect(tester.takeException(), isNull);
            for (final icon in icons) {
              expect(find.byIcon(icon), findsOneWidget);
            }
            final fee = find.textContaining('12.345');
            expect(fee, findsOneWidget);
            final cardRect = tester.getRect(find.byType(AppOrderOfferCard));
            final feeRect = tester.getRect(fee);
            expect(feeRect.left, greaterThanOrEqualTo(cardRect.left));
            expect(feeRect.right, lessThanOrEqualTo(cardRect.right));
            // Full width inside the 16 px padding.
            expect(cardRect.width, width - 32);
          });
        }
      }
    }
  });

  group('PendingOffersSliver stays lazy with the new card', () {
    for (final count in [0, 1, 100, 500]) {
      testWidgets('$count offers', (tester) async {
        setScreenSize(tester, 375, 800);
        final cubit = PendingOffersCubit(
          GetEligibleOffers(
            FixedOfferRepository([for (var i = 1; i <= count; i++) offer(i)]),
          ),
          AcceptOrderOffer(FixedOfferRepository(const [])),
          DeclineOrderOffer(FixedOfferRepository(const [])),
          () => true,
        );
        addTearDown(cubit.close);
        await cubit.load();
        await tester.pumpWidget(
          testApp(
            BlocProvider.value(
              value: cubit,
              child: const CustomScrollView(slivers: [PendingOffersSliver()]),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final built = tester
            .widgetList(find.byType(AppOrderOfferCard, skipOffstage: false))
            .length;
        expect(built, lessThanOrEqualTo(count));
        expect(built, lessThan(10));
        if (count > 0) {
          expect(find.byKey(const ValueKey('o1')), findsOneWidget);
        }
      });
    }
  });
}
