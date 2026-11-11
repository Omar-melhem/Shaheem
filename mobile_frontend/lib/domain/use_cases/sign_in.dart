// Use case: sign in with username + password and load the user.

import 'dart:async';

import 'package:mobile_frontend/domain/entities/app_user.dart';
import 'package:mobile_frontend/domain/errors/auth_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/auth_repository.dart';
import 'package:mobile_frontend/domain/use_cases/get_current_user.dart';

/// Outcome of [SignIn]. Each case gets its own message in the UI.
sealed class SignInResult {
  const SignInResult();
}

/// Credentials accepted and a valid profile loaded.
final class SignInSuccess extends SignInResult {
  const SignInSuccess(this.user);

  final AppUser user;
}

/// The backend rejected the credentials. Shown generically, never revealing
/// whether the username exists.
final class SignInInvalidCredentials extends SignInResult {
  const SignInInvalidCredentials();
}

/// The account may not use this app (only if the backend reports it).
final class SignInAccountBlocked extends SignInResult {
  const SignInAccountBlocked();
}

/// The device has no usable internet.
final class SignInNoInternet extends SignInResult {
  const SignInNoInternet();
}

/// The backend was unreachable, failed or timed out.
final class SignInServiceUnavailable extends SignInResult {
  const SignInServiceUnavailable();
}

/// Credentials were accepted but the profile failed to load or was
/// malformed. No user is invented.
final class SignInProfileFailure extends SignInResult {
  const SignInProfileFailure();
}

/// No authentication backend is connected yet (current development state).
final class SignInBackendNotConfigured extends SignInResult {
  const SignInBackendNotConfigured();
}

/// Unexpected error.
final class SignInFailure extends SignInResult {
  const SignInFailure();
}

/// Signs the user in, then loads their profile with [GetCurrentUser] — the
/// same profile path startup uses, so Login and startup produce the same
/// `AppUser` (the repository may serve a profile cached from the login
/// response instead of a second request).
///
/// Never logs the password, and never turns an unknown error into "invalid
/// credentials".
class SignIn {
  const SignIn(
    this._repository,
    this._getCurrentUser, {
    this.timeout = const Duration(seconds: 20),
  });

  final AuthRepository _repository;
  final GetCurrentUser _getCurrentUser;

  /// Safety net if the sign-in request never answers.
  final Duration timeout;

  Future<SignInResult> call({
    required String username,
    required String password,
  }) async {
    try {
      await _repository
          .signIn(username: username, password: password)
          .timeout(timeout);
    } on InvalidCredentialsException {
      return const SignInInvalidCredentials();
    } on AccountBlockedException {
      return const SignInAccountBlocked();
    } on NetworkUnavailableException {
      return const SignInNoInternet();
    } on ServiceUnavailableException {
      return const SignInServiceUnavailable();
    } on TimeoutException {
      return const SignInServiceUnavailable();
    } on BackendNotConfiguredException {
      return const SignInBackendNotConfigured();
    } catch (_) {
      // Deliberately not "invalid credentials": nothing confirmed that.
      return const SignInFailure();
    }

    return switch (await _getCurrentUser()) {
      CurrentUserLoaded(:final user) => SignInSuccess(user),
      CurrentUserBlocked() => const SignInAccountBlocked(),
      CurrentUserUnavailable() ||
      CurrentUserInvalid() => const SignInProfileFailure(),
      // The session was rejected right after being accepted: unexpected.
      CurrentUserUnauthorized() ||
      CurrentUserFailure() => const SignInFailure(),
    };
  }
}
