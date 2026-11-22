// Use case: read one page of the captain's completed deliveries.

import 'dart:async';

import 'package:mobile_frontend/domain/entities/order_workflow.dart';
import 'package:mobile_frontend/domain/errors/order_history_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/order_history_repository.dart';

/// Outcome of [GetCompletedDeliveries].
sealed class CompletedDeliveriesResult {
  const CompletedDeliveriesResult();
}

/// The server answered (the page may be empty: confirmed none).
final class CompletedDeliveriesLoaded extends CompletedDeliveriesResult {
  const CompletedDeliveriesLoaded(this.page);

  final CompletedDeliveriesPage page;
}

/// No history backend is connected; nothing was checked.
final class CompletedDeliveriesNotConfigured extends CompletedDeliveriesResult {
  const CompletedDeliveriesNotConfigured();
}

/// Offline while reading.
final class CompletedDeliveriesNoInternet extends CompletedDeliveriesResult {
  const CompletedDeliveriesNoInternet();
}

/// Service failure or timeout: retryable, never "empty".
final class CompletedDeliveriesFailure extends CompletedDeliveriesResult {
  const CompletedDeliveriesFailure();
}

/// Reads one page of completed deliveries exactly as the server returns
/// them: no sorting, filtering or invented rows on the phone.
class GetCompletedDeliveries {
  const GetCompletedDeliveries(
    this._repository, {
    this.timeout = const Duration(seconds: 20),
  });

  final OrderHistoryRepository _repository;
  final Duration timeout;

  Future<CompletedDeliveriesResult> call({String? cursor}) async {
    try {
      final page = await _repository
          .getCompletedDeliveries(cursor: cursor)
          .timeout(timeout);
      return CompletedDeliveriesLoaded(
        CompletedDeliveriesPage(
          items: List.unmodifiable(page.items),
          nextCursor: page.nextCursor,
        ),
      );
    } on OrderHistoryBackendNotConfiguredException {
      return const CompletedDeliveriesNotConfigured();
    } on OrderHistoryNetworkUnavailableException {
      return const CompletedDeliveriesNoInternet();
    } on TimeoutException {
      // Read timeout (R04): retryable failure, never "empty".
      return const CompletedDeliveriesFailure();
    } on Object {
      return const CompletedDeliveriesFailure();
    }
  }
}
