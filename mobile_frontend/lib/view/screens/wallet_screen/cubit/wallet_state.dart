part of 'wallet_cubit.dart';

/// What the Wallet screen can show for one read (the wallet, or the
/// statistics).
enum WalletStatus {
  /// Not loaded yet.
  initial,

  /// Loading from the server.
  loading,

  /// No signed-in captain (e.g. the debug preview): nothing is loaded.
  noSession,

  /// No backend is connected; nothing was checked.
  notConfigured,

  /// Offline while loading.
  noInternet,

  /// The server failed while loading.
  failure,

  /// The server answered.
  loaded,
}

/// Wallet read-model state (D-A76), shared by Home and Wallet (R02). Two independent reads:
/// - [status] / [overview]: the single balance and the commission debits;
/// - [statisticsStatus] / [statistics]: the lifetime delivery statistics.
///
/// A statistics failure never clears the balance, and vice versa. Each
/// value is the server's last answer, kept only while re-loading and
/// cleared by a failure of its own read.
class WalletState {
  const WalletState({
    this.status = WalletStatus.initial,
    this.overview,
    this.statisticsStatus = WalletStatus.initial,
    this.statistics,
  });

  final WalletStatus status;
  final WalletOverview? overview;

  final WalletStatus statisticsStatus;
  final CaptainDeliveryStatistics? statistics;

  /// The authoritative single balance in fils, or null while unknown (not
  /// read, not configured, offline or failed). Never derived from the debit
  /// list and never a substitute zero. Home's chip and Wallet both use it.
  int? get balanceFils => overview?.summary.balanceFils;

  /// Whether a Retry makes sense for the wallet read.
  bool get canRetry =>
      status == WalletStatus.noInternet || status == WalletStatus.failure;

  /// Whether a Retry makes sense for the statistics read.
  bool get canRetryStatistics =>
      statisticsStatus == WalletStatus.noInternet ||
      statisticsStatus == WalletStatus.failure;

  WalletState _copyWith({
    WalletStatus? status,
    WalletOverview? Function()? overview,
    WalletStatus? statisticsStatus,
    CaptainDeliveryStatistics? Function()? statistics,
  }) => WalletState(
    status: status ?? this.status,
    overview: overview == null ? this.overview : overview(),
    statisticsStatus: statisticsStatus ?? this.statisticsStatus,
    statistics: statistics == null ? this.statistics : statistics(),
  );
}
