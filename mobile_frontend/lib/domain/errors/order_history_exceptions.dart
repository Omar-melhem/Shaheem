// Typed failures that order-history data sources report to the domain.

/// Base type for failures while reading the captain's order history.
sealed class OrderHistoryException implements Exception {
  const OrderHistoryException();
}

/// No history backend is connected yet (development placeholder). Nothing
/// was read. Distinct from an empty history.
final class OrderHistoryBackendNotConfiguredException
    extends OrderHistoryException {
  const OrderHistoryBackendNotConfiguredException();
}

/// The device has no usable internet.
final class OrderHistoryNetworkUnavailableException
    extends OrderHistoryException {
  const OrderHistoryNetworkUnavailableException();
}

/// The backend could not be reached or failed.
final class OrderHistoryServiceUnavailableException
    extends OrderHistoryException {
  const OrderHistoryServiceUnavailableException();
}
