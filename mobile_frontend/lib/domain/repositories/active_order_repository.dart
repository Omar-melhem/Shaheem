// Contract for reading the captain's current active order.

import 'package:mobile_frontend/domain/entities/active_order.dart';

/// Reads the active order of the signed-in captain from the backend.
///
/// The server is the authority: it decides which order (if any) is active.
/// Implementations must not filter by status on the client, cache a
/// previous answer as truth, or invent an order.
abstract interface class ActiveOrderRepository {
  /// The active order, or null when the server reports none.
  ///
  /// Throws an `OrderException` for network, server or "not configured"
  /// failures.
  Future<ActiveOrder?> getActiveOrder();
}
