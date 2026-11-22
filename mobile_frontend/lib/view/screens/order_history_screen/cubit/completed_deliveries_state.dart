part of 'completed_deliveries_cubit.dart';

/// What the completed-deliveries section can show.
enum CompletedDeliveriesStatus {
  initial,
  loading,

  /// No signed-in captain (debug preview): nothing is read.
  noSession,

  /// No history backend; nothing was checked.
  notConfigured,
  noInternet,
  failure,

  /// The server answered (the list may be empty: confirmed none).
  loaded,
}

/// Completed-deliveries state: the server's rows so far, the next-page
/// cursor and the "more" read's own progress. No `toString` override, so
/// merchant names never reach logs.
class CompletedDeliveriesState {
  const CompletedDeliveriesState({
    this.status = CompletedDeliveriesStatus.initial,
    this.items = const [],
    this.nextCursor,
    this.loadingMore = false,
    this.moreFailed = false,
  });

  final CompletedDeliveriesStatus status;
  final List<CompletedDelivery> items;
  final String? nextCursor;
  final bool loadingMore;
  final bool moreFailed;

  /// Whether a read (first page or more) is running.
  bool get isBusy => status == CompletedDeliveriesStatus.loading || loadingMore;

  /// Whether a Retry of the first page makes sense.
  bool get canRetry =>
      status == CompletedDeliveriesStatus.noInternet ||
      status == CompletedDeliveriesStatus.failure;

  /// Whether «عرض المزيد» makes sense.
  bool get canLoadMore =>
      status == CompletedDeliveriesStatus.loaded && nextCursor != null;

  CompletedDeliveriesState _copyWith({
    CompletedDeliveriesStatus? status,
    bool? loadingMore,
    bool? moreFailed,
  }) => CompletedDeliveriesState(
    status: status ?? this.status,
    items: items,
    nextCursor: nextCursor,
    loadingMore: loadingMore ?? this.loadingMore,
    moreFailed: moreFailed ?? this.moreFailed,
  );
}
