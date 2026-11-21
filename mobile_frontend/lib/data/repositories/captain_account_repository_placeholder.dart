// Temporary CaptainAccountRepository used until the account backend exists.

import 'package:mobile_frontend/domain/entities/captain_account.dart';
import 'package:mobile_frontend/domain/errors/captain_account_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/captain_account_repository.dart';

/// TEMPORARY — there is no rating or account-deletion backend or API
/// contract yet (TO SPECIFY, D-P37, D-P39).
///
/// Always reports "backend not configured": it never returns a rating (not
/// even "no ratings"), never sends or pretends to send a deletion request,
/// never signs anybody out and makes no network call.
class CaptainAccountRepositoryPlaceholder implements CaptainAccountRepository {
  const CaptainAccountRepositoryPlaceholder();

  @override
  Future<CaptainRating> getRating() async {
    throw const CaptainAccountBackendNotConfiguredException();
  }

  @override
  Future<AccountDeletionStatus> requestAccountDeletion() async {
    throw const CaptainAccountBackendNotConfiguredException();
  }
}
