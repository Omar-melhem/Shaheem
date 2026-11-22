// A driving route from the captain to the merchant pickup (D-A62).

import 'package:mobile_frontend/domain/entities/active_order.dart';

/// A real road route returned by the approved routing source (Google Routes
/// API, DRIVE, without live traffic). Never a straight line computed on the
/// phone: when no routing source answers, there is no route at all.
class PickupRoute {
  const PickupRoute({
    required this.path,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  /// The decoded route polyline, captain first, merchant last.
  final List<GeoPoint> path;

  final int distanceMeters;
  final int durationSeconds;
}
