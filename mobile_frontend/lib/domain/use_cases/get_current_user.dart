// Reusable use case: load the signed-in user's profile.

import 'dart:async';

import 'package:mobile_frontend/domain/entities/app_user.dart';
import 'package:mobile_frontend/domain/errors/auth_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/auth_repository.dart';
import 'package:mobile_frontend/domain/use_cases/clear_rejected_session.dart';

/// Outcome of [GetCurrentUser].
sealed class CurrentUserResult {
  const CurrentUserResult();
}

/// The profile was loaded and is usable.
final class CurrentUserLoaded extends CurrentUserResult {
  const CurrentUserLoaded(this.user);

  final AppUser user;
}

/// The backend rejected the session while loading the profile (credentials
/// cleared). The user must sign in again.
final class CurrentUserUnauthorized extends CurrentUserResult {
  const CurrentUserUnauthorized();
}

/// The account may not use this app.
final class CurrentUserBlocked extends CurrentUserResult {
  const CurrentUserBlocked();
}

/// Temporary failure (timeout, server error, backend unreachable). The
/// session stays; the caller should offer a retry.
final class CurrentUserUnavailable extends CurrentUserResult {
  const CurrentUserUnavailable();
}

/// The profile response was malformed or missing its identifier. No user is
/// produced.
final class CurrentUserInvalid extends CurrentUserResult {
  const CurrentUserInvalid();
}

/// Unexpected error. Not proof that the user is signed out.
final class CurrentUserFailure extends CurrentUserResult {
  const CurrentUserFailure();
}

/// Loads the signed-in user's profile from the configured repository. The
/// backend is the source of truth once it exists.
///
/// Used by startup; any feature that explicitly needs a fresh profile can
/// call it too. Screens that only need the current user should read
/// `AppSessionCubit` instead of calling this again.
class GetCurrentUser {
  const GetCurrentUser(
    this._repository, {
    this.timeout = const Duration(seconds: 20),
  });

  final AuthRepository _repository;

  /// Safety net if the repository never answers; maps to unavailable.
  final Duration timeout;

  Future<CurrentUserResult> call() async {
    try {
      final user = await _repository.getCurrentUser().timeout(timeout);
      return CurrentUserLoaded(user);
    } on SessionInvalidException {
      await clearRejectedSession(_repository);
      return const CurrentUserUnauthorized();
    } on AccountBlockedException {
      return const CurrentUserBlocked();
    } on ServiceUnavailableException {
      return const CurrentUserUnavailable();
    } on ProfileUnavailableException {
      return const CurrentUserUnavailable();
    } on TimeoutException {
      return const CurrentUserUnavailable();
    } on InvalidProfileException {
      return const CurrentUserInvalid();
    } catch (_) {
      return const CurrentUserFailure();
    }
  }
}
