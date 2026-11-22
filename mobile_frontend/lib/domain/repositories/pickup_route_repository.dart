// Contract for the captain → merchant driving route (D-A62).

import 'package:mobile_frontend/domain/entities/active_order.dart';
import 'package:mobile_frontend/domain/entities/pickup_route.dart';

/// Computes the driving route to the merchant pickup.
///
/// **Access design: TO SPECIFY.** The approved source is Google Routes API
/// (DRIVE, no live traffic). How the app reaches it — through a SHAHM
/// backend endpoint or a mobile call with an app-restricted key — is not
/// decided; an unrestricted server credential must never be embedded in
/// the app. Until it is decided the production implementation reports
/// "not configured".
abstract interface class PickupRouteRepository {
  /// The route from [origin] (the captain) to [destination] (the merchant).
  ///
  /// Throws [PickupRouteNotConfiguredException] or
  /// [PickupRouteUnavailableException].
  Future<PickupRoute> getDrivingRoute({
    required GeoPoint origin,
    required GeoPoint destination,
  });
}

/// No routing source is configured.
final class PickupRouteNotConfiguredException implements Exception {
  const PickupRouteNotConfiguredException();
}

/// The routing source did not return a route (network, quota, no route).
final class PickupRouteUnavailableException implements Exception {
  const PickupRouteUnavailableException();
}
