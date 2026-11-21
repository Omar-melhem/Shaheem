// SHAHM DEMO (Task 37) — AuthRepository for the fictional demo captain.
// Removed by `bash tool/demo/remove_demo.sh --apply`.

import 'package:mobile_frontend/demo/demo_state.dart';
import 'package:mobile_frontend/domain/entities/app_user.dart';
import 'package:mobile_frontend/domain/errors/auth_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/auth_repository.dart';

/// The real `AuthRepository` contract, answered by [DemoState] in memory.
///
/// Used only when the demo is enabled (debug build + `SHAHM_DEMO=true`).
/// The real Login form, validation, `SignIn`, `AppSessionCubit` and router
/// guard run unchanged. Only the fixture credentials sign in; anything else
/// is "invalid credentials". The fictional token stays in [DemoState]: it is
/// never sent anywhere, written to storage or logged. Nothing survives a
/// restart, so the demo always opens on Login.
class DemoAuthRepository implements AuthRepository {
  const DemoAuthRepository(this._state);

  final DemoState _state;

  @override
  Future<bool> hasStoredSession() async => _state.session != null;

  @override
  Future<void> validateSession() async {
    if (_state.session == null) throw const SessionInvalidException();
  }

  @override
  Future<AppUser> getCurrentUser() async {
    final session = _state.session;
    if (session == null) throw const SessionInvalidException();
    return session.user;
  }

  @override
  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    if (!_state.signIn(username, password)) {
      throw const InvalidCredentialsException();
    }
  }

  @override
  Future<void> clearSession() async => _state.signOut();
}
