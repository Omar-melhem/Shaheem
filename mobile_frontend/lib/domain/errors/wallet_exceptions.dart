// Typed failures that wallet data sources report to the domain.

/// Base type for failures while reading the wallet.
sealed class WalletException implements Exception {
  const WalletException();
}

/// No wallet backend is connected yet (development placeholder). Nothing
/// was read. Distinct from a zero balance or an empty history.
final class WalletBackendNotConfiguredException extends WalletException {
  const WalletBackendNotConfiguredException();
}

/// The device has no usable internet.
final class WalletNetworkUnavailableException extends WalletException {
  const WalletNetworkUnavailableException();
}

/// The backend could not be reached or failed.
final class WalletServiceUnavailableException extends WalletException {
  const WalletServiceUnavailableException();
}
