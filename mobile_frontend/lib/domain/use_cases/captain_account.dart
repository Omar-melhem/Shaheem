// Use cases: the captain's rating and the account-deletion request.

import 'dart:async';

import 'package:mobile_frontend/domain/entities/captain_account.dart';
import 'package:mobile_frontend/domain/errors/captain_account_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/captain_account_repository.dart';

/// Outcome of [GetCaptainRating].
sealed class RatingResult {
  const RatingResult();
}

/// The server answered (possibly "no ratings yet").
final class RatingLoaded extends RatingResult {
  const RatingLoaded(this.rating);

  final CaptainRating rating;
}

/// No rating backend is connected; nothing was read.
final class RatingNotConfigured extends RatingResult {
  const RatingNotConfigured();
}

/// The device is offline.
final class RatingNoInternet extends RatingResult {
  const RatingNoInternet();
}

/// The server failed, timed out or answered unexpectedly.
final class RatingFailure extends RatingResult {
  const RatingFailure();
}

/// Reads the captain's rating (D-A77).
class GetCaptainRating {
  const GetCaptainRating(
    this._repository, {
    this.timeout = const Duration(seconds: 20),
  });

  final CaptainAccountRepository _repository;

  /// Safety net if the server never answers.
  final Duration timeout;

  Future<RatingResult> call() async {
    try {
      return RatingLoaded(await _repository.getRating().timeout(timeout));
    } on CaptainAccountBackendNotConfiguredException {
      return const RatingNotConfigured();
    } on CaptainAccountNetworkUnavailableException {
      return const RatingNoInternet();
    } on Object {
      return const RatingFailure();
    }
  }
}

/// Outcome of [RequestAccountDeletion] (D-A78). "Request not sent" is the
/// UI's state before confirmation; every value here is the answer to one
/// confirmed submission.
sealed class AccountDeletionResult {
  const AccountDeletionResult();
}

/// Accepted; still being processed. The account is **not** deleted yet.
final class AccountDeletionPending extends AccountDeletionResult {
  const AccountDeletionPending();
}

/// The server confirmed the deletion.
final class AccountDeletionCompleted extends AccountDeletionResult {
  const AccountDeletionCompleted();
}

/// No deletion backend is connected; nothing was sent or deleted.
final class AccountDeletionNotConfigured extends AccountDeletionResult {
  const AccountDeletionNotConfigured();
}

/// Offline; nothing was sent.
final class AccountDeletionNoInternet extends AccountDeletionResult {
  const AccountDeletionNoInternet();
}

/// The server failed or the answer is unknown; nothing is assumed deleted.
final class AccountDeletionFailure extends AccountDeletionResult {
  const AccountDeletionFailure();
}

/// The server asks for a fresh sign-in first.
final class AccountDeletionReauthenticationRequired
    extends AccountDeletionResult {
  const AccountDeletionReauthenticationRequired();
}

/// Sends the confirmed deletion request through the repository boundary.
class RequestAccountDeletion {
  const RequestAccountDeletion(
    this._repository, {
    this.timeout = const Duration(seconds: 30),
  });

  final CaptainAccountRepository _repository;

  /// Safety net; a timeout is a failure (never "deleted").
  final Duration timeout;

  Future<AccountDeletionResult> call() async {
    try {
      final status = await _repository.requestAccountDeletion().timeout(
        timeout,
      );
      return switch (status) {
        AccountDeletionStatus.pending => const AccountDeletionPending(),
        AccountDeletionStatus.completed => const AccountDeletionCompleted(),
      };
    } on CaptainAccountBackendNotConfiguredException {
      return const AccountDeletionNotConfigured();
    } on CaptainAccountNetworkUnavailableException {
      return const AccountDeletionNoInternet();
    } on CaptainAccountReauthenticationRequiredException {
      return const AccountDeletionReauthenticationRequired();
    } on Object {
      return const AccountDeletionFailure();
    }
  }
}
