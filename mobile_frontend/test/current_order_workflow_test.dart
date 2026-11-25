// D-A81: the Current Order workflow — code-free pickup confirmation,
// separate Start Delivery,
// completion, reconciliation of unknown outcomes, optional customer phone,
// the Google Maps launcher, and the history/wallet refresh after a
// confirmed completion. Everything runs on test-only repositories; nothing
// here proves a real backend, database write or Google integration.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_frontend/data/repositories/captain_location_repository_placeholder.dart';
import 'package:mobile_frontend/domain/entities/active_order.dart';
import 'package:mobile_frontend/domain/entities/declined_offer.dart';
import 'package:mobile_frontend/domain/entities/order_workflow.dart';
import 'package:mobile_frontend/domain/entities/wallet.dart';
import 'package:mobile_frontend/domain/errors/order_workflow_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/order_history_repository.dart';
import 'package:mobile_frontend/domain/repositories/order_workflow_repository.dart';
import 'package:mobile_frontend/domain/repositories/wallet_repository.dart';
import 'package:mobile_frontend/domain/use_cases/get_active_order.dart';
import 'package:mobile_frontend/domain/use_cases/get_captain_location.dart';
import 'package:mobile_frontend/domain/use_cases/order_workflow.dart';
import 'package:mobile_frontend/helper/money/jod_format.dart';
import 'package:mobile_frontend/helper/navigation/pickup_navigation_launcher.dart';
import 'package:mobile_frontend/main.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/cubit/current_order_cubit.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/view/current_order_screen.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/widget/active_order_delivery_view.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/widget/active_order_pickup_view.dart';
import 'package:mobile_frontend/view/widget/order/order_delivery_details.dart';
import 'package:mobile_frontend/view/widget/pop_up_screen/app_popup.dart';
import 'package:mobile_frontend/view/screens/order_history_screen/view/order_history_screen.dart';
import 'package:mobile_frontend/view/screens/order_history_screen/widget/completed_delivery_tile.dart';
import 'package:mobile_frontend/view/widget/navigation/main_nav_destination.dart';
import 'package:mobile_frontend/view/widget/navigation/main_navigation_bar.dart';

import 'fakes.dart';
import 'test_app.dart';

/// A test order on [status] with optional contact data.
ActiveOrder order({
  String id = 'o-1',
  ActiveOrderStatus status = ActiveOrderStatus.accepted,
  String? phone,
  String? area = 'الدوار السابع',
  String? assignment = 'a-1',
}) => ActiveOrder(
  orderId: id,
  restaurantName: 'مطعم الاختبار',
  status: status,
  assignmentRef: assignment,
  pickupLocation: testPickup,
  deliveryAreaName: area,
  customerPhone: phone,
  customerName: 'سارة',
  deliveryNotes: 'الطابق الثالث',
  deliveryFeeFils: 3000,
);

ActiveOrder advanced(ActiveOrder o, ActiveOrderStatus status) => ActiveOrder(
  orderId: o.orderId,
  restaurantName: o.restaurantName,
  status: status,
  assignmentRef: o.assignmentRef,
  pickupLocation: o.pickupLocation,
  deliveryAreaName: o.deliveryAreaName,
  customerPhone: o.customerPhone,
  customerName: o.customerName,
  deliveryNotes: o.deliveryNotes,
  deliveryFeeFils: o.deliveryFeeFils,
);

/// A server-like workflow over [orders] (test data only). Pickup takes no
/// code: like a server, it validates the assignment and the stage only.
class FakeWorkflow implements OrderWorkflowRepository {
  FakeWorkflow(this.orders);

  final FakeActiveOrderRepository orders;

  /// When set, every command waits on it (a command in flight).
  Completer<void>? gate;

  /// When set, the next command throws it instead.
  Object? error;

  final keys = <String>[];
  int pickupCalls = 0;
  int startCalls = 0;
  int completeCalls = 0;
  OrderOutcome outcome = const OrderOutcomeUnresolved();

  final _receiptsByKey = <String, DeliveryCompletionReceipt>{};

  Future<void> _wait() async {
    if (gate != null) await gate!.future;
    final e = error;
    if (e != null) {
      error = null;
      throw e;
    }
  }

  @override
  Future<ActiveOrder> confirmPickup(
    OrderCommandTarget target, {
    required String operationKey,
  }) async {
    pickupCalls++;
    keys.add(operationKey);
    await _wait();
    final current = orders.order;
    if (current == null ||
        current.orderId != target.orderId ||
        current.assignmentRef != target.assignmentRef ||
        current.leg != ActiveOrderLeg.pickup) {
      throw const OrderStateConflictException();
    }
    final next = advanced(orders.order!, ActiveOrderStatus.pickedUp);
    orders.order = next;
    return next;
  }

  @override
  Future<ActiveOrder> startDelivery(
    OrderCommandTarget target, {
    required String operationKey,
  }) async {
    startCalls++;
    keys.add(operationKey);
    await _wait();
    final next = advanced(orders.order!, ActiveOrderStatus.onTheWay);
    orders.order = next;
    return next;
  }

  @override
  Future<DeliveryCompletionReceipt> completeDelivery(
    OrderCommandTarget target, {
    required String operationKey,
  }) async {
    completeCalls++;
    keys.add(operationKey);
    await _wait();
    return _receiptsByKey.putIfAbsent(operationKey, () {
      orders.order = null;
      return DeliveryCompletionReceipt(
        orderId: target.orderId,
        deliveredAt: DateTime.utc(2026, 11, 22, 12),
      );
    });
  }

  @override
  Future<OrderOutcome> getOrderOutcome(String orderId) async => outcome;
}

int _keySeq = 0;
String testKey() => 'k${++_keySeq}';

CurrentOrderCubit buildCubit(
  FakeActiveOrderRepository orders,
  FakeWorkflow workflow, {
  Duration timeout = const Duration(seconds: 5),
}) {
  final cubit = CurrentOrderCubit(
    GetActiveOrder(orders),
    GetCaptainLocation(const CaptainLocationRepositoryPlaceholder()),
    confirmPickup: ConfirmPickup(workflow, timeout: timeout),
    startDelivery: StartDelivery(workflow, timeout: timeout),
    completeDelivery: CompleteDelivery(workflow, timeout: timeout),
    getOrderOutcome: GetOrderOutcome(workflow),
    operationKey: testKey,
  );
  addTearDown(cubit.close);
  return cubit;
}

CurrentOrderActive active(CurrentOrderCubit c) => c.state as CurrentOrderActive;

void main() {
  group('optional customer phone (D-A81)', () {
    test('null, empty and blank are absent; a value is trimmed', () {
      expect(order().contactPhone, isNull);
      expect(order(phone: '').contactPhone, isNull);
      expect(order(phone: '   ').contactPhone, isNull);
      expect(order(phone: ' 0790000001 ').contactPhone, '0790000001');
    });
  });

  group('CurrentOrderCubit workflow', () {
    late FakeActiveOrderRepository orders;
    late FakeWorkflow workflow;

    setUp(() {
      orders = FakeActiveOrderRepository(order: order());
      workflow = FakeWorkflow(orders);
    });

    test('«تم الاستلام» sends one code-free command; the stage becomes '
        'picked_up only from the server answer', () async {
      final cubit = buildCubit(orders, workflow);
      await cubit.load();
      expect(active(cubit).order.status, ActiveOrderStatus.accepted);
      await cubit.confirmPickup();
      expect(workflow.pickupCalls, 1);
      expect(active(cubit).order.status, ActiveOrderStatus.pickedUp);
      expect(active(cubit).canShowMap, isFalse);
      expect(active(cubit).command, isNull);
      // Picked up: pickup cannot be sent again.
      await cubit.confirmPickup();
      expect(workflow.pickupCalls, 1);
    });

    test('rapid pickup taps send one command', () async {
      final cubit = buildCubit(orders, workflow);
      await cubit.load();
      workflow.gate = Completer<void>();
      final first = cubit.confirmPickup();
      expect(active(cubit).isSending, isTrue);
      unawaited(cubit.confirmPickup());
      unawaited(cubit.confirmPickup());
      workflow.gate!.complete();
      await first;
      expect(workflow.pickupCalls, 1);
      expect(active(cubit).order.status, ActiveOrderStatus.pickedUp);
    });

    for (final (label, error, expected) in [
      (
        'offline',
        const OrderWorkflowNetworkUnavailableException() as Object,
        OrderCommandError.noInternet,
      ),
      (
        'not configured',
        const OrderWorkflowNotConfiguredException(),
        OrderCommandError.notConfigured,
      ),
      (
        'state conflict',
        const OrderStateConflictException(),
        OrderCommandError.stateConflict,
      ),
    ]) {
      test('pickup failure ($label): its own error, the stage stays, and a '
          'new tap may send again', () async {
        final cubit = buildCubit(orders, workflow);
        await cubit.load();
        workflow.error = error;
        await cubit.confirmPickup();
        await pumpEventQueue();
        expect(active(cubit).order.status, ActiveOrderStatus.accepted);
        if (expected != OrderCommandError.stateConflict) {
          expect(active(cubit).command!.error, expected);
        }
        await cubit.confirmPickup();
        expect(workflow.pickupCalls, 2);
        expect(active(cubit).order.status, ActiveOrderStatus.pickedUp);
      });
    }

    test('timeout is unconfirmed, never a pickup; the action stays blocked '
        'until a fresh read, and the retry reuses the same key', () async {
      final cubit = buildCubit(
        orders,
        workflow,
        timeout: const Duration(milliseconds: 20),
      );
      await cubit.load();
      workflow.gate = Completer<void>();
      await cubit.confirmPickup();
      expect(active(cubit).command!.error, OrderCommandError.unconfirmed);
      expect(active(cubit).order.status, ActiveOrderStatus.accepted);
      await cubit.confirmPickup(); // blocked until reconciled
      expect(workflow.pickupCalls, 1);

      await cubit.checkCommandStatus();
      expect(active(cubit).command, isNull);
      expect(active(cubit).order.status, ActiveOrderStatus.accepted);
      workflow.gate = null;
      await cubit.confirmPickup();
      expect(workflow.pickupCalls, 2);
      expect(workflow.keys[1], workflow.keys[0]);
      expect(active(cubit).order.status, ActiveOrderStatus.pickedUp);
    });

    test('unconfirmed pickup that the server applied: the fresh read shows '
        'picked_up (the server decides, not the timeout)', () async {
      final cubit = buildCubit(
        orders,
        workflow,
        timeout: const Duration(milliseconds: 20),
      );
      await cubit.load();
      workflow.gate = Completer<void>();
      final pending = cubit.confirmPickup();
      await pending;
      expect(active(cubit).command!.error, OrderCommandError.unconfirmed);
      workflow.gate!.complete(); // the server applies it late
      await pumpEventQueue();
      expect(active(cubit).order.status, ActiveOrderStatus.accepted);
      await cubit.checkCommandStatus();
      expect(active(cubit).order.status, ActiveOrderStatus.pickedUp);
      expect(active(cubit).command, isNull);
    });

    test('a pickup answer for a stale assignment is dropped', () async {
      final cubit = buildCubit(orders, workflow);
      await cubit.load();
      workflow.gate = Completer<void>();
      final pending = cubit.confirmPickup();
      // The server reassigned the order meanwhile; a fresh read shows it.
      orders.order = order(assignment: 'a-2');
      await cubit.load();
      expect(active(cubit).order.assignmentRef, 'a-2');
      workflow.gate!.complete();
      await pending;
      // The fake server refused the old assignment; nothing advanced.
      expect(active(cubit).order.assignmentRef, 'a-2');
      expect(active(cubit).order.status, ActiveOrderStatus.accepted);
    });

    test('full flow: code-free pickup → Start Delivery → completion', () async {
      final cubit = buildCubit(orders, workflow);
      await cubit.load();
      await cubit.completeDelivery();
      await cubit.startDelivery();
      expect((workflow.startCalls, workflow.completeCalls), (0, 0));
      await cubit.confirmPickup();
      expect(active(cubit).order.status, ActiveOrderStatus.pickedUp);
      await cubit.completeDelivery();
      expect(workflow.completeCalls, 0);
      await cubit.startDelivery();
      expect(active(cubit).order.status, ActiveOrderStatus.onTheWay);
      await cubit.completeDelivery();
      expect(cubit.state, isA<CurrentOrderDelivered>());
    });

    test('Start Delivery is separate and only from picked_up; completion '
        'only after a confirmed start', () async {
      orders.order = order(status: ActiveOrderStatus.pickedUp);
      final cubit = buildCubit(orders, workflow);
      await cubit.load();
      await cubit.completeDelivery();
      expect(workflow.completeCalls, 0);
      await cubit.startDelivery();
      expect(active(cubit).order.status, ActiveOrderStatus.onTheWay);
      await cubit.startDelivery();
      expect(workflow.startCalls, 1);
      await cubit.completeDelivery();
      expect(cubit.state, isA<CurrentOrderDelivered>());
      expect((cubit.state as CurrentOrderDelivered).receipt.orderId, 'o-1');
    });

    test('rapid completion taps send one command', () async {
      orders.order = order(status: ActiveOrderStatus.onTheWay);
      final cubit = buildCubit(orders, workflow);
      await cubit.load();
      workflow.gate = Completer<void>();
      final first = cubit.completeDelivery();
      unawaited(cubit.completeDelivery());
      unawaited(cubit.completeDelivery());
      workflow.gate!.complete();
      await first;
      expect(workflow.completeCalls, 1);
      expect(cubit.state, isA<CurrentOrderDelivered>());
    });

    test('lost completion answer: unknown, the same key is reused after '
        'reconciling "still active", and no success from absence', () async {
      orders.order = order(status: ActiveOrderStatus.onTheWay);
      final cubit = buildCubit(orders, workflow);
      await cubit.load();
      workflow.error = const OrderWorkflowServiceUnavailableException();
      await cubit.completeDelivery();
      expect(active(cubit).command!.error, OrderCommandError.unconfirmed);
      await cubit.completeDelivery(); // blocked until reconciled
      expect(workflow.completeCalls, 1);

      workflow.outcome = OrderOutcomeActive(orders.order!);
      await cubit.checkCommandStatus();
      expect(active(cubit).command, isNull);
      await cubit.completeDelivery();
      expect(workflow.completeCalls, 2);
      expect(workflow.keys[0], workflow.keys[1]);
      expect(cubit.state, isA<CurrentOrderDelivered>());
    });

    test('reconciliation: delivered / cancelled / unresolved', () async {
      orders.order = order(status: ActiveOrderStatus.onTheWay);
      final cubit = buildCubit(orders, workflow);
      await cubit.load();
      workflow.error = const OrderWorkflowServiceUnavailableException();
      await cubit.completeDelivery();
      workflow.outcome = const OrderOutcomeUnresolved();
      await cubit.checkCommandStatus();
      expect(active(cubit).command!.error, OrderCommandError.checkPending);
      workflow.outcome = const OrderOutcomeCancelled();
      await cubit.checkCommandStatus();
      expect(
        (cubit.state as CurrentOrderEnded).reason,
        CurrentOrderEndReason.cancelled,
      );
    });

    test('an "absent" read during an in-flight completion is not applied: '
        'absence is not proof of delivery', () async {
      orders.order = order(status: ActiveOrderStatus.onTheWay);
      final cubit = buildCubit(orders, workflow);
      await cubit.load();
      workflow.gate = Completer<void>();
      final completing = cubit.completeDelivery();
      orders.order = null;
      await cubit.load();
      expect(cubit.state, isA<CurrentOrderActive>());
      workflow.gate!.complete();
      await completing;
      expect(cubit.state, isA<CurrentOrderDelivered>());
    });

    test('a late answer for a reassigned order or a previous session is '
        'dropped', () async {
      final cubit = buildCubit(orders, workflow);
      await cubit.load();
      workflow.gate = Completer<void>();
      final pending = cubit.confirmPickup();
      orders.order = order(assignment: 'a-2');
      // A fresh read shows the new assignment while the old answer waits.
      workflow.gate!.complete();
      cubit.reset();
      await pending;
      expect(cubit.state, isA<CurrentOrderInitial>());
    });

    test('server state conflict re-reads the authoritative order', () async {
      orders.order = order(status: ActiveOrderStatus.pickedUp);
      final cubit = buildCubit(orders, workflow);
      await cubit.load();
      workflow.error = const OrderStateConflictException();
      orders.order = order(status: ActiveOrderStatus.onTheWay);
      final before = orders.calls;
      await cubit.startDelivery();
      await pumpEventQueue();
      expect(orders.calls, before + 1);
      expect(active(cubit).order.status, ActiveOrderStatus.onTheWay);
    });
  });

  group('PickupNavigationLauncher', () {
    const merchant = GeoPoint(latitude: 31.9470123, longitude: 35.88);

    test('driving URI per platform, latitude first', () {
      expect(
        PickupNavigationLauncher.googleMapsUri(
          merchant,
          TargetPlatform.android,
        ).toString(),
        'google.navigation:q=31.9470123,35.8800000&mode=d',
      );
      expect(
        PickupNavigationLauncher.googleMapsUri(
          merchant,
          TargetPlatform.iOS,
        ).toString(),
        'comgooglemaps://?daddr=31.9470123,35.8800000&directionsmode=driving',
      );
    });

    test('outcomes: launched / app unavailable / invalid / failed', () async {
      final fake = _FakeLauncher();
      final launcher = PickupNavigationLauncher(
        launcher: fake,
        platform: TargetPlatform.android,
      );
      expect(await launcher.open(merchant), PickupNavigationOutcome.launched);
      fake.installed = false;
      expect(
        await launcher.open(merchant),
        PickupNavigationOutcome.appUnavailable,
      );
      expect(
        await launcher.open(const GeoPoint(latitude: 0, longitude: 0)),
        PickupNavigationOutcome.invalidDestination,
      );
      expect(
        await launcher.open(null),
        PickupNavigationOutcome.invalidDestination,
      );
      fake
        ..installed = true
        ..throws = true;
      expect(await launcher.open(merchant), PickupNavigationOutcome.failed);
      expect(fake.opened.length, 1);
    });
  });

  group('real app flow', () {
    late FakeActiveOrderRepository orders;
    late FakeWorkflow workflow;
    late _History history;
    late _Wallet wallet;

    Future<void> launch(WidgetTester tester) async {
      await tester.pumpWidget(
        MainApp(
          connectivityService: FakeInternetConnectionService(),
          authRepository: FakeAuthRepository(hasSession: true),
          activeOrderRepository: orders,
          orderWorkflowRepository: workflow,
          orderHistoryRepository: history,
          walletRepository: wallet,
        ),
      );
      await tester.pumpAndSettle();
    }

    setUp(() {
      orders = FakeActiveOrderRepository(order: order(phone: '0790000001'));
      workflow = FakeWorkflow(orders);
      history = _History();
      wallet = _Wallet();
    });

    Future<void> tapPickup(WidgetTester tester) async {
      await tester.tap(find.text(l10n.pickupConfirmAction));
      await tester.pumpAndSettle();
    }

    testWidgets('pickup leg: «تم الاستلام» confirms directly — no code field '
        'or form — and the server-confirmed pickup shows the delivery view '
        'without a map', (tester) async {
      await launch(tester);
      expect(find.byType(CurrentOrderScreen), findsOneWidget);
      expect(find.byType(ActiveOrderPickupView), findsOneWidget);
      expect(find.text(l10n.openInGoogleMaps), findsOneWidget);
      expect(find.text(l10n.completeDeliveryAction), findsNothing);

      expect(find.byType(TextField), findsNothing);
      await tapPickup(tester);
      expect(workflow.pickupCalls, 1);
      expect(find.byType(AppPopup), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(ActiveOrderDeliveryView), findsOneWidget);
      expect(find.byKey(ActiveOrderPickupView.mapAreaKey), findsNothing);
      expect(find.text('الدوار السابع'), findsOneWidget);
      expect(find.byType(OrderDeliveryDetails), findsOneWidget);
      expect(find.text(l10n.orderDetailCustomerPhone), findsOneWidget);
      // D-A83 details survive the server's stage change (picked_up).
      expect(find.text('سارة'), findsOneWidget);
      expect(find.text('الطابق الثالث'), findsOneWidget);
      expect(
        find.text(
          '${ltrIsolate(formatJodFils(3000))} ${l10n.walletCurrencySymbol}',
        ),
        findsOneWidget,
      );
      expect(find.text(l10n.startDeliveryAction), findsOneWidget);
      expect(find.text(l10n.completeDeliveryAction), findsNothing);
    });

    for (final phone in [null, '', '   ']) {
      testWidgets('no customer phone ("$phone"): no contact section, and '
          'start and completion still work', (tester) async {
        orders.order = order(status: ActiveOrderStatus.pickedUp, phone: phone);
        await launch(tester);
        expect(find.byType(OrderDeliveryDetails), findsOneWidget);
        expect(find.text(l10n.orderDetailCustomerPhone), findsNothing);
        await tester.tap(find.text(l10n.startDeliveryAction));
        await tester.pumpAndSettle();
        expect(find.text(l10n.completeDeliveryAction), findsOneWidget);
      });
    }

    testWidgets('offline pickup: the message shows under «تم الاستلام», '
        'the stage stays and a new tap succeeds', (tester) async {
      await launch(tester);
      workflow.error = const OrderWorkflowNetworkUnavailableException();
      await tapPickup(tester);
      expect(find.text(l10n.orderCommandNoInternet), findsOneWidget);
      expect(find.byType(ActiveOrderPickupView), findsOneWidget);
      await tapPickup(tester);
      expect(workflow.pickupCalls, 2);
      expect(find.byType(ActiveOrderDeliveryView), findsOneWidget);
    });

    testWidgets('confirmed completion from a page above the shell: one '
        'command, success, My Orders opens once and the completed list and '
        'the wallet are re-read', (tester) async {
      // Start at Home with no order, then a resume recovers an on-the-way
      // order and pushes Current Order above the mounted shell.
      orders.order = null;
      await launch(tester);
      // Open My Orders once so its completed list has been read.
      await tester.tap(
        find.byKey(MainNavigationBar.itemKey(MainNavDestination.orderHistory)),
      );
      await tester.pumpAndSettle();
      final historyBefore = history.completedCalls;
      final walletBefore = wallet.calls;

      orders.order = order(status: ActiveOrderStatus.onTheWay);
      for (final s in const [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(s);
      }
      await tester.pumpAndSettle();
      expect(find.byType(CurrentOrderScreen), findsOneWidget);

      history.completed = [
        CompletedDelivery(
          orderId: 'o-1',
          deliveredAt: DateTime.utc(2026, 11, 22, 12),
          merchantName: 'مطعم الاختبار',
          deliveryAreaName: 'الدوار السابع',
          deliveryFeeFils: 3000,
        ),
      ];
      await tester.tap(find.text(l10n.completeDeliveryAction));
      await tester.pumpAndSettle();
      // Cancel in the confirmation sends nothing.
      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();
      expect(workflow.completeCalls, 0);
      await tester.tap(find.text(l10n.completeDeliveryAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.completeDeliveryConfirmAction));
      await tester.pumpAndSettle();

      expect(workflow.completeCalls, 1);
      expect(find.byType(CurrentOrderScreen), findsNothing);
      expect(find.byType(OrderHistoryScreen), findsOneWidget);
      expect(find.text(l10n.deliveryCompletedTitle), findsOneWidget);
      expect(history.completedCalls, greaterThan(historyBefore));
      expect(wallet.calls, greaterThan(walletBefore));
      expect(find.byType(CompletedDeliveryTile), findsOneWidget);
      expect(
        find.text(
          l10n.completedDeliveryFeeLine(
            ltrIsolate(formatJodFils(3000)),
            l10n.walletCurrencySymbol,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('no workflow backend: «تم الاستلام» says nothing was sent and '
        'the stage stays', (tester) async {
      await tester.pumpWidget(
        MainApp(
          connectivityService: FakeInternetConnectionService(),
          authRepository: FakeAuthRepository(hasSession: true),
          activeOrderRepository: orders,
        ),
      );
      await tester.pumpAndSettle();
      await tapPickup(tester);
      expect(find.text(l10n.orderCommandNotConfigured), findsOneWidget);
      final cubit = BlocProvider.of<CurrentOrderCubit>(
        tester.element(find.byType(CurrentOrderScreen)),
      );
      expect(active(cubit).order.status, ActiveOrderStatus.accepted);
    });

    testWidgets('320 px at text scale 2.0: pickup and delivery views fit', (
      tester,
    ) async {
      setScreenSize(tester, 320, 640);
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await launch(tester);
      expect(tester.takeException(), isNull);
      await tapPickup(tester);
      expect(tester.takeException(), isNull);
      expect(find.text(l10n.startDeliveryAction), findsOneWidget);
    });
  });
}

class _FakeLauncher implements ExternalAppLauncher {
  bool installed = true;
  bool throws = false;
  final opened = <Uri>[];

  @override
  Future<bool> canOpen(Uri uri) async {
    if (throws) throw StateError('platform');
    return installed;
  }

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return true;
  }
}

class _History implements OrderHistoryRepository {
  List<CompletedDelivery> completed = const [];
  int completedCalls = 0;

  @override
  Future<List<DeclinedOfferRecord>> getDeclinedOffers() async => const [];

  @override
  Future<CompletedDeliveriesPage> getCompletedDeliveries({
    String? cursor,
  }) async {
    completedCalls++;
    return CompletedDeliveriesPage(items: completed);
  }
}

class _Wallet implements WalletRepository {
  int calls = 0;

  @override
  Future<WalletOverview> getWallet({required DateTime historySinceUtc}) async {
    calls++;
    return const WalletOverview(
      summary: WalletSummary(balanceFils: 4000),
      debits: [],
    );
  }

  @override
  Future<CaptainDeliveryStatistics> getDeliveryStatistics() async =>
      const CaptainDeliveryStatistics(deliveredCount: 1);
}
