// Domain view of the captain's current active order (pickup and delivery).

/// A geographic coordinate in decimal degrees.
class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  /// Whether this is a usable SHAHM coordinate: finite, inside the
  /// geographic ranges (latitude ±90, longitude ±180), and not the
  /// approved-invalid `(0, 0)` (D-A62/D-P31: "(0,0) is invalid for SHAHM
  /// service").
  ///
  /// It does NOT say the point lies inside the service area: that check
  /// needs the Admin geofence and stays on the server.
  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude.abs() <= 90 &&
      longitude.abs() <= 180 &&
      !(latitude == 0 && longitude == 0);
}

/// The authoritative status of an active delivery, as the server reports
/// it (D-A68). Only the four active statuses exist here; anything else the
/// server might send is [unknown], which the app never treats as pickup.
enum ActiveOrderStatus {
  accepted,
  headingToPickup,
  pickedUp,
  onTheWay,

  /// A status this app version does not know. No action is offered.
  unknown,
}

/// Which part of the journey a status belongs to (D-A81). The pickup leg
/// groups `accepted` and `heading_to_pickup` in one presentation; the app
/// never sends a transition between them.
enum ActiveOrderLeg { pickup, delivery, unknown }

/// Presentation grouping of [ActiveOrderStatus].
extension ActiveOrderStatusLeg on ActiveOrderStatus {
  ActiveOrderLeg get leg => switch (this) {
    ActiveOrderStatus.accepted ||
    ActiveOrderStatus.headingToPickup => ActiveOrderLeg.pickup,
    ActiveOrderStatus.pickedUp ||
    ActiveOrderStatus.onTheWay => ActiveOrderLeg.delivery,
    ActiveOrderStatus.unknown => ActiveOrderLeg.unknown,
  };
}

/// The order the server currently reports as active for the signed-in
/// captain (D-A68, D-A73, D-A81).
///
/// **The client never decides the stage.** [status] is what the server
/// reported; commands are only offered for it, and only the server's next
/// answer changes it (never a tap, a timeout, opening Maps or GPS).
///
/// Customer data is limited to what the merchant enters (D-A81, D-A83): the
/// destination **area** (required), and optionally a customer name, a phone
/// and delivery notes — never customer coordinates, a street address or a
/// route. No `toString` override, so these details never reach logs.
class ActiveOrder {
  const ActiveOrder({
    required this.orderId,
    required this.restaurantName,
    required this.status,
    this.assignmentRef,
    this.pickupLocation,
    this.pickupInstructions,
    this.deliveryAreaName,
    this.customerPhone,
    this.customerName,
    this.deliveryNotes,
    this.deliveryFeeFils,
  });

  /// Backend identifier of the order.
  final String orderId;

  /// Display name of the merchant (restaurant) to collect from.
  final String restaurantName;

  /// The server-reported status.
  final ActiveOrderStatus status;

  /// Opaque reference of the current assignment, when the contract has one.
  /// Commands carry it so a reassigned order rejects a stale command.
  final String? assignmentRef;

  /// The merchant's own coordinates (never the customer's). Null when the
  /// server sent none. May also be malformed: use [mappablePickup].
  final GeoPoint? pickupLocation;

  /// [pickupLocation] when it is present and valid, otherwise null. The
  /// order is just as active either way; only the map and the external
  /// navigation action depend on this.
  GeoPoint? get mappablePickup {
    final pickup = pickupLocation;
    return pickup != null && pickup.isValid ? pickup : null;
  }

  /// Pickup notes, if the order contract provides any.
  final String? pickupInstructions;

  /// The customer's delivery area as the server labels it (required by the
  /// business; nullable here only so a missing value is shown honestly).
  final String? deliveryAreaName;

  /// The customer phone exactly as received; **optional** (D-A81). Use
  /// [contactPhone] for display.
  final String? customerPhone;

  /// [customerPhone] trimmed, or null when it is null, empty or blank. A
  /// missing phone never blocks any stage.
  String? get contactPhone => presentText(customerPhone);

  /// The customer name as received; **optional** (D-A83). Use
  /// [contactName] for display.
  final String? customerName;

  /// [customerName] trimmed, or null when null, empty or blank.
  String? get contactName => presentText(customerName);

  /// The merchant's notes for the **delivery** (D-A83); optional. Distinct
  /// from [pickupInstructions], which are about collecting the order.
  final String? deliveryNotes;

  /// [deliveryNotes] trimmed, or null when null, empty or blank.
  String? get deliveryNote => presentText(deliveryNotes);

  /// The full delivery fee in integer fils (business-required). Null only
  /// when the server did not send it — shown as unavailable, never as 0.
  /// An explicit 0 is a real value.
  final int? deliveryFeeFils;

  /// Which leg of the journey this order is in.
  ActiveOrderLeg get leg => status.leg;
}

/// [value] trimmed, or null when it is null, empty or whitespace-only. Used
/// for optional order texts, so a blank value is never shown as data.
String? presentText(String? value) {
  final text = value?.trim();
  return text == null || text.isEmpty ? null : text;
}
