// Domain representation of an order offer the captain may still accept.

/// An order offer that the backend says is **currently actionable for this
/// captain**: active, not expired, not withdrawn, not accepted by anyone
/// and still addressed to this captain (public round or private offer).
/// An ignored notification does not remove an offer; an explicit decline,
/// expiry, withdrawal or another captain's acceptance does — and only the
/// server decides that.
///
/// This is not an assigned order (see `ActiveOrder`). The customer has no
/// GPS point in this product: only the delivery **area** is known.
///
/// Mapping from the backend contract (TO SPECIFY) must reject an empty
/// [id], merchant name or area and a negative fee.
class CaptainOrderOffer {
  const CaptainOrderOffer({
    required this.id,
    required this.merchantName,
    required this.deliveryAreaName,
    required this.deliveryFeeFils,
    this.pickupLabel,
  });

  /// Opaque, stable offer identifier from the server.
  final String id;

  /// Merchant (restaurant) display name.
  final String merchantName;

  /// Merchant pickup display text (area or address) when the server
  /// provides a verified one; null otherwise (shown as "not available").
  final String? pickupLabel;

  /// Customer delivery area name (never a coordinate or address).
  final String deliveryAreaName;

  /// Delivery fee snapshot in integer fils (1 JOD = 1000 fils). Not the
  /// captain's profit or commission.
  final int deliveryFeeFils;
}
