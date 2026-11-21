// Contract for the captain's rating and the account-deletion request.

import 'package:mobile_frontend/domain/entities/captain_account.dart';

/// The signed-in captain's account on the SHAHM backend (D-A77, D-A78).
///
/// **API contract: TO SPECIFY.** No rating endpoint, deletion command,
/// retention rule, timing or session-revocation contract exists yet
/// (D-P37, D-P39); nothing here invents them.
abstract interface class CaptainAccountRepository {
  /// The captain's rating. Throws a `CaptainAccountException` for "not
  /// configured", network or server failures.
  Future<CaptainRating> getRating();

  /// Sends the captain's own account-deletion request, once, after the
  /// captain confirmed it. Returns what the server reports (pending or
  /// completed). Throws a `CaptainAccountException` when nothing was
  /// accepted (including "reauthentication required").
  Future<AccountDeletionStatus> requestAccountDeletion();
}
