// Contract for reading the captain's current device location.

import 'package:mobile_frontend/domain/entities/active_order.dart';

/// Gives the device's current position.
///
/// Implementations ask for the location permission only when this is
/// called (never at app start) and must not prompt again by themselves
/// after a denial; a new prompt only follows a new, user-initiated call.
abstract interface class CaptainLocationRepository {
  /// The current position.
  ///
  /// Throws a `LocationException` when permission is denied, no position is
  /// available, or no provider is integrated.
  Future<GeoPoint> getCurrentLocation();
}
