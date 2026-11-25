// D-A83: the shared order-details section (delivery leg and past orders)
// and the read-only completed-order page. Test-only repositories; nothing
// here proves a real backend, retention policy or database record.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_frontend/domain/entities/active_order.dart';
import 'package:mobile_frontend/domain/entities/declined_offer.dart';
import 'package:mobile_frontend/domain/entities/order_workflow.dart';
import 'package:mobile_frontend/domain/repositories/order_history_repository.dart';
import 'package:mobile_frontend/helper/money/jod_format.dart';
import 'package:mobile_frontend/main.dart';
import 'package:mobile_frontend/util/fonts.dart';
import 'package:mobile_frontend/util/routes/routes_string.dart';
import 'package:mobile_frontend/view/navigation/app_nav_bar.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/widget/active_order_delivery_view.dart';
import 'package:mobile_frontend/view/screens/order_history_screen/cubit/completed_deliveries_cubit.dart';
import 'package:mobile_frontend/view/screens/order_history_screen/view/completed_order_details_screen.dart';
import 'package:mobile_frontend/view/screens/order_history_screen/view/order_history_screen.dart';
import 'package:mobile_frontend/view/screens/order_history_screen/widget/completed_delivery_tile.dart';
import 'package:mobile_frontend/view/widget/navigation/main_nav_destination.dart';
import 'package:mobile_frontend/view/widget/navigation/main_navigation_bar.dart';
import 'package:mobile_frontend/view/widget/order/order_delivery_details.dart';

import 'fakes.dart';
import 'test_app.dart';

String money(int fils) =>
    '${ltrIsolate(formatJodFils(fils))} ${l10n.walletCurrencySymbol}';

Finder inDetails(Finder f) => find.descendant(
  of: find.byKey(OrderDeliveryDetails.sectionKey),
  matching: f,
);

/// History source whose answers each test controls.
class _History implements OrderHistoryRepository {
  _History(this.completed);

  List<CompletedDelivery> completed;
  Object? error;
  int completedCalls = 0;

  @override
  Future<List<DeclinedOfferRecord>> getDeclinedOffers() async => const [];

  @override
  Future<CompletedDeliveriesPage> getCompletedDeliveries({
    String? cursor,
  }) async {
    completedCalls++;
    final e = error;
    if (e != null) throw e;
    return CompletedDeliveriesPage(items: completed);
  }
}

CompletedDelivery delivery(
  String id, {
  String merchant = 'مطعم التلة',
  String? name,
  String? phone,
  String? notes,
  int? fee = 2500,
}) => CompletedDelivery(
  orderId: id,
  deliveredAt: DateTime.utc(2026, 11, 20, 10),
  merchantName: merchant,
  deliveryAreaName: 'الدوار الرابع',
  deliveryFeeFils: fee,
  customerName: name,
  customerPhone: phone,
  deliveryNotes: notes,
);

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

  group('OrderDeliveryDetails', () {
    Future<void> pump(WidgetTester tester, OrderDeliveryDetails details) =>
        tester.pumpWidget(testApp(SingleChildScrollView(child: details)));

    testWidgets('all five details, phone and fee LTR-isolated', (tester) async {
      await pump(
        tester,
        const OrderDeliveryDetails(
          customerName: 'سارة',
          customerPhone: '0790000001',
          deliveryAreaName: 'الدوار السابع',
          deliveryNotes: 'الطابق الثالث',
          deliveryFeeFils: 3000,
        ),
      );
      expect(find.text(l10n.orderDetailsHeading), findsOneWidget);
      expect(find.text('سارة'), findsOneWidget);
      expect(find.text(ltrIsolate('0790000001')), findsOneWidget);
      expect(find.text('الدوار السابع'), findsOneWidget);
      expect(find.text('الطابق الثالث'), findsOneWidget);
      expect(find.text(money(3000)), findsOneWidget);
    });

    for (final blank in [null, '', '   \t\n']) {
      testWidgets(
        'optional rows omitted for ${blank == null ? 'null' : 'blank'}',
        (tester) async {
          await pump(
            tester,
            OrderDeliveryDetails(
              customerName: blank,
              customerPhone: blank,
              deliveryAreaName: 'الدوار السابع',
              deliveryNotes: blank,
              deliveryFeeFils: 3000,
            ),
          );
          expect(find.text(l10n.orderDetailCustomerName), findsNothing);
          expect(find.text(l10n.orderDetailCustomerPhone), findsNothing);
          expect(find.text(l10n.orderDetailDeliveryNotes), findsNothing);
          expect(find.text('الدوار السابع'), findsOneWidget);
          expect(find.text(money(3000)), findsOneWidget);
        },
      );
    }

    testWidgets('missing required values are explicitly unavailable, never '
        'invented; an explicit 0 fee is shown as 0', (tester) async {
      await pump(
        tester,
        const OrderDeliveryDetails(
          deliveryAreaName: ' ',
          deliveryFeeFils: null,
        ),
      );
      expect(find.text(l10n.deliveryAreaUnavailable), findsOneWidget);
      expect(find.text(l10n.orderDetailFeeUnavailable), findsOneWidget);
      expect(find.textContaining('0.000'), findsNothing);

      await pump(
        tester,
        const OrderDeliveryDetails(
          deliveryAreaName: 'صويلح',
          deliveryFeeFils: 0,
        ),
      );
      expect(find.text(money(0)), findsOneWidget);
      expect(find.text(l10n.orderDetailFeeUnavailable), findsNothing);
    });

    testWidgets('one screen-reader sentence per row', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        const OrderDeliveryDetails(
          customerName: 'سارة',
          deliveryAreaName: 'صويلح',
          deliveryFeeFils: 2500,
        ),
      );
      expect(
        find.bySemanticsLabel(
          l10n.orderDetailSemantics(l10n.orderDetailCustomerName, 'سارة'),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          l10n.orderDetailSemantics(l10n.deliveryDestinationHeading, 'صويلح'),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    for (final scale in [2.0, 3.0]) {
      testWidgets('320 px × $scale: long Arabic name/area/notes wrap', (
        tester,
      ) async {
        setScreenSize(tester, 320, 1600);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pump(
          tester,
          const OrderDeliveryDetails(
            customerName: 'عبد الرحمن محمد عبد الله الخطيب العتيبي',
            customerPhone: '0790000001',
            deliveryAreaName: 'دابوق — الحي الغربي قرب المدارس الخاصة',
            deliveryNotes:
                'الطابق الثالث، الجرس معطّل، الرجاء الاتصال عند الوصول وعدم ترك الطلب عند الباب',
            deliveryFeeFils: 123456789,
          ),
        );
        expect(tester.takeException(), isNull);
        for (final p in tester.renderObjectList<RenderParagraph>(
          find.byType(RichText),
        )) {
          expect(p.didExceedMaxLines, isFalse, reason: p.text.toPlainText());
        }
      });
    }
  });

  group('delivery leg', () {
    testWidgets('notes are the delivery notes, never the pickup '
        'instructions; details stay through the stage change', (tester) async {
      final orders = FakeActiveOrderRepository(
        order: const ActiveOrder(
          orderId: 'o-1',
          restaurantName: 'مطعم الاختبار',
          status: ActiveOrderStatus.pickedUp,
          deliveryAreaName: 'صويلح',
          pickupInstructions: 'الاستلام من الباب الخلفي',
          customerName: 'سارة',
          deliveryFeeFils: 3000,
        ),
      );
      await tester.pumpWidget(
        MainApp(
          connectivityService: FakeInternetConnectionService(),
          authRepository: FakeAuthRepository(hasSession: true),
          activeOrderRepository: orders,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ActiveOrderDeliveryView), findsOneWidget);
      expect(inDetails(find.text('سارة')), findsOneWidget);
      expect(inDetails(find.text(money(3000))), findsOneWidget);
      expect(find.text(l10n.orderDetailDeliveryNotes), findsNothing);
      expect(find.text('الاستلام من الباب الخلفي'), findsNothing);
    });
  });

  group('completed-order page', () {
    late _History history;

    Future<void> launch(WidgetTester tester) async {
      setScreenSize(tester, 420, 1400);
      await tester.pumpWidget(
        MainApp(
          connectivityService: FakeInternetConnectionService(),
          authRepository: FakeAuthRepository(hasSession: true),
          orderHistoryRepository: history,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(MainNavigationBar.itemKey(MainNavDestination.orderHistory)),
      );
      await tester.pumpAndSettle();
    }

    setUp(() {
      history = _History([
        delivery(
          'd-1',
          name: 'ريم',
          phone: '0790000002',
          notes: 'تسليم للحارس',
          fee: 3500,
        ),
        delivery('d-2', merchant: 'بيت المعجنات', fee: null),
      ]);
    });

    testWidgets('a row opens that exact order; Back returns to the kept '
        'list; no extra read was made', (tester) async {
      await launch(tester);
      final reads = history.completedCalls;
      await tester.tap(find.byKey(const ValueKey('d-2')));
      await tester.pumpAndSettle();
      expect(find.byType(CompletedOrderDetailsScreen), findsOneWidget);
      expect(
        find.text(l10n.completedOrderMerchantLine('بيت المعجنات')),
        findsOneWidget,
      );
      expect(
        find.text(l10n.completedOrderIdLine(ltrIsolate('d-2'))),
        findsOneWidget,
      );
      expect(find.text(l10n.orderDetailFeeUnavailable), findsOneWidget);
      expect(find.text('ريم'), findsNothing);
      // Read-only: no workflow action on a past order.
      expect(find.text(l10n.startDeliveryAction), findsNothing);
      expect(find.text(l10n.completeDeliveryAction), findsNothing);
      expect(find.text(l10n.pickupConfirmAction), findsNothing);
      expect(history.completedCalls, reads);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(OrderHistoryScreen), findsOneWidget);
      expect(find.byType(CompletedDeliveryTile), findsNWidgets(2));

      await tester.tap(find.byKey(const ValueKey('d-1')));
      await tester.pumpAndSettle();
      expect(find.text('ريم'), findsOneWidget);
      expect(find.text(ltrIsolate('0790000002')), findsOneWidget);
      expect(find.text('تسليم للحارس'), findsOneWidget);
      expect(find.text(money(3500)), findsOneWidget);
    });

    testWidgets('the open page survives a list refresh that no longer '
        'returns its row (historical snapshot)', (tester) async {
      await launch(tester);
      await tester.tap(find.byKey(const ValueKey('d-1')));
      await tester.pumpAndSettle();
      history.completed = [delivery('d-9')];
      final cubit = BlocProvider.of<CompletedDeliveriesCubit>(
        tester.element(find.byType(CompletedOrderDetailsScreen)),
      );
      await cubit.load();
      await tester.pumpAndSettle();
      expect(find.text('ريم'), findsOneWidget);
    });

    testWidgets('a direct link to an order this session never loaded says '
        'unavailable; it never shows another order', (tester) async {
      await launch(tester);
      GoRouter.of(
        tester.element(find.byType(AppNavBar)),
      ).go(RoutesString.completedOrderDetails('unknown-order'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.completedOrderUnavailableTitle), findsOneWidget);
      expect(find.byType(OrderDeliveryDetails), findsNothing);
      expect(find.text('ريم'), findsNothing);
    });

    testWidgets('no history backend: unavailable with the not-configured '
        'explanation', (tester) async {
      await tester.pumpWidget(
        MainApp(
          connectivityService: FakeInternetConnectionService(),
          authRepository: FakeAuthRepository(hasSession: true),
        ),
      );
      await tester.pumpAndSettle();
      GoRouter.of(
        tester.element(find.byType(AppNavBar)),
      ).go(RoutesString.completedOrderDetails('d-1'));
      await tester.pumpAndSettle();
      // My Orders was never opened: nothing is fetched for the page, and it
      // says the details are unavailable instead of spinning.
      expect(find.byType(CompletedOrderDetailsScreen), findsOneWidget);
      expect(find.text(l10n.completedOrderUnavailableTitle), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(OrderDeliveryDetails), findsNothing);
    });

    test('route encodes the order id', () {
      expect(
        RoutesString.completedOrderDetails('a/b c'),
        '/order-history/completed/a%2Fb%20c',
      );
    });
  });
}
