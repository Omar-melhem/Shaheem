// Typed failures that order and location data sources report to the domain.

/// Base type for failures while reading order data.
sealed class OrderException implements Exception {
  const OrderException();
}

/// The device has no usable internet.
final class OrderNetworkUnavailableException extends OrderException {
  const OrderNetworkUnavailableException();
}

/// The SHAHM backend could not be reached or answered with a server error.
final class OrderServiceUnavailableException extends OrderException {
  const OrderServiceUnavailableException();
}

/// No orders backend is connected yet (development placeholder). Distinct
/// from "no active order": nothing was checked.
final class OrderBackendNotConfiguredException extends OrderException {
  const OrderBackendNotConfiguredException();
}

/// Base type for failures while reading the device location.
sealed class LocationException implements Exception {
  const LocationException();
}

/// The user did not allow the app to use the device location.
final class LocationPermissionDeniedException extends LocationException {
  const LocationPermissionDeniedException();
}

/// Permission is fine but no position could be obtained (location services
/// off, no fix, timeout).
final class LocationUnavailableException extends LocationException {
  const LocationUnavailableException();
}

/// No location provider is integrated yet (development placeholder).
final class LocationNotConfiguredException extends LocationException {
  const LocationNotConfiguredException();
}
