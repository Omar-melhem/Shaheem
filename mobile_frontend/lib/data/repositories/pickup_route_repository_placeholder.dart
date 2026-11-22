// Temporary PickupRouteRepository used until the Routes access is designed.

import 'package:mobile_frontend/domain/entities/active_order.dart';
import 'package:mobile_frontend/domain/entities/pickup_route.dart';
import 'package:mobile_frontend/domain/repositories/pickup_route_repository.dart';

/// TEMPORARY — the Google Routes access design (backend proxy or
/// app-restricted key) is not decided, so no route is ever computed and no
/// straight line is drawn instead.
class PickupRouteRepositoryPlaceholder implements PickupRouteRepository {
  const PickupRouteRepositoryPlaceholder();

  @override
  Future<PickupRoute> getDrivingRoute({
    required GeoPoint origin,
    required GeoPoint destination,
  }) async => throw const PickupRouteNotConfiguredException();
}
