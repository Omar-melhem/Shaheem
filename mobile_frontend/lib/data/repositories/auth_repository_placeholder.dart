// Temporary AuthRepository used until the SHAHM backend exists.

import 'package:mobile_frontend/domain/entities/app_user.dart';
import 'package:mobile_frontend/domain/errors/auth_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/auth_repository.dart';

/// TEMPORARY — no backend or credential storage exists yet.
///
/// Reports that no session is stored, so startup always routes to Login,
/// and reports sign-in as "backend not configured".
/// It makes no network request and never creates a user, token or session.
/// Replace it with the API-backed implementation (plus secure credential
/// storage) once the backend contract is agreed.
class AuthRepositoryPlaceholder implements AuthRepository {
  const AuthRepositoryPlaceholder();

  /// Always false: nothing can be stored without a backend.
  @override
  Future<bool> hasStoredSession() async => false;

  /// Unreachable while [hasStoredSession] is false. Throws instead of
  /// pretending a backend accepted the session if it is ever called.
  @override
  Future<void> validateSession() async {
    throw UnsupportedError('No authentication backend is configured yet.');
  }

  /// Unreachable while [hasStoredSession] is false. Throws instead of
  /// inventing a user if it is ever called.
  @override
  Future<AppUser> getCurrentUser() async {
    throw UnsupportedError('No authentication backend is configured yet.');
  }

  /// No backend exists, so sign-in can't be checked. Reports
  /// [BackendNotConfiguredException] instead of pretending the credentials
  /// were accepted or rejected. Nothing is sent or stored.
  @override
  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    throw const BackendNotConfiguredException();
  }

  /// Nothing is stored, so there is nothing to clear.
  @override
  Future<void> clearSession() async {}
}
