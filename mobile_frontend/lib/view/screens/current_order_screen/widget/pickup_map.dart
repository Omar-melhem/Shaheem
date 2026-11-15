// The boundary between the Current Order screen and a map implementation.

import 'package:flutter/widgets.dart';
import 'package:mobile_frontend/domain/entities/active_order.dart';

/// Everything a map needs to show the pickup of one active order.
class PickupMapData {
  const PickupMapData({
    required this.orderId,
    required this.restaurantName,
    required this.pickup,
    this.captainLocation,
  });

  /// The order this map belongs to.
  final String orderId;

  /// Title for the destination marker.
  final String restaurantName;

  /// Destination: the RESTAURANT's well-formed coordinates. There is no
  /// customer address in this type on purpose.
  final GeoPoint pickup;

  /// The captain's position; null when permission was denied or no
  /// position is available, in which case only the destination is shown.
  final GeoPoint? captainLocation;
}

/// Builds the in-app map for [PickupMapData].
///
/// No maps provider is approved or configured yet (D-P05), so the app
/// passes no builder and the screen shows a "map unavailable" state. When a
/// provider is chosen, its widget is plugged in here; a route line or
/// turn-by-turn guidance additionally needs a routing provider.
typedef PickupMapBuilder =
    Widget Function(BuildContext context, PickupMapData data);
