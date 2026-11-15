// Domain view of the captain's current active order, for the pickup map.

/// A geographic coordinate in decimal degrees.
class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  /// Whether this is a well-formed coordinate: finite and inside the
  /// geographic ranges (latitude ±90, longitude ±180).
  ///
  /// This is the only check the client can make today. It does NOT say the
  /// point is a plausible restaurant location: (0, 0), or a point far
  /// outside the delivery area, is well-formed and passes. Rejecting such
  /// values needs the service-area contract, which does not exist yet
  /// (D-P31); until then no area or "empty value" rule is guessed here.
  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude.abs() <= 90 &&
      longitude.abs() <= 180;
}

/// The order the server currently reports as active for the signed-in
/// captain, reduced to what the pickup map needs.
///
/// **The client never decides what "active" means.** Which statuses count,
/// and whether a captain can have more than one such order, are backend
/// rules that are not approved yet (D-P25); the repository simply returns
/// what the server reports. That is why there is no status field here.
///
/// It deliberately has NO customer or delivery-address data: this model is
/// only about travelling to the restaurant to collect the order.
class ActiveOrder {
  const ActiveOrder({
    required this.orderId,
    required this.restaurantName,
    this.pickupLocation,
    this.pickupInstructions,
  });

  /// Backend identifier of the order.
  final String orderId;

  /// Display name of the restaurant to collect from.
  final String restaurantName;

  /// The restaurant's own coordinates (never the customer's). Null when the
  /// server sent none. May also be malformed: use [mappablePickup].
  final GeoPoint? pickupLocation;

  /// [pickupLocation] when it is present and well-formed, otherwise null.
  /// The order is just as active either way; only the map depends on this.
  GeoPoint? get mappablePickup {
    final pickup = pickupLocation;
    return pickup != null && pickup.isValid ? pickup : null;
  }

  /// Pickup notes, if the order contract provides any.
  final String? pickupInstructions;
}
