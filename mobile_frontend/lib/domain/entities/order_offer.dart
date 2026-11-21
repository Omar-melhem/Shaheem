// Domain representation of an order offer the captain may still accept.

/// Whether an offer is for now or for a future pickup.
enum OrderOfferKind {
  /// «حالي»: an instant order; accepting it makes it the active delivery.
  instant,

  /// «مؤجل»: a scheduled order for a future pickup. A confirmed scheduled
  /// assignment is a future commitment, never an active order (D-A44).
  /// Under the approved process the Admin confirms it directly, with no
  /// in-app acceptance (D-A47 / D-A61).
  scheduled,
}

/// The server's immutable commission snapshot for one order (D-A49 /
/// D-A59): later changes to the global rate never change it.
///
/// Both values come from the server. The client never derives the amount
/// from the rate (the server owns the nearest-fils rounding).
class OfferCommissionSnapshot {
  const OfferCommissionSnapshot({
    required this.amountFils,
    this.rateBasisPoints,
  });

  /// Commission in integer fils (1 JOD = 1000 fils).
  final int amountFils;

  /// The snapshot rate in basis points (2000 = 20 %), when the server
  /// provides it; null shows the rate as not available. An integer, so no
  /// floating-point rate is ever stored.
  final int? rateBasisPoints;
}

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
///
/// [kind], [orderId], [scheduledPickupAt] and [commission] were added in
/// Task 36 for the new-offer sheet. Their wire fields are TO SPECIFY too;
/// until a contract sends them they stay at their defaults, and the UI
/// shows "not available" rather than a guess.
class CaptainOrderOffer {
  const CaptainOrderOffer({
    required this.id,
    required this.merchantName,
    required this.deliveryAreaName,
    required this.deliveryFeeFils,
    this.pickupLabel,
    this.kind = OrderOfferKind.instant,
    this.orderId,
    this.scheduledPickupAt,
    this.commission,
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

  /// Instant or scheduled. Defaults to instant: the approved dispatch
  /// process only sends instant offers to the app (public rounds and
  /// private offers, D-A46 / D-A60); scheduled orders are assigned by the
  /// Admin (D-A47 / D-A61).
  final OrderOfferKind kind;

  /// The merchant order this offer is for, when the server provides it.
  /// After an acceptance, Current Order opens only when the server's
  /// active order has this id; null means that match cannot be checked.
  final String? orderId;

  /// The authoritative scheduled pickup time (scheduled offers only); null
  /// when the server did not send one.
  final DateTime? scheduledPickupAt;

  /// The order's commission snapshot; null when the server did not send
  /// one (then the earnings breakdown is not available).
  final OfferCommissionSnapshot? commission;

  /// The captain's estimated net earnings in fils: [deliveryFeeFils] minus
  /// the snapshot commission, by integer subtraction. Null when there is
  /// no snapshot or it is inconsistent (negative, or above the fee).
  ///
  /// An estimate shown at decision time, not a wallet credit: the server
  /// applies the commission at the proper lifecycle step (D-A59).
  int? get netEarningsFils {
    final amount = commission?.amountFils;
    if (amount == null || amount < 0 || amount > deliveryFeeFils) return null;
    return deliveryFeeFils - amount;
  }

  /// Whether the commission snapshot is complete and consistent, which an
  /// informed acceptance needs: a valid amount and the snapshot rate.
  bool get hasEarningsDisclosure {
    final rate = commission?.rateBasisPoints;
    return netEarningsFils != null &&
        rate != null &&
        rate >= 0 &&
        rate <= 10000;
  }
}
