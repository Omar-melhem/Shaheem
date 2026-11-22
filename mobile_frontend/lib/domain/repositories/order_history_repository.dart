// Contract for reading the signed-in captain's order history.

import 'package:mobile_frontend/domain/entities/declined_offer.dart';
import 'package:mobile_frontend/domain/entities/order_workflow.dart';

/// Read-only access to the captain's history on the SHAHM backend: the
/// offers this captain declined (Task 36) and, since D-A81, the deliveries
/// this captain completed.
///
/// **API contract: TO SPECIFY.** The query, paging, time range and record
/// fields do not exist yet; nothing here invents them. Paging is an opaque
/// server cursor, so no page size or sort rule is guessed on the phone.
abstract interface class OrderHistoryRepository {
  /// The offers this captain declined, as the server records them. An
  /// empty list means the server confirmed there are none.
  ///
  /// Throws an `OrderHistoryException` for "not configured", network or
  /// server failures.
  Future<List<DeclinedOfferRecord>> getDeclinedOffers();

  /// One page of this captain's completed deliveries (lifetime, newest
  /// first as the server sorts them). [cursor] is null for the first page,
  /// otherwise the previous page's `nextCursor`. A declined offer is never
  /// a completed delivery.
  ///
  /// Throws an `OrderHistoryException` like [getDeclinedOffers].
  Future<CompletedDeliveriesPage> getCompletedDeliveries({String? cursor});
}
