// State management for the wallet read models shared by Home and Wallet.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/domain/entities/wallet.dart';
import 'package:mobile_frontend/domain/use_cases/get_wallet.dart';

part 'wallet_state.dart';

/// The single owner of the captain's wallet read models (D-A71, D-A74,
/// D-A76): the balance with the last-7-days commission debits, and —
/// independently — the lifetime delivery statistics.
///
/// **Scope (R02, API-05):** one instance per authenticated main shell,
/// shared by the Home balance chip and the Wallet tab, so both always show
/// the same snapshot. A second balance owner (a Home-only Cubit or cache)
/// is not allowed: two owners can disagree after a debit. It closes with
/// the shell on sign-out.
///
/// **Load triggers** (each one explicit, no polling, no build-time loads):
/// - shell creation: [loadBalance] once (balance and debits only);
/// - Wallet first shown: [ensureLoaded] reads whatever is still unread
///   (usually only the statistics, so Home never causes a statistics read);
/// - Wallet re-shown after another tab, or its Retry: [load] (both reads);
/// - statistics Retry: [retryStatistics];
/// - session owner changed (account replacement): [syncSession].
/// A read requested while the same read runs is ignored (the running answer
/// is already the freshest one).
///
/// **Session safety:** [_sessionOwner] identifies the signed-in captain
/// (null when nobody is signed in). Data is tagged with the owner it was
/// read for; an answer that arrives for an older owner, after [close], or
/// after a newer read of the same kind is dropped, and an owner change
/// clears every value before anything else is shown.
///
/// Read-only: no recharge, payment or ledger command exists here. Values
/// are shown exactly as the server reports them; nothing is summed,
/// estimated or clamped (unknown stays unknown, zero stays zero, negative
/// and over-ceiling balances are shown as returned).
class WalletCubit extends Cubit<WalletState> {
  /// [hasSession] keeps the original contract for callers that only know
  /// whether a session exists; [sessionOwner], when given, also identifies
  /// the captain so an account switch drops the previous captain's data.
  WalletCubit(
    this._getWallet,
    this._getStatistics,
    bool Function() hasSession, {
    Object? Function()? sessionOwner,
  }) : _sessionOwner = sessionOwner ?? (() => hasSession() ? _anyOwner : null),
       super(const WalletState());

  /// Owner used when only "a session exists" is known.
  static const Object _anyOwner = Object();

  final GetWallet _getWallet;
  final GetDeliveryStatistics _getStatistics;

  /// The signed-in captain's identity right now, or null with no session.
  final Object? Function() _sessionOwner;

  /// The owner the current values belong to (null: none read yet).
  Object? _dataOwner;

  int _walletGeneration = 0;
  int _statisticsGeneration = 0;

  /// Reads the wallet and the statistics in parallel. Each read is ignored
  /// while it is already running. The last confirmed values stay visible
  /// while re-reading; a failure clears only its own values.
  Future<void> load() async {
    if (!_requireSession()) return;
    await Future.wait([_loadWallet(), _loadStatistics()]);
  }

  /// Reads only the balance and debits (the shell's creation trigger).
  Future<void> loadBalance() async {
    if (!_requireSession()) return;
    await _loadWallet();
  }

  /// Reads each of the two models that has not been read yet in this
  /// session (Wallet's first show). Nothing is read twice.
  Future<void> ensureLoaded() async {
    if (!_requireSession()) return;
    await Future.wait([
      if (state.status == WalletStatus.initial) _loadWallet(),
      if (state.statisticsStatus == WalletStatus.initial) _loadStatistics(),
    ]);
  }

  /// Retries only the statistics (their own Retry action).
  Future<void> retryStatistics() async {
    if (!_requireSession()) return;
    await _loadStatistics();
  }

  /// Applies a session change at once (called by the shell's session
  /// listener): when the owner differs from the one the values were read
  /// for, every value is cleared and, if someone is signed in, the balance
  /// is read again for the new owner. Same owner: nothing happens.
  Future<void> syncSession() async {
    if (isClosed) return;
    final owner = _sessionOwner();
    if (owner == _dataOwner) return;
    if (owner == null) {
      _requireSession();
      return;
    }
    _resetFor(owner);
    await _loadWallet();
  }

  Future<void> _loadWallet() async {
    if (state.status == WalletStatus.loading) return;
    final generation = ++_walletGeneration;
    final owner = _dataOwner;
    emit(state._copyWith(status: WalletStatus.loading));

    final result = await _getWallet();
    if (isClosed || generation != _walletGeneration) return;
    if (!_requireSession() || _dataOwner != owner) return;
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
    final owner = _dataOwner;
    emit(state._copyWith(statisticsStatus: WalletStatus.loading));

    final result = await _getStatistics();
    if (isClosed || generation != _statisticsGeneration) return;
    if (!_requireSession() || _dataOwner != owner) return;
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
  /// in, and returns false. When the signed-in owner differs from the one
  /// the values belong to, they are cleared first (account replacement).
  bool _requireSession() {
    final owner = _sessionOwner();
    if (owner != null) {
      if (owner != _dataOwner) _resetFor(owner);
      return true;
    }
    _dataOwner = null;
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

  /// Drops every value and running read, and tags the state with [owner].
  void _resetFor(Object owner) {
    _dataOwner = owner;
    _walletGeneration++;
    _statisticsGeneration++;
    emit(const WalletState());
  }
}
