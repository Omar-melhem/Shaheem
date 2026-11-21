// Temporary WalletRepository used until the wallet backend exists.

import 'package:mobile_frontend/domain/entities/wallet.dart';
import 'package:mobile_frontend/domain/errors/wallet_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/wallet_repository.dart';

/// TEMPORARY — there is no wallet or statistics backend or API contract yet
/// (TO SPECIFY).
///
/// Always reports "backend not configured". It never returns a balance or
/// a statistic (not even zero), never reports an empty history and makes
/// no network call.
class WalletRepositoryPlaceholder implements WalletRepository {
  const WalletRepositoryPlaceholder();

  @override
  Future<WalletOverview> getWallet({required DateTime historySinceUtc}) async {
    throw const WalletBackendNotConfiguredException();
  }

  @override
  Future<CaptainDeliveryStatistics> getDeliveryStatistics() async {
    throw const WalletBackendNotConfiguredException();
  }
}
