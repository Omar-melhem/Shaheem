// SHAHM DEMO (Task 37) — the in-memory "server" of the demonstration.
// Removed by `bash tool/demo/remove_demo.sh --apply`.

import 'package:flutter/foundation.dart';
import 'package:mobile_frontend/demo/model/demo_fixtures.dart';
import 'package:mobile_frontend/domain/entities/active_order.dart';
import 'package:mobile_frontend/domain/entities/app_user.dart';
import 'package:mobile_frontend/domain/entities/captain_availability.dart';
import 'package:mobile_frontend/domain/entities/declined_offer.dart';
import 'package:mobile_frontend/domain/entities/order_offer.dart';
import 'package:mobile_frontend/domain/entities/order_workflow.dart';
import 'package:mobile_frontend/domain/entities/wallet.dart';
import 'package:mobile_frontend/domain/errors/order_offer_exceptions.dart';
import 'package:mobile_frontend/domain/errors/order_workflow_exceptions.dart';

/// Which active order the demo server reports.
enum DemoOrderScenario {
  /// No active order (the start state), so a new offer can be accepted.
  none,

  /// The fixture's pre-assigned order (`current_order.json` → `assigned`).
  assigned,
}

/// A fictional signed-in demo captain. The token is only held here, in
/// memory: nothing sends, stores or logs it.
class DemoSession {
  const DemoSession({required this.user, required this.accessToken});

  final AppUser user;
  final String accessToken;
}

/// One offer the demo server lists, with its resolved expiry and the
/// fixture seed it came from (fictional pickup point and phone).
class _LiveOffer {
  _LiveOffer(this.offer, this.expiresAt, this.seed);

  final CaptainOrderOffer offer;
  final DateTime? expiresAt;
  final DemoOfferSeed seed;
}

/// The money facts of the demo active order, kept by the demo server only
/// (the app never receives or computes them for the debit).
class _ActiveMoney {
  const _ActiveMoney({required this.feeFils, required this.commissionFils});

  final int feeFils;
  final int commissionFils;
}

/// Everything the demo repositories read and change, in memory only.
///
/// It plays the backend for the demo: it decides what is eligible, accepts
/// or declines atomically (one active order per captain, expiry, already
/// answered), and records the result. Relative fixture times are resolved
/// against [clock] each time the data is reset (sign-in, reset, sign-out),
/// so the 7-day wallet window stays meaningful on any date. No timer, no
/// file write, no network. Listeners are told after every change, so the
/// shell can re-read through the real Cubits.
class DemoState extends ChangeNotifier {
  DemoState(this.fixtures, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    _resetData();
  }

  final DemoFixtures fixtures;
  final DateTime Function() _clock;

  /// At most this many demo-injected offers can wait for an answer.
  static const maxInjectedOffers = 3;

  DemoSession? _session;
  late List<_LiveOffer> _offers;
  late List<DeclinedOfferRecord> _declined;
  late WalletOverview _wallet;
  late CaptainAvailability _availability;
  ActiveOrder? _activeOrder;
  _ActiveMoney? _activeMoney;

  /// Completed deliveries, as the demo server records them.
  late List<CompletedDelivery> _completed;

  /// Receipts by operation key, so a repeated completion with the same key
  /// returns the same result and creates no second debit (D-A56).
  final Map<String, DeliveryCompletionReceipt> _completionsByKey = {};

  /// Completed orders, for the outcome lookup.
  final Map<String, DeliveryCompletionReceipt> _completedOrders = {};
  DemoOrderScenario _scenario = DemoOrderScenario.none;
  int _sequence = 0;
  int _resetCount = 0;

  DateTime get now => _clock();

  /// The signed-in demo captain, or null.
  DemoSession? get session => _session;

  DemoOrderScenario get scenario => _scenario;

  /// Grows each time the data returns to the fixtures (sign-in, reset,
  /// sign-out). The shell bridge uses it to re-read the declined-offers
  /// history only after a reset (Task 38); a decline is refreshed by the
  /// app's own confirmed-decline path instead.
  int get resetCount => _resetCount;

  /// Signs the fictional captain in (credentials from `auth.json`) and
  /// starts from fresh fixtures. False for other credentials.
  ///
  /// A pre-assigned order scenario chosen before (and kept through
  /// sign-out) is applied to the fresh session, so a new sign-in shows the
  /// app's startup routing to Current Order (D-A73). Demo only.
  bool signIn(String username, String password) {
    if (username != fixtures.username || password != fixtures.password) {
      return false;
    }
    final scenario = _scenario;
    _resetData();
    _applyScenario(scenario);
    _session = DemoSession(
      user: AppUser(
        id: fixtures.captainId,
        displayName: fixtures.captainName,
        phone: fixtures.captainPhone,
        role: fixtures.captainRole,
      ),
      accessToken: fixtures.accessToken,
    );
    notifyListeners();
    return true;
  }

  /// Forgets the captain, the token and every change, except the chosen
  /// active-order scenario (see [signIn]).
  void signOut() {
    final scenario = _scenario;
    _session = null;
    _resetData();
    _scenario = scenario;
    notifyListeners();
  }

  /// «إعادة ضبط بيانات العرض»: back to the original fixtures (the captain
  /// stays signed in).
  void reset() {
    _resetData();
    notifyListeners();
  }

  void _resetData() {
    _resetCount++;
    final start = now;
    DateTime ago(int minutes) => start.subtract(Duration(minutes: minutes));
    _sequence = 0;
    _scenario = DemoOrderScenario.none;
    _activeOrder = null;
    _activeMoney = null;
    _completionsByKey.clear();
    _completedOrders.clear();
    _completed = [
      for (final c in fixtures.completed)
        CompletedDelivery(
          orderId: c.orderId,
          deliveredAt: ago(c.minutesAgo).toUtc(),
          merchantName: c.merchantName,
          deliveryAreaName: c.deliveryArea,
          deliveryFeeFils: c.deliveryFeeFils,
          customerName: c.customerName,
          customerPhone: c.customerPhone,
          deliveryNotes: c.deliveryNotes,
        ),
    ];
    _availability = fixtures.initiallyAvailable
        ? CaptainAvailability.available
        : CaptainAvailability.unavailable;
    _offers = [
      for (final id in fixtures.pendingOfferIds)
        _live(fixtures.offers.firstWhere((o) => o.id == id), id: id),
    ];
    _declined = [
      for (final d in fixtures.declined)
        DeclinedOfferRecord(
          offerId: d.offerId,
          declinedAt: ago(d.minutesAgo),
          merchantName: d.merchantName,
          kind: d.kind,
        ),
    ];
    _wallet = WalletOverview(
      summary: WalletSummary(balanceFils: fixtures.walletBalanceFils),
      debits: [
        for (final d in fixtures.debits)
          WalletCommissionDebit(
            id: d.id,
            debitedAt: ago(d.minutesAgo).toUtc(),
            commissionFils: d.amountFils,
            merchantName: d.merchantName,
            deliveryAreaName: d.deliveryArea,
            orderId: d.orderId,
          ),
      ],
    );
  }

  _LiveOffer _live(DemoOfferSeed seed, {required String id, String? orderId}) {
    final start = now;
    final expires = seed.expiresInSeconds;
    final scheduled = seed.scheduledInMinutes;
    return _LiveOffer(
      CaptainOrderOffer(
        id: id,
        orderId: orderId ?? seed.orderId,
        kind: seed.kind,
        merchantName: seed.merchantName,
        pickupLabel: seed.pickupDisplay,
        deliveryAreaName: seed.deliveryArea,
        deliveryFeeFils: seed.deliveryFeeFils,
        scheduledPickupAt: scheduled == null
            ? null
            : start.add(Duration(minutes: scheduled)),
        commission: OfferCommissionSnapshot(
          amountFils: seed.commissionFils,
          rateBasisPoints: seed.commissionRatePercent * 100,
        ),
      ),
      expires == null ? null : start.add(Duration(seconds: expires)),
      seed,
    );
  }

  bool _isLive(_LiveOffer o) {
    final expires = o.expiresAt;
    return expires == null || now.isBefore(expires);
  }

  /// The offers the demo server lists as actionable now (expired ones are
  /// dropped, as the real server would).
  List<CaptainOrderOffer> eligibleOffers() {
    _offers.removeWhere((o) => !_isLive(o));
    return [for (final o in _offers) o.offer];
  }

  int get _injectedWaiting => _offers
      .where((o) => _isLive(o) && o.offer.id.startsWith(_templatePrefix))
      .length;

  String get _templatePrefix =>
      fixtures.incomingTemplate.id.split('{sequence}').first;

  /// Whether «إظهار طلب جديد» may add another offer.
  bool get canInjectOffer =>
      _session != null && _injectedWaiting < maxInjectedOffers;

  /// «إظهار طلب جديد»: a new instant offer from the template, with a unique
  /// id and an expiry relative to now. Returns its id, or null when the
  /// limit is reached or nobody is signed in.
  String? injectOffer() {
    if (!canInjectOffer) return null;
    _sequence++;
    final template = fixtures.incomingTemplate;
    final id = template.id.replaceAll('{sequence}', '$_sequence');
    final orderId = template.orderId.replaceAll('{sequence}', '$_sequence');
    _offers.add(_live(template, id: id, orderId: orderId));
    notifyListeners();
    return id;
  }

  /// Lists the fixture's scheduled sample (visual only: it can never be
  /// accepted in the app). Null when no scheduled sample exists or it is
  /// already listed.
  String? showScheduledSample() {
    final seed = fixtures.offers
        .where((o) => o.kind == OrderOfferKind.scheduled)
        .firstOrNull;
    if (_session == null ||
        seed == null ||
        _offers.any((o) => o.offer.id == seed.id)) {
      return null;
    }
    _offers.add(_live(seed, id: seed.id));
    notifyListeners();
    return seed.id;
  }

  /// Chooses which active order the demo server reports.
  void setScenario(DemoOrderScenario scenario) {
    _applyScenario(scenario);
    notifyListeners();
  }

  void _applyScenario(DemoOrderScenario scenario) {
    _scenario = scenario;
    final seed = fixtures.assignedScenario;
    switch (scenario) {
      case DemoOrderScenario.none:
        _activeOrder = null;
        _activeMoney = null;
      case DemoOrderScenario.assigned:
        _activeOrder = ActiveOrder(
          orderId: seed.id,
          restaurantName: seed.merchantName,
          status: ActiveOrderStatus.accepted,
          assignmentRef: 'demo-assignment-${seed.id}',
          pickupLocation: seed.pickup,
          deliveryAreaName: seed.deliveryArea,
          customerPhone: seed.customerPhone,
          customerName: seed.customerName,
          deliveryNotes: seed.deliveryNotes,
          deliveryFeeFils: seed.deliveryFeeFils,
        );
        _activeMoney = _ActiveMoney(
          feeFils: seed.deliveryFeeFils,
          commissionFils: seed.commissionFils,
        );
    }
  }

  _LiveOffer _eligible(String offerId) {
    final match = _offers.where((o) => o.offer.id == offerId).firstOrNull;
    if (match == null || !_isLive(match)) {
      throw const OrderOfferNoLongerAvailableException();
    }
    return match;
  }

  /// Simulated atomic accept: only an eligible, unexpired instant offer,
  /// and only without another active order (one active delivery per
  /// captain). A second accept finds nothing to accept.
  void accept(String offerId) {
    final live = _eligible(offerId);
    if (live.offer.kind != OrderOfferKind.instant || _activeOrder != null) {
      throw const OrderOfferRefusedException();
    }
    _offers.remove(live);
    final offer = live.offer;
    _activeOrder = ActiveOrder(
      orderId: offer.orderId!,
      restaurantName: offer.merchantName,
      status: ActiveOrderStatus.accepted,
      assignmentRef: 'demo-assignment-${offer.orderId}',
      pickupLocation: live.seed.pickup,
      deliveryAreaName: offer.deliveryAreaName,
      customerPhone: live.seed.customerPhone,
      customerName: live.seed.customerName,
      deliveryNotes: live.seed.deliveryNotes,
      deliveryFeeFils: offer.deliveryFeeFils,
    );
    _activeMoney = _ActiveMoney(
      feeFils: offer.deliveryFeeFils,
      commissionFils: live.seed.commissionFils,
    );
    _scenario = DemoOrderScenario.none;
    notifyListeners();
  }

  /// Simulated decline for this captain only: the merchant's order is not
  /// cancelled and the wallet is untouched; the server records it in this
  /// captain's declined-offers history.
  void decline(String offerId) {
    final live = _eligible(offerId);
    _offers.remove(live);
    _declined.add(
      DeclinedOfferRecord(
        offerId: live.offer.id,
        declinedAt: now,
        merchantName: live.offer.merchantName,
        kind: live.offer.kind,
      ),
    );
    notifyListeners();
  }

  ActiveOrder? get activeOrder => _activeOrder;

  /// The active order targeted by a command, or a state conflict (another
  /// order, another assignment, or none) — as a real server would refuse.
  ActiveOrder _target(OrderCommandTarget target) {
    final order = _activeOrder;
    if (order == null ||
        order.orderId != target.orderId ||
        order.assignmentRef != target.assignmentRef) {
      throw const OrderStateConflictException();
    }
    return order;
  }

  ActiveOrder _withStatus(ActiveOrder order, ActiveOrderStatus status) =>
      ActiveOrder(
        orderId: order.orderId,
        restaurantName: order.restaurantName,
        status: status,
        assignmentRef: order.assignmentRef,
        pickupLocation: order.pickupLocation,
        pickupInstructions: order.pickupInstructions,
        deliveryAreaName: order.deliveryAreaName,
        customerPhone: order.customerPhone,
        customerName: order.customerName,
        deliveryNotes: order.deliveryNotes,
        deliveryFeeFils: order.deliveryFeeFils,
      );

  /// Simulated pickup confirmation, without any code: only the assigned
  /// active order on its pickup leg advances to `picked_up` (anything else
  /// is a state conflict, as a real server would refuse).
  ActiveOrder confirmPickup(OrderCommandTarget target) {
    final order = _target(target);
    if (order.leg != ActiveOrderLeg.pickup) {
      throw const OrderStateConflictException();
    }
    final next = _withStatus(order, ActiveOrderStatus.pickedUp);
    _activeOrder = next;
    notifyListeners();
    return next;
  }

  /// Simulated Start Delivery: only from `picked_up`.
  ActiveOrder startDelivery(OrderCommandTarget target) {
    final order = _target(target);
    if (order.status != ActiveOrderStatus.pickedUp) {
      throw const OrderStateConflictException();
    }
    final next = _withStatus(order, ActiveOrderStatus.onTheWay);
    _activeOrder = next;
    notifyListeners();
    return next;
  }

  /// Simulated completion in one step: the order is recorded as delivered,
  /// exactly one commission debit is appended and the balance updated. A
  /// repeat with the same [operationKey] returns the same receipt and
  /// changes nothing (demo of the D-A56 idempotency the server must have).
  DeliveryCompletionReceipt completeDelivery(
    OrderCommandTarget target,
    String operationKey,
  ) {
    final repeated = _completionsByKey[operationKey];
    if (repeated != null) return repeated;
    final order = _target(target);
    if (order.status != ActiveOrderStatus.onTheWay) {
      throw const OrderStateConflictException();
    }
    final money = _activeMoney!;
    final at = now.toUtc();
    final receipt = DeliveryCompletionReceipt(
      orderId: order.orderId,
      deliveredAt: at,
      receiptRef: 'demo-receipt-${order.orderId}',
    );
    _completed.add(
      CompletedDelivery(
        orderId: order.orderId,
        deliveredAt: at,
        merchantName: order.restaurantName,
        deliveryAreaName: order.deliveryAreaName,
        deliveryFeeFils: money.feeFils,
        // The order's own snapshot goes into history (D-A83).
        customerName: order.customerName,
        customerPhone: order.customerPhone,
        deliveryNotes: order.deliveryNotes,
      ),
    );
    _wallet = WalletOverview(
      summary: WalletSummary(
        balanceFils: _wallet.summary.balanceFils - money.commissionFils,
      ),
      debits: [
        ..._wallet.debits,
        WalletCommissionDebit(
          id: 'demo-debit-${order.orderId}',
          debitedAt: at,
          commissionFils: money.commissionFils,
          merchantName: order.restaurantName,
          deliveryAreaName: order.deliveryAreaName,
          orderId: order.orderId,
        ),
      ],
    );
    _completionsByKey[operationKey] = receipt;
    _completedOrders[order.orderId] = receipt;
    _activeOrder = null;
    _activeMoney = null;
    notifyListeners();
    return receipt;
  }

  /// What happened to [orderId], for reconciling an unknown outcome.
  OrderOutcome outcome(String orderId) {
    final delivered = _completedOrders[orderId];
    if (delivered != null) return OrderOutcomeDelivered(delivered);
    final order = _activeOrder;
    if (order != null && order.orderId == orderId) {
      return OrderOutcomeActive(order);
    }
    return const OrderOutcomeUnresolved();
  }

  /// Completed deliveries, newest first (the demo server's sort).
  List<CompletedDelivery> get completedDeliveries => List.unmodifiable(
    [..._completed]..sort((a, b) => b.deliveredAt.compareTo(a.deliveredAt)),
  );

  List<DeclinedOfferRecord> get declinedOffers => List.unmodifiable(_declined);

  /// The fictional wallet: never changed by accept/decline (no hold);
  /// a simulated completion appends one commission debit (D-A74).
  WalletOverview get wallet => _wallet;

  /// Lifetime delivered count as this fictional "server" records it: every
  /// completed delivery in the fixtures, including ones older than the
  /// 7-day debit window. Earnings stay null (formula pending, D-P36).
  CaptainDeliveryStatistics get deliveryStatistics =>
      CaptainDeliveryStatistics(deliveredCount: _completed.length);

  CaptainAvailability get availability => _availability;

  set availability(CaptainAvailability value) {
    _availability = value;
    notifyListeners();
  }
}
