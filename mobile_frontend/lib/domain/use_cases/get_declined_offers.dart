// Use case: load the offers this captain declined.

import 'dart:async';

import 'package:mobile_frontend/domain/entities/declined_offer.dart';
import 'package:mobile_frontend/domain/errors/order_history_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/order_history_repository.dart';

/// Outcome of [GetDeclinedOffers].
sealed class DeclinedOffersResult {
  const DeclinedOffersResult();
}

/// The server answered; [records] may be empty (confirmed: none).
final class DeclinedOffersLoaded extends DeclinedOffersResult {
  const DeclinedOffersLoaded(this.records);

  final List<DeclinedOfferRecord> records;
}

/// No history backend is connected; nothing was read.
final class DeclinedOffersNotConfigured extends DeclinedOffersResult {
  const DeclinedOffersNotConfigured();
}

/// The device is offline.
final class DeclinedOffersNoInternet extends DeclinedOffersResult {
  const DeclinedOffersNoInternet();
}

/// The server failed, timed out or answered unexpectedly.
final class DeclinedOffersFailure extends DeclinedOffersResult {
  const DeclinedOffersFailure();
}

/// Loads the declined offers, newest first (undated records keep the
/// server's order after the dated ones).
class GetDeclinedOffers {
  const GetDeclinedOffers(
    this._repository, {
    this.timeout = const Duration(seconds: 20),
  });

  final OrderHistoryRepository _repository;

  /// Safety net if the server never answers.
  final Duration timeout;

  Future<DeclinedOffersResult> call() async {
    try {
      final records = await _repository.getDeclinedOffers().timeout(timeout);
      final dated = [
        for (final r in records)
          if (r.declinedAt != null) r,
      ]..sort((a, b) => b.declinedAt!.compareTo(a.declinedAt!));
      return DeclinedOffersLoaded(
        List.unmodifiable([
          ...dated,
          for (final r in records)
            if (r.declinedAt == null) r,
        ]),
      );
    } on OrderHistoryBackendNotConfiguredException {
      return const DeclinedOffersNotConfigured();
    } on OrderHistoryNetworkUnavailableException {
      return const DeclinedOffersNoInternet();
    } on TimeoutException {
      // Read timeout (R04): retryable failure, never "offline" or "empty".
      return const DeclinedOffersFailure();
    } on Object {
      return const DeclinedOffersFailure();
    }
  }
}
