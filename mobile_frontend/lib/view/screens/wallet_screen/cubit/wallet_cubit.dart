// State management for the read-only Wallet screen.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/domain/entities/wallet.dart';
import 'package:mobile_frontend/domain/use_cases/get_wallet.dart';

part 'wallet_state.dart';

/// Loads the captain's single balance with the last-7-days commission
/// debits, and — independently — their lifetime delivery statistics
/// (D-A74, D-A76).
///
/// Read-only: no recharge, payment or ledger command exists here. Values
/// are shown exactly as the server reports them; nothing is summed,
/// estimated or clamped. Scoped to the Wallet route inside the main shell,
/// so it is closed on sign-out; answers that arrive after a newer load, a
/// sign-out ([hasSession] false) or [close] are dropped.
class WalletCubit extends Cubit<WalletState> {
  WalletCubit(this._getWallet, this._getStatistics, this._hasSession)
    : super(const WalletState());

  final GetWallet _getWallet;
  final GetDeliveryStatistics _getStatistics;

  /// Whether a real captain session exists right now.
  final bool Function() _hasSession;

  int _walletGeneration = 0;
  int _statisticsGeneration = 0;

  /// Reads the wallet and the statistics in parallel. Each read is ignored
  /// while it is already running. The last confirmed values stay visible
  /// while re-reading; a failure clears only its own values.
  Future<void> load() async {
    if (!_requireSession()) return;
    await Future.wait([_loadWallet(), _loadStatistics()]);
  }

  /// Retries only the statistics (their own Retry action).
  Future<void> retryStatistics() async {
    if (!_requireSession()) return;
    await _loadStatistics();
  }

  Future<void> _loadWallet() async {
    if (state.status == WalletStatus.loading) return;
    final generation = ++_walletGeneration;
    emit(state._copyWith(status: WalletStatus.loading));

    final result = await _getWallet();
    if (isClosed || generation != _walletGeneration) return;
    if (!_requireSession()) return;
    emit(switch (result) {
      WalletLoaded(:final overview) => state._copyWith(
        status: WalletStatus.loaded,
        overview: () => overview,
      ),
      WalletNotConfigured() => state._copyWith(
        status: WalletStatus.notConfigured,
        overview: () => null,
      ),
      WalletNoInternet() => state._copyWith(
        status: WalletStatus.noInternet,
        overview: () => null,
      ),
      WalletFailure() => state._copyWith(
        status: WalletStatus.failure,
        overview: () => null,
      ),
    });
  }

  Future<void> _loadStatistics() async {
    if (state.statisticsStatus == WalletStatus.loading) return;
    final generation = ++_statisticsGeneration;
    emit(state._copyWith(statisticsStatus: WalletStatus.loading));

    final result = await _getStatistics();
    if (isClosed || generation != _statisticsGeneration) return;
    if (!_requireSession()) return;
    emit(switch (result) {
      DeliveryStatisticsLoaded(:final statistics) => state._copyWith(
        statisticsStatus: WalletStatus.loaded,
        statistics: () => statistics,
      ),
      DeliveryStatisticsNotConfigured() => state._copyWith(
        statisticsStatus: WalletStatus.notConfigured,
        statistics: () => null,
      ),
      DeliveryStatisticsNoInternet() => state._copyWith(
        statisticsStatus: WalletStatus.noInternet,
        statistics: () => null,
      ),
      DeliveryStatisticsFailure() => state._copyWith(
        statisticsStatus: WalletStatus.failure,
        statistics: () => null,
      ),
    });
  }

  /// Emits the no-session state (clearing all data) when nobody is signed
  /// in, and returns false.
  bool _requireSession() {
    if (_hasSession()) return true;
    _walletGeneration++;
    _statisticsGeneration++;
    emit(
      const WalletState(
        status: WalletStatus.noSession,
        statisticsStatus: WalletStatus.noSession,
      ),
    );
    return false;
  }
}
