// Domain record of an order offer this captain declined.

import 'package:mobile_frontend/domain/entities/order_offer.dart';

/// One offer **this captain** declined, as the server's history reports it.
///
/// It records the captain's answer to a temporary offer. It is NOT a
/// delivery (completed or not) and NOT a cancelled merchant order: declining
/// never cancels the merchant's order (D-A46 / D-A60). Only the server
/// creates these records; the app never adds one locally after a decline.
///
/// The history contract is TO SPECIFY. Mapping must reject an empty
/// [offerId]; the other fields are shown only when the server sends them.
class DeclinedOfferRecord {
  const DeclinedOfferRecord({
    required this.offerId,
    this.declinedAt,
    this.merchantName,
    this.kind,
  });

  /// Opaque, stable offer identifier from the server.
  final String offerId;

  /// When the server recorded the decline; null when not provided.
  final DateTime? declinedAt;

  /// Merchant display name, when provided.
  final String? merchantName;

  /// Instant or scheduled, when provided.
  final OrderOfferKind? kind;
}
