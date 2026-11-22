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
    this.routePath,
  });

  /// The order this map belongs to.
  final String orderId;

  /// Title for the destination marker.
  final String restaurantName;

  /// Destination: the MERCHANT's valid coordinates. There is no customer
  /// address in this type on purpose (D-A62).
  final GeoPoint pickup;

  /// The captain's position; null when permission was denied or no
  /// position is available, in which case only the destination is shown.
  final GeoPoint? captainLocation;

  /// The road route from the routing source (captain → merchant), or null.
  /// Never a straight line drawn by the app.
  final List<GeoPoint>? routePath;
}

/// Builds the in-app map for [PickupMapData].
///
/// The approved provider is Google Maps Flutter (D-A62). Its adapter is
/// `googlePickupMapBuilder` (`google_pickup_map.dart`), enabled only when
/// the native keys are provisioned (`--dart-define=SHAHM_GOOGLE_MAPS=true`);
/// otherwise no builder is passed and the screen says the map is
/// unavailable.
typedef PickupMapBuilder =
    Widget Function(BuildContext context, PickupMapData data);
