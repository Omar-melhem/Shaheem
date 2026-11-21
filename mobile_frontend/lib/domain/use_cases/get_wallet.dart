// Use cases: the captain's wallet (balance and last-7-days commission
// debits) and their lifetime delivery statistics.

import 'dart:async';

import 'package:mobile_frontend/domain/entities/wallet.dart';
import 'package:mobile_frontend/domain/errors/wallet_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/wallet_repository.dart';

/// Outcome of [GetWallet].
sealed class WalletResult {
  const WalletResult();
}

/// The server answered. History lists are inside the window, newest first,
/// and may be empty (confirmed: none in the window).
final class WalletLoaded extends WalletResult {
  const WalletLoaded(this.overview);

  final WalletOverview overview;
}

/// No wallet backend is connected; nothing was read.
final class WalletNotConfigured extends WalletResult {
  const WalletNotConfigured();
}

/// The device is offline.
final class WalletNoInternet extends WalletResult {
  const WalletNoInternet();
}

/// The server failed, timed out or answered unexpectedly.
final class WalletFailure extends WalletResult {
  const WalletFailure();
}

/// Loads the wallet: the single balance and the commission debits. The
/// visible history is a **display window**: the last [historyWindow] up to
/// now, start inclusive (UTC comparison), newest first. It never deletes or
/// truncates the server's ledger (D-A76).
class GetWallet {
  const GetWallet(
    this._repository, {
    this.now = _utcNow,
    this.timeout = const Duration(seconds: 20),
  });

  final WalletRepository _repository;

  /// Current time; tests pass a fixed clock.
  final DateTime Function() now;

  /// Safety net if the server never answers.
  final Duration timeout;

  /// Length of the visible history (owner decision, Task 34).
  static const historyWindow = Duration(days: 7);

  static DateTime _utcNow() => DateTime.now().toUtc();

  Future<WalletResult> call() async {
    final end = now().toUtc();
    final start = end.subtract(historyWindow);
    try {
      final overview = await _repository
          .getWallet(historySinceUtc: start)
          .timeout(timeout);
      bool inWindow(DateTime at) {
        final utc = at.toUtc();
        // Start inclusive; a record dated after "now" is malformed or from
        // a skewed clock and is not shown as history.
        return !utc.isBefore(start) && !utc.isAfter(end);
      }

      final debits =
          overview.debits.where((d) => inWindow(d.debitedAt)).toList()
            ..sort((a, b) => b.debitedAt.compareTo(a.debitedAt));
      return WalletLoaded(
        WalletOverview(
          summary: overview.summary,
          debits: List.unmodifiable(debits),
        ),
      );
    } on WalletBackendNotConfiguredException {
      return const WalletNotConfigured();
    } on WalletNetworkUnavailableException {
      return const WalletNoInternet();
    } on Object {
      return const WalletFailure();
    }
  }
}

/// Outcome of [GetDeliveryStatistics].
sealed class DeliveryStatisticsResult {
  const DeliveryStatisticsResult();
}

/// The server answered with the lifetime statistics.
final class DeliveryStatisticsLoaded extends DeliveryStatisticsResult {
  const DeliveryStatisticsLoaded(this.statistics);

  final CaptainDeliveryStatistics statistics;
}

/// No statistics backend is connected; nothing was read.
final class DeliveryStatisticsNotConfigured extends DeliveryStatisticsResult {
  const DeliveryStatisticsNotConfigured();
}

/// The device is offline.
final class DeliveryStatisticsNoInternet extends DeliveryStatisticsResult {
  const DeliveryStatisticsNoInternet();
}

/// The server failed, timed out or answered unexpectedly.
final class DeliveryStatisticsFailure extends DeliveryStatisticsResult {
  const DeliveryStatisticsFailure();
}

/// Loads the captain's **lifetime** delivery statistics (D-A76). Separate
/// from [GetWallet] so a statistics failure never hides a loaded balance.
class GetDeliveryStatistics {
  const GetDeliveryStatistics(
    this._repository, {
    this.timeout = const Duration(seconds: 20),
  });

  final WalletRepository _repository;

  /// Safety net if the server never answers.
  final Duration timeout;

  Future<DeliveryStatisticsResult> call() async {
    try {
      final statistics = await _repository.getDeliveryStatistics().timeout(
        timeout,
      );
      return DeliveryStatisticsLoaded(statistics);
    } on WalletBackendNotConfiguredException {
      return const DeliveryStatisticsNotConfigured();
    } on WalletNetworkUnavailableException {
      return const DeliveryStatisticsNoInternet();
    } on Object {
      return const DeliveryStatisticsFailure();
    }
  }
}
