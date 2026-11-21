// Typed failures that captain-account data sources report to the domain.

/// Base type for failures while reading the rating or requesting deletion.
sealed class CaptainAccountException implements Exception {
  const CaptainAccountException();
}

/// No account backend is connected yet (development placeholder). Nothing
/// was read or sent.
final class CaptainAccountBackendNotConfiguredException
    extends CaptainAccountException {
  const CaptainAccountBackendNotConfiguredException();
}

/// The device has no usable internet; nothing was sent.
final class CaptainAccountNetworkUnavailableException
    extends CaptainAccountException {
  const CaptainAccountNetworkUnavailableException();
}

/// The backend could not be reached or failed.
final class CaptainAccountServiceUnavailableException
    extends CaptainAccountException {
  const CaptainAccountServiceUnavailableException();
}

/// The server requires a fresh sign-in before it accepts the request.
final class CaptainAccountReauthenticationRequiredException
    extends CaptainAccountException {
  const CaptainAccountReauthenticationRequiredException();
}
