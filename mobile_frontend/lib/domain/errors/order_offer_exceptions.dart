// Typed failures that order-offer data sources report to the domain.

/// Base type for failures while reading or answering order offers.
sealed class OrderOfferException implements Exception {
  const OrderOfferException();
}

/// No offers backend is connected yet (development placeholder). Nothing
/// was checked or sent. Distinct from "no offers".
final class OrderOfferBackendNotConfiguredException
    extends OrderOfferException {
  const OrderOfferBackendNotConfiguredException();
}

/// The device has no usable internet.
final class OrderOfferNetworkUnavailableException extends OrderOfferException {
  const OrderOfferNetworkUnavailableException();
}

/// The backend could not be reached or failed. For a command, the outcome
/// is unknown.
final class OrderOfferServiceUnavailableException extends OrderOfferException {
  const OrderOfferServiceUnavailableException();
}

/// The offer is no longer actionable for this captain (expired, withdrawn,
/// declined, or accepted by another captain).
final class OrderOfferNoLongerAvailableException extends OrderOfferException {
  const OrderOfferNoLongerAvailableException();
}

/// The backend refused the command for this captain (e.g. not eligible,
/// already on an active order, wallet floor). The offer did not change.
final class OrderOfferRefusedException extends OrderOfferException {
  const OrderOfferRefusedException();
}
