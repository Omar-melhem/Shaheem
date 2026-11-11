// Typed failures that authentication repositories report to the domain.
//
// Data implementations translate transport details (HTTP status codes,
// timeouts, decoding errors) into one of these so domain and UI can react to
// each case differently instead of guessing from a generic error.

/// Base type for all authentication/session failures.
sealed class AuthException implements Exception {
  const AuthException();
}

/// The backend rejected the stored session (expired, revoked, invalid —
/// typically HTTP 401). The user must sign in again.
final class SessionInvalidException extends AuthException {
  const SessionInvalidException();
}

/// The session is valid but the account may not use this app: disabled,
/// suspended, or wrong role (typically HTTP 403). Not an offline case.
final class AccountBlockedException extends AuthException {
  const AccountBlockedException();
}

/// The SHAHM backend could not be reached or did not answer usefully
/// (DNS/connection failure, timeout, 5xx) before the session was confirmed.
/// The device may still have internet; this is not "no internet".
final class ServiceUnavailableException extends AuthException {
  const ServiceUnavailableException();
}

/// The session was accepted but loading the user's profile failed
/// (timeout or server error). The session must not be cleared for this.
final class ProfileUnavailableException extends AuthException {
  const ProfileUnavailableException();
}

/// The profile response was malformed or missing required identity data.
/// The app must not continue with a partial or invented user.
final class InvalidProfileException extends AuthException {
  const InvalidProfileException();
}

/// Login: the backend rejected the username/password combination.
/// The UI must show a generic message and never reveal whether the account
/// exists.
final class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException();
}

/// A request failed because the device has no usable internet (for example
/// a DNS or connection failure detected before reaching any server).
final class NetworkUnavailableException extends AuthException {
  const NetworkUnavailableException();
}

/// No authentication backend is connected yet (development placeholder).
/// Distinct from rejected credentials: nothing was checked.
final class BackendNotConfiguredException extends AuthException {
  const BackendNotConfiguredException();
}
