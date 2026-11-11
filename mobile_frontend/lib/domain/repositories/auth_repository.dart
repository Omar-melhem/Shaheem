// Contract between the domain and whatever stores and validates sessions.

import 'package:mobile_frontend/domain/entities/app_user.dart';

/// Session and current-user operations the domain needs from the data layer.
///
/// The backend is the source of truth for whether a session is valid and who
/// the user is. Implementations report failures with the typed exceptions in
/// `domain/errors/auth_exceptions.dart`.
///
/// If the real backend validates the session and returns the profile in one
/// response, an implementation may do that single request in
/// [validateSession] and return the cached result from [getCurrentUser]
/// (clearing the cache once read), instead of making a second request.
abstract class AuthRepository {
  /// Whether a session credential is stored on this device. Local check only;
  /// it says nothing about whether the backend still accepts the session.
  Future<bool> hasStoredSession();

  /// Asks the backend whether the stored session is still valid.
  ///
  /// Completes normally if it is. Throws [SessionInvalidException],
  /// [AccountBlockedException] or [ServiceUnavailableException].
  Future<void> validateSession();

  /// Loads the signed-in user's profile through an authorized request.
  ///
  /// Throws [SessionInvalidException], [AccountBlockedException],
  /// [ServiceUnavailableException], [ProfileUnavailableException] or
  /// [InvalidProfileException].
  Future<AppUser> getCurrentUser();

  /// Signs in with [username] and [password] and stores the resulting
  /// session credential.
  ///
  /// Completes normally when the backend accepts the credentials. If the
  /// backend also returns the user's profile, the implementation may cache
  /// it for the next [getCurrentUser] call instead of requesting it again.
  /// The password must never be logged or included in exception messages.
  ///
  /// Throws [InvalidCredentialsException], [AccountBlockedException],
  /// [NetworkUnavailableException], [ServiceUnavailableException] or
  /// [BackendNotConfiguredException].
  Future<void> signIn({required String username, required String password});

  /// Removes stored session credentials from this device.
  Future<void> clearSession();
}
