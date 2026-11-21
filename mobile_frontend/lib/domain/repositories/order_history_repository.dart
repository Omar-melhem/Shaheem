// Contract for reading the signed-in captain's order history.

import 'package:mobile_frontend/domain/entities/declined_offer.dart';

/// Read-only access to the captain's history on the SHAHM backend.
///
/// Today it only covers the offers this captain declined (Task 36);
/// completed deliveries are a later task.
///
/// **API contract: TO SPECIFY.** The query, paging, time range and record
/// fields do not exist yet; nothing here invents them.
abstract interface class OrderHistoryRepository {
  /// The offers this captain declined, as the server records them. An
  /// empty list means the server confirmed there are none.
  ///
  /// Throws an `OrderHistoryException` for "not configured", network or
  /// server failures.
  Future<List<DeclinedOfferRecord>> getDeclinedOffers();
}
