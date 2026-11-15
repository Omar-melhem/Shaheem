// Temporary CaptainLocationRepository used until a location provider is
// approved and integrated.

import 'package:mobile_frontend/domain/entities/active_order.dart';
import 'package:mobile_frontend/domain/errors/order_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/captain_location_repository.dart';

/// TEMPORARY — no location package is approved or configured yet (D-P06,
/// D-P12), and no location permission is declared on Android or iOS.
///
/// Reports "not configured". It requests no permission and never returns a
/// made-up position.
class CaptainLocationRepositoryPlaceholder
    implements CaptainLocationRepository {
  const CaptainLocationRepositoryPlaceholder();

  @override
  Future<GeoPoint> getCurrentLocation() async {
    throw const LocationNotConfiguredException();
  }
}
