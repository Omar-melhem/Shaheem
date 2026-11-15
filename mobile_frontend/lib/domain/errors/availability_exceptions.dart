// Typed failures that availability data sources report to the domain.

/// Base type for failures while reading or changing availability.
sealed class AvailabilityException implements Exception {
  const AvailabilityException();
}

/// No availability backend is connected yet (development placeholder).
/// Nothing was checked or changed.
final class AvailabilityBackendNotConfiguredException
    extends AvailabilityException {
  const AvailabilityBackendNotConfiguredException();
}

/// The device has no usable internet.
final class AvailabilityNetworkUnavailableException
    extends AvailabilityException {
  const AvailabilityNetworkUnavailableException();
}

/// The SHAHM backend could not be reached or answered with a server error.
/// For a change request the outcome is unknown.
final class AvailabilityServiceUnavailableException
    extends AvailabilityException {
  const AvailabilityServiceUnavailableException();
}

/// The backend answered and refused the change (e.g. the captain is not
/// eligible). The status did not change.
final class AvailabilityRejectedException extends AvailabilityException {
  const AvailabilityRejectedException();
}
