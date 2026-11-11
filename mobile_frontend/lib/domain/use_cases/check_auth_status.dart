// Reusable use case: is there a valid session on this device?

import 'dart:async';

import 'package:mobile_frontend/domain/errors/auth_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/auth_repository.dart';
import 'package:mobile_frontend/domain/use_cases/clear_rejected_session.dart';

/// Outcome of [CheckAuthStatus].
sealed class AuthCheckResult {
  const AuthCheckResult();
}

/// The backend accepted the stored session.
final class AuthCheckAuthenticated extends AuthCheckResult {
  const AuthCheckAuthenticated();
}

/// No session is stored, or the backend rejected it (credentials cleared).
final class AuthCheckUnauthenticated extends AuthCheckResult {
  const AuthCheckUnauthenticated();
}

/// The account may not use this app.
final class AuthCheckBlocked extends AuthCheckResult {
  const AuthCheckBlocked();
}

/// The SHAHM backend could not be reached or timed out.
final class AuthCheckServiceUnavailable extends AuthCheckResult {
  const AuthCheckServiceUnavailable();
}

/// Unexpected error. Not proof that the user is signed out.
final class AuthCheckFailure extends AuthCheckResult {
  const AuthCheckFailure();
}

/// Determines whether the stored session is still valid.
///
/// Used at startup and for any later explicit revalidation. Only a backend
/// rejection signs the user out; timeouts, server errors and unknown errors
/// each have their own recoverable result.
class CheckAuthStatus {
  const CheckAuthStatus(
    this._repository, {
    this.timeout = const Duration(seconds: 20),
  });

  final AuthRepository _repository;

  /// Safety net if the repository never answers; maps to service unavailable.
  final Duration timeout;

  Future<AuthCheckResult> call() async {
    try {
      if (!await _repository.hasStoredSession()) {
        return const AuthCheckUnauthenticated();
      }
      await _repository.validateSession().timeout(timeout);
      return const AuthCheckAuthenticated();
    } on SessionInvalidException {
      await clearRejectedSession(_repository);
      return const AuthCheckUnauthenticated();
    } on AccountBlockedException {
      // Credentials are kept: the blocked-account session policy is a
      // backend decision that has not been made yet.
      return const AuthCheckBlocked();
    } on ServiceUnavailableException {
      return const AuthCheckServiceUnavailable();
    } on TimeoutException {
      return const AuthCheckServiceUnavailable();
    } catch (_) {
      return const AuthCheckFailure();
    }
  }
}
