part of 'declined_offers_cubit.dart';

/// What the declined-offers section can show.
enum DeclinedOffersStatus {
  /// Not loaded yet.
  initial,

  /// Loading from the server.
  loading,

  /// No signed-in captain (e.g. the debug preview): nothing is loaded.
  noSession,

  /// No history backend is connected; nothing was checked.
  notConfigured,

  /// Offline while loading.
  noInternet,

  /// The server failed while loading.
  failure,

  /// The server answered (the list may be empty: confirmed none).
  loaded,
}

/// Declined-offers state. [records] is the server's last answer; kept only
/// while re-loading, cleared by any failure. No `toString` override, so
/// merchant names never reach logs.
class DeclinedOffersState {
  const DeclinedOffersState({
    this.status = DeclinedOffersStatus.initial,
    this.records = const [],
  });

  final DeclinedOffersStatus status;
  final List<DeclinedOfferRecord> records;

  /// Whether a Retry makes sense for this state.
  bool get canRetry =>
      status == DeclinedOffersStatus.noInternet ||
      status == DeclinedOffersStatus.failure;
}
