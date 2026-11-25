// Use cases: the captain's rating and the account-deletion request.

import 'dart:async';

import 'package:mobile_frontend/domain/entities/captain_account.dart';
import 'package:mobile_frontend/domain/errors/captain_account_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/captain_account_repository.dart';

/// Outcome of [GetCaptainRating].
sealed class RatingResult {
  const RatingResult();
}

/// The server answered with a valid rating (possibly "no ratings yet").
final class RatingLoaded extends RatingResult {
  const RatingLoaded(this.rating);

  final CaptainRating rating;
}

/// The server answered with values that cannot be shown honestly (a
/// negative or incoherent count, or an average that is not finite or lies
/// outside 0..5). Shown as "unavailable"; never clamped or rescaled.
final class RatingInvalid extends RatingResult {
  const RatingInvalid();
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

/// Reads the captain's rating (D-A77) and validates it
/// ([CaptainRating.isValid]) before the UI may show it.
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
      final rating = await _repository.getRating().timeout(timeout);
      return rating.isValid ? RatingLoaded(rating) : const RatingInvalid();
    } on CaptainAccountBackendNotConfiguredException {
      return const RatingNotConfigured();
    } on CaptainAccountNetworkUnavailableException {
      return const RatingNoInternet();
    } on TimeoutException {
      // Read timeout (R04): the service did not answer; this read has no
      // separate "service unavailable" outcome, so it is a retryable
      // failure — never "offline" and never "not configured".
      return const RatingFailure();
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

/// The server failed; nothing is assumed deleted.
final class AccountDeletionFailure extends AccountDeletionResult {
  const AccountDeletionFailure();
}

/// No answer arrived in time (R04, ARCH-06): the request may or may not
/// have reached the server, so the outcome is unknown. Never "deleted",
/// and never "not sent" either.
final class AccountDeletionUnconfirmed extends AccountDeletionResult {
  const AccountDeletionUnconfirmed();
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

  /// Safety net; a timeout is an unknown outcome
  /// ([AccountDeletionUnconfirmed]), never "deleted" or "not sent".
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
    } on TimeoutException {
      return const AccountDeletionUnconfirmed();
    } on Object {
      return const AccountDeletionFailure();
    }
  }
}
