// SHAHM DEMO (Task 37) — the fictional JSON fixture pack, parsed and
// checked. Fixture schema only: NOT a production API contract.
// Removed by `bash tool/demo/remove_demo.sh --apply`.

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:mobile_frontend/domain/entities/active_order.dart';
import 'package:mobile_frontend/domain/entities/order_offer.dart';

/// Where the fixtures live (declared as an asset only while the demo is
/// installed).
const demoFixturesDir = 'assets/demo/fixtures';

/// The fixture files, one feature each.
const demoFixtureFiles = [
  'auth',
  'captain',
  'home',
  'offers',
  'current_order',
  'order_history',
  'wallet',
];

/// A fixture file is missing, malformed or inconsistent.
class DemoFixtureException implements Exception {
  const DemoFixtureException(this.file, this.message);

  final String file;
  final String message;

  @override
  String toString() => 'DemoFixtureException($file): $message';
}

/// Reads one JSON object field with a type check.
class _Reader {
  _Reader(this.file, this.json);

  final String file;
  final Map<String, Object?> json;

  T req<T>(String key) {
    final value = json[key];
    if (value is T) return value;
    throw DemoFixtureException(file, 'field "$key" must be $T');
  }

  T? opt<T>(String key) {
    final Object? value = json[key];
    if (value == null) return null;
    if (value is T) return value as T;
    throw DemoFixtureException(file, 'field "$key" must be $T or null');
  }

  _Reader obj(String key) =>
      _Reader(file, req<Map<String, Object?>>(key).cast<String, Object?>());

  List<_Reader> list(String key) => [
    for (final item in req<List<Object?>>(key))
      if (item is Map<String, Object?>)
        _Reader(file, item)
      else
        throw DemoFixtureException(file, '"$key" must hold objects'),
  ];

  /// The optional fictional pickup point (`demo_pickup_latitude` /
  /// `demo_pickup_longitude`), both or neither.
  GeoPoint? point() {
    final lat = opt<num>('demo_pickup_latitude');
    final lng = opt<num>('demo_pickup_longitude');
    if (lat == null && lng == null) return null;
    if (lat == null || lng == null) {
      throw DemoFixtureException(file, 'pickup point needs lat and lng');
    }
    return GeoPoint(latitude: lat.toDouble(), longitude: lng.toDouble());
  }

  int fils(String key) {
    final value = req<int>(key);
    if (value < 0) throw DemoFixtureException(file, '"$key" is negative');
    return value;
  }
}

/// One fictional offer (or the incoming-offer template).
class DemoOfferSeed {
  const DemoOfferSeed({
    required this.id,
    required this.orderId,
    required this.kind,
    required this.merchantName,
    required this.pickupDisplay,
    required this.deliveryArea,
    required this.deliveryFeeFils,
    required this.commissionRatePercent,
    required this.commissionFils,
    required this.expiresInSeconds,
    required this.scheduledInMinutes,
    this.pickup,
    this.customerPhone,
  });

  /// For the template these are the `{sequence}` patterns.
  final String id;
  final String orderId;
  final OrderOfferKind kind;
  final String merchantName;
  final String pickupDisplay;
  final String deliveryArea;
  final int deliveryFeeFils;
  final int commissionRatePercent;
  final int commissionFils;
  final int? expiresInSeconds;
  final int? scheduledInMinutes;

  /// Fictional merchant point for the demo pickup map / Google Maps action.
  final GeoPoint? pickup;

  /// Fictional customer phone; absent on purpose for some orders (D-A81).
  final String? customerPhone;

  static DemoOfferSeed _parse(_Reader r, {bool template = false}) {
    final fee = r.fils('delivery_fee_fils');
    final commission = r.fils('commission_fils');
    final net = r.fils('captain_net_fils');
    if (fee - commission != net) {
      throw DemoFixtureException(r.file, 'net != fee - commission');
    }
    final rate = r.req<int>('commission_rate_percent');
    if (rate < 0 || rate > 100) {
      throw DemoFixtureException(r.file, 'commission rate out of range');
    }
    final kind = switch (r.req<String>('kind')) {
      'instant' => OrderOfferKind.instant,
      'scheduled' => OrderOfferKind.scheduled,
      final other => throw DemoFixtureException(r.file, 'kind "$other"'),
    };
    final seed = DemoOfferSeed(
      id: r.req<String>(template ? 'id_pattern' : 'id'),
      orderId: r.req<String>(template ? 'order_id_pattern' : 'order_id'),
      kind: kind,
      merchantName: r.req<String>('merchant_name'),
      pickupDisplay: r.req<String>('pickup_display'),
      deliveryArea: r.req<String>('delivery_area'),
      deliveryFeeFils: fee,
      commissionRatePercent: rate,
      commissionFils: commission,
      expiresInSeconds: r.opt<int>('expires_in_seconds'),
      scheduledInMinutes: r.opt<int>('scheduled_in_minutes'),
      pickup: r.point(),
      customerPhone: r.opt<String>('demo_customer_phone'),
    );
    if (!seed.id.startsWith('demo-') || !seed.orderId.startsWith('demo-')) {
      throw DemoFixtureException(r.file, 'ids must start with "demo-"');
    }
    if (kind == OrderOfferKind.scheduled && seed.scheduledInMinutes == null) {
      throw DemoFixtureException(r.file, 'scheduled offer without a time');
    }
    return seed;
  }
}

/// One fictional active-order scenario.
class DemoOrderSeed {
  const DemoOrderSeed({
    required this.id,
    required this.merchantName,
    required this.deliveryArea,
    required this.deliveryFeeFils,
    required this.commissionFils,
    this.pickup,
    this.customerPhone,
  });

  final String id;
  final String merchantName;
  final String deliveryArea;
  final int deliveryFeeFils;
  final int commissionFils;
  final GeoPoint? pickup;
  final String? customerPhone;
}

/// One fictional completed delivery (history and lifetime statistics).
class DemoCompletedSeed {
  const DemoCompletedSeed({
    required this.orderId,
    required this.merchantName,
    required this.deliveryArea,
    required this.deliveryFeeFils,
    required this.minutesAgo,
  });

  final String orderId;
  final String merchantName;
  final String deliveryArea;
  final int deliveryFeeFils;
  final int minutesAgo;
}

/// One fictional declined offer.
class DemoDeclinedSeed {
  const DemoDeclinedSeed({
    required this.offerId,
    required this.kind,
    required this.merchantName,
    required this.minutesAgo,
  });

  final String offerId;
  final OrderOfferKind kind;
  final String merchantName;
  final int minutesAgo;
}

/// One fictional wallet row (credit or commission debit).
class DemoLedgerSeed {
  const DemoLedgerSeed({
    required this.id,
    required this.amountFils,
    required this.minutesAgo,
    this.merchantName,
    this.deliveryArea,
    this.orderId,
  });

  final String id;
  final int amountFils;
  final int minutesAgo;
  final String? merchantName;
  final String? deliveryArea;
  final String? orderId;
}

/// The whole fixture pack, checked for internal consistency.
class DemoFixtures {
  const DemoFixtures({
    required this.username,
    required this.password,
    required this.accessToken,
    required this.captainId,
    required this.captainName,
    required this.captainRole,
    required this.initiallyAvailable,
    required this.pendingOfferIds,
    required this.offers,
    required this.incomingTemplate,
    required this.assignedScenario,
    required this.declined,
    required this.completed,
    required this.pickupPin,
    required this.futureCount,
    required this.walletBalanceFils,
    required this.debits,
  });

  final String username;
  final String password;

  /// Deliberately NOT a JWT. Kept in memory only; never sent or stored.
  final String accessToken;
  final String captainId;
  final String captainName;
  final String captainRole;
  final bool initiallyAvailable;
  final List<String> pendingOfferIds;
  final List<DemoOfferSeed> offers;
  final DemoOfferSeed incomingTemplate;
  final DemoOrderSeed assignedScenario;
  final List<DemoDeclinedSeed> declined;

  /// Completed deliveries in the fixtures: the demo "server"'s history and
  /// lifetime delivered count (D-A76).
  final List<DemoCompletedSeed> completed;

  /// The fictional pickup PIN every demo order accepts (checked only by
  /// the in-memory demo server; production never compares a PIN).
  final String pickupPin;

  int get completedCount => completed.length;

  /// Parsed and checked, but the app has no screen for them yet.
  final int futureCount;

  /// The single fictional balance (D-A74: no holds).
  final int walletBalanceFils;
  final List<DemoLedgerSeed> debits;

  /// Loads every file from [bundle] and parses it.
  static Future<DemoFixtures> load(AssetBundle bundle) async {
    final raw = <String, String>{};
    for (final name in demoFixtureFiles) {
      raw[name] = await bundle.loadString('$demoFixturesDir/$name.json');
    }
    return parse(raw);
  }

  /// Parses the seven files' text (by name without `.json`).
  static DemoFixtures parse(Map<String, String> files) {
    _Reader open(String name) {
      final text = files[name];
      if (text == null) throw DemoFixtureException(name, 'file missing');
      final Object? decoded;
      try {
        decoded = jsonDecode(text);
      } on FormatException catch (e) {
        throw DemoFixtureException(name, 'invalid JSON: ${e.message}');
      }
      if (decoded is! Map<String, Object?>) {
        throw DemoFixtureException(name, 'top level must be an object');
      }
      final r = _Reader(name, decoded);
      if (r.req<String>('schema') != 'shahm-demo-v1' ||
          r.req<bool>('demo_only') != true) {
        throw DemoFixtureException(name, 'not a shahm-demo-v1 demo file');
      }
      return r;
    }

    final auth = open('auth');
    final captain = open('captain');
    final home = open('home');
    final offersFile = open('offers');
    final current = open('current_order');
    final history = open('order_history');
    final wallet = open('wallet');

    final token = auth.obj('session').req<String>('access_token');
    if (token.split('.').length == 3) {
      throw const DemoFixtureException(
        'auth',
        'token must not look like a JWT',
      );
    }

    final offers = [
      for (final o in offersFile.list('offers')) DemoOfferSeed._parse(o),
    ];
    final ids = offers.map((o) => o.id).toList();
    if (ids.toSet().length != ids.length) {
      throw const DemoFixtureException('offers', 'duplicate offer ids');
    }
    final pending = [
      for (final id in home.req<List<Object?>>('pending_offer_ids'))
        if (id is String)
          id
        else
          throw const DemoFixtureException('home', 'ids must be strings'),
    ];
    for (final id in pending) {
      final seed = offers.where((o) => o.id == id).firstOrNull;
      if (seed == null || seed.kind != OrderOfferKind.instant) {
        throw DemoFixtureException('home', 'unknown instant offer "$id"');
      }
    }
    final template = DemoOfferSeed._parse(
      offersFile.obj('incoming_offer_template'),
      template: true,
    );
    if (!template.id.contains('{sequence}') ||
        template.kind != OrderOfferKind.instant) {
      throw const DemoFixtureException('offers', 'bad incoming template');
    }

    if (current.opt<String>('default_active_order_id') != null ||
        home.opt<String>('active_order_id') != null) {
      throw const DemoFixtureException(
        'current_order',
        'the demo must start without an active order',
      );
    }
    final assigned = current.obj('scenarios').obj('assigned');
    final pin = assigned.req<String>('pickup_pin');
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw const DemoFixtureException('current_order', 'pin: 4 digits');
    }

    final balance = wallet.obj('summary').req<int>('balance_fils');
    if (home.req<int>('wallet_balance_fils') != balance) {
      throw const DemoFixtureException('wallet', 'Home and Wallet disagree');
    }
    // D-A75: new demo data starts within the 5,000-fils balance ceiling.
    if (balance > 5000) {
      throw const DemoFixtureException('wallet', 'balance above 5,000 fils');
    }
    // D-A74: no hold-derived fields may come back.
    for (final retired in ['available_fils', 'held_commissions_fils']) {
      if (wallet.obj('summary').json.containsKey(retired)) {
        throw DemoFixtureException('wallet', 'retired field "$retired"');
      }
    }

    DemoLedgerSeed ledger(_Reader r, String amountKey) => DemoLedgerSeed(
      id: r.req<String>('id'),
      amountFils: r.fils(amountKey),
      minutesAgo: r.fils('occurred_minutes_ago'),
      merchantName: r.opt<String>('merchant_name'),
      deliveryArea: r.opt<String>('delivery_area'),
      orderId: r.opt<String>('order_id'),
    );

    final person = captain.obj('captain');
    return DemoFixtures(
      username: auth.req<String>('demo_username'),
      password: auth.req<String>('demo_password'),
      accessToken: token,
      captainId: person.req<String>('id'),
      captainName: person.req<String>('display_name'),
      captainRole: person.req<String>('role'),
      initiallyAvailable: captain.obj('availability').req<bool>('is_available'),
      pendingOfferIds: pending,
      offers: offers,
      incomingTemplate: template,
      assignedScenario: DemoOrderSeed(
        id: assigned.req<String>('id'),
        merchantName: assigned.req<String>('merchant_name'),
        deliveryArea: assigned.req<String>('delivery_area'),
        deliveryFeeFils: assigned.fils('delivery_fee_fils'),
        commissionFils: assigned.fils('commission_fils'),
        pickup: assigned.point(),
        customerPhone: assigned.opt<String>('customer_phone'),
      ),
      pickupPin: pin,
      declined: [
        for (final d in history.list('declined_offers'))
          DemoDeclinedSeed(
            offerId: d.req<String>('offer_id'),
            kind: d.req<String>('kind') == 'scheduled'
                ? OrderOfferKind.scheduled
                : OrderOfferKind.instant,
            merchantName: d.req<String>('merchant_name'),
            minutesAgo: d.fils('declined_minutes_ago'),
          ),
      ],
      completed: [
        for (final c in history.list('completed_deliveries'))
          DemoCompletedSeed(
            orderId: c.req<String>('id'),
            merchantName: c.req<String>('merchant_name'),
            deliveryArea: c.req<String>('delivery_area'),
            deliveryFeeFils: c.fils('delivery_fee_fils'),
            minutesAgo: c.fils('occurred_minutes_ago'),
          ),
      ],
      futureCount: history.list('future_commitments').length,
      walletBalanceFils: balance,
      debits: [
        for (final d in wallet.list('commission_debits'))
          ledger(d, 'commission_fils'),
      ],
    );
  }
}
