// Use case: look up the captain's current active order.

import 'dart:async';

import 'package:mobile_frontend/domain/entities/active_order.dart';
import 'package:mobile_frontend/domain/errors/order_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/active_order_repository.dart';

/// Outcome of [GetActiveOrder].
sealed class ActiveOrderResult {
  const ActiveOrderResult();
}

/// The server reports this order as active.
final class ActiveOrderFound extends ActiveOrderResult {
  const ActiveOrderFound(this.order);

  final ActiveOrder order;
}

/// The server answered: there is no active order.
final class ActiveOrderNone extends ActiveOrderResult {
  const ActiveOrderNone();
}

/// No orders backend is connected yet; nothing was checked.
final class ActiveOrderNotConfigured extends ActiveOrderResult {
  const ActiveOrderNotConfigured();
}

/// The device is offline.
final class ActiveOrderNoInternet extends ActiveOrderResult {
  const ActiveOrderNoInternet();
}

/// The backend was unreachable, failed or timed out.
final class ActiveOrderServiceUnavailable extends ActiveOrderResult {
  const ActiveOrderServiceUnavailable();
}

/// Unexpected error. Not proof that there is no active order.
final class ActiveOrderFailure extends ActiveOrderResult {
  const ActiveOrderFailure();
}

/// Asks the repository for the active order and classifies every failure,
/// so callers never mistake an error for "no active order".
///
/// It always asks the server again; it keeps no cache.
class GetActiveOrder {
  const GetActiveOrder(
    this._repository, {
    this.timeout = const Duration(seconds: 20),
  });

  final ActiveOrderRepository _repository;

  /// Safety net if the repository never answers; maps to unavailable.
  final Duration timeout;

  Future<ActiveOrderResult> call() async {
    try {
      final order = await _repository.getActiveOrder().timeout(timeout);
      return order == null ? const ActiveOrderNone() : ActiveOrderFound(order);
    } on OrderBackendNotConfiguredException {
      return const ActiveOrderNotConfigured();
    } on OrderNetworkUnavailableException {
      return const ActiveOrderNoInternet();
    } on OrderServiceUnavailableException {
      return const ActiveOrderServiceUnavailable();
    } on TimeoutException {
      return const ActiveOrderServiceUnavailable();
    } catch (_) {
      return const ActiveOrderFailure();
    }
  }
}
