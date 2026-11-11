// Use case for ending the user's session on this device.

import 'package:mobile_frontend/domain/repositories/auth_repository.dart';

/// Clears stored session credentials. Used for logout and when a later API
/// call reports that the session is no longer valid.
class SignOut {
  const SignOut(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.clearSession();
}
