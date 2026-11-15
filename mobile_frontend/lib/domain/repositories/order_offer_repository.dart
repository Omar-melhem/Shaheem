// Contract for the captain's currently actionable order offers.

import 'package:mobile_frontend/domain/entities/order_offer.dart';

/// Reads and answers the signed-in captain's order offers on the SHAHM
/// backend, which alone owns offer visibility, rounds, expiry, eligibility,
/// first-wins atomic acceptance and idempotency (D-A42–D-A46, D-A54–D-A56).
///
/// Implementations must not filter, expire or reorder offers on the client,
/// cache a list as truth, or treat a push notification as permission to
/// accept.
///
/// **API contract: TO SPECIFY.** Endpoint paths, DTOs, Problem Details codes
/// and how each command carries its `Idempotency-Key` (D-A56) do not exist
/// yet; nothing here invents them.
abstract interface class OrderOfferRepository {
  /// The offers that are actionable for this captain right now. An empty
  /// list means the server confirmed there are none.
  ///
  /// Throws an `OrderOfferException` for "not configured", network or
  /// server failures.
  Future<List<CaptainOrderOffer>> getEligibleOffers();

  /// Asks the server to assign the offer's order to this captain. Returns
  /// only after the server confirmed the assignment.
  ///
  /// Throws `OrderOfferNoLongerAvailableException` (expired, withdrawn,
  /// taken), `OrderOfferRefusedException` (not eligible), or other
  /// `OrderOfferException`s when the outcome is unknown.
  Future<void> acceptOffer(String offerId);

  /// Declines the offer **for this captain only**; it never cancels the
  /// merchant's order. Returns only after the server confirmed it.
  ///
  /// Throws like [acceptOffer].
  Future<void> declineOffer(String offerId);
}
