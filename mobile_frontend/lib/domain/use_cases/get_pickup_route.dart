// Use case: the driving route from the captain to the merchant pickup.

import 'dart:async';

import 'package:mobile_frontend/domain/entities/active_order.dart';
import 'package:mobile_frontend/domain/entities/pickup_route.dart';
import 'package:mobile_frontend/domain/repositories/pickup_route_repository.dart';

/// Outcome of [GetPickupRoute].
sealed class PickupRouteResult {
  const PickupRouteResult();
}

/// A real road route from the routing source.
final class PickupRouteFound extends PickupRouteResult {
  const PickupRouteFound(this.route);

  final PickupRoute route;
}

/// No routing source is configured (a permanent condition today).
final class PickupRouteNotConfigured extends PickupRouteResult {
  const PickupRouteNotConfigured();
}

/// The routing source did not return a route (or timed out).
final class PickupRouteUnavailable extends PickupRouteResult {
  const PickupRouteUnavailable();
}

/// Reads the route; never draws a straight line as a substitute.
class GetPickupRoute {
  const GetPickupRoute(
    this._repository, {
    this.timeout = const Duration(seconds: 15),
  });

  final PickupRouteRepository _repository;
  final Duration timeout;

  Future<PickupRouteResult> call({
    required GeoPoint origin,
    required GeoPoint destination,
  }) async {
    try {
      final route = await _repository
          .getDrivingRoute(origin: origin, destination: destination)
          .timeout(timeout);
      return route.path.length < 2
          ? const PickupRouteUnavailable()
          : PickupRouteFound(route);
    } on PickupRouteNotConfiguredException {
      return const PickupRouteNotConfigured();
    } on Object {
      return const PickupRouteUnavailable();
    }
  }
}
