// Temporary ActiveOrderRepository used until the orders backend exists.

import 'package:mobile_frontend/domain/entities/active_order.dart';
import 'package:mobile_frontend/domain/errors/order_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/active_order_repository.dart';

/// TEMPORARY — there is no orders backend or approved order contract yet
/// (D-P02, D-P25).
///
/// Reports "backend not configured" instead of answering "no active order"
/// (which would be a claim about data nobody checked) or inventing an
/// order. Replace it with the API-backed implementation once the contract
/// is agreed.
class ActiveOrderRepositoryPlaceholder implements ActiveOrderRepository {
  const ActiveOrderRepositoryPlaceholder();

  @override
  Future<ActiveOrder?> getActiveOrder() async {
    throw const OrderBackendNotConfiguredException();
  }
}
