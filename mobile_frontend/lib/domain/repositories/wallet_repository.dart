// Contract for reading the signed-in captain's wallet and statistics.

import 'package:mobile_frontend/domain/entities/wallet.dart';

/// Reads the captain's wallet from the SHAHM backend, which alone owns the
/// balance and the complete, immutable ledger (D-A25, D-A28, D-A74).
/// Read-only: there is no recharge, payment or ledger write here.
///
/// **API contract: TO SPECIFY.** Endpoint paths, DTOs, error codes and
/// pagination do not exist yet; nothing here invents them.
abstract interface class WalletRepository {
  /// The balance plus the commission debits recorded at or after
  /// [historySinceUtc] (the screen's display window; the server keeps the
  /// full ledger). The server is expected to apply the window; the caller
  /// applies the same window again, which changes nothing for conforming
  /// answers.
  ///
  /// Throws a `WalletException` for "not configured", network or server
  /// failures.
  Future<WalletOverview> getWallet({required DateTime historySinceUtc});

  /// The captain's lifetime delivery statistics (D-A76), independent of the
  /// debit display window. Throws a `WalletException` like [getWallet].
  Future<CaptainDeliveryStatistics> getDeliveryStatistics();
}
