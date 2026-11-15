// Use case: read the captain's current location for the pickup map.

import 'dart:async';

import 'package:mobile_frontend/domain/entities/active_order.dart';
import 'package:mobile_frontend/domain/errors/order_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/captain_location_repository.dart';

/// Outcome of [GetCaptainLocation].
sealed class CaptainLocationResult {
  const CaptainLocationResult();
}

/// A usable position.
final class CaptainLocationFound extends CaptainLocationResult {
  const CaptainLocationFound(this.location);

  final GeoPoint location;
}

/// The user denied the location permission.
final class CaptainLocationPermissionDenied extends CaptainLocationResult {
  const CaptainLocationPermissionDenied();
}

/// No position could be obtained (services off, no fix, timeout, or an
/// invalid reading).
final class CaptainLocationUnavailable extends CaptainLocationResult {
  const CaptainLocationUnavailable();
}

/// No location provider is integrated yet.
final class CaptainLocationNotConfigured extends CaptainLocationResult {
  const CaptainLocationNotConfigured();
}

/// Reads the device position once and classifies the failures.
///
/// Called only while an active order's pickup map is shown, and again only
/// when the user asks to retry; it never polls or prompts on its own.
class GetCaptainLocation {
  const GetCaptainLocation(
    this._repository, {
    this.timeout = const Duration(seconds: 20),
  });

  final CaptainLocationRepository _repository;

  /// Safety net if no fix arrives; maps to unavailable.
  final Duration timeout;

  Future<CaptainLocationResult> call() async {
    try {
      final location = await _repository.getCurrentLocation().timeout(timeout);
      // A nonsensical reading is treated as no reading.
      return location.isValid
          ? CaptainLocationFound(location)
          : const CaptainLocationUnavailable();
    } on LocationPermissionDeniedException {
      return const CaptainLocationPermissionDenied();
    } on LocationNotConfiguredException {
      return const CaptainLocationNotConfigured();
    } catch (_) {
      // LocationUnavailableException, a timeout, or anything unexpected.
      return const CaptainLocationUnavailable();
    }
  }
}
