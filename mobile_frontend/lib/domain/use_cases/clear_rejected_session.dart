// Shared cleanup used when the backend rejects the stored session.

import 'package:mobile_frontend/domain/repositories/auth_repository.dart';

/// Removes credentials the backend has rejected (expired/revoked/401).
///
/// Shared by [CheckAuthStatus] and [GetCurrentUser] so the rule lives in one
/// place. A failure to clear is ignored: the session is already unusable, the
/// user goes to Login either way, and a leftover credential is rejected
/// again on the next launch.
Future<void> clearRejectedSession(AuthRepository repository) async {
  try {
    await repository.clearSession();
  } catch (_) {
    // See the doc comment: the outcome (go to Login) does not change.
  }
}
