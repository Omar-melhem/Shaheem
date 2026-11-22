// State management for the My Orders «الطلبات المكتملة» section (D-A81).

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/domain/entities/order_workflow.dart';
import 'package:mobile_frontend/domain/use_cases/get_completed_deliveries.dart';

part 'completed_deliveries_state.dart';

/// Loads the deliveries this captain completed, as the server records
/// them, page by page through the server's opaque cursor.
///
/// Read-only: a completion never inserts a row here; after a confirmed
/// completion the shell calls [refresh] and the new delivery appears once
/// the server returns it. Scoped to the main shell like
/// `DeclinedOffersCubit` (closed on sign-out), and it reads nothing until
/// My Orders first opens. Late answers (newer load, sign-out, close) are
/// dropped.
class CompletedDeliveriesCubit extends Cubit<CompletedDeliveriesState> {
  CompletedDeliveriesCubit(this._getCompleted, this._hasSession)
    : super(const CompletedDeliveriesState());

  final GetCompletedDeliveries _getCompleted;

  /// Whether a real captain session exists right now.
  final bool Function() _hasSession;

  int _generation = 0;

  /// Set when [refresh] arrives during a load: one more first-page read
  /// follows it.
  bool _staleWhileLoading = false;

  /// Reads the first page again (first entry, tab return, resume, Retry,
  /// refresh). Ignored while a read is running. The shown rows stay
  /// visible while re-reading.
  Future<void> load() async {
    if (state.isBusy) return;
    if (!_requireSession()) return;
    final generation = ++_generation;
    _staleWhileLoading = false;
    emit(state._copyWith(status: CompletedDeliveriesStatus.loading));

    final result = await _getCompleted();
    if (isClosed || generation != _generation) return;
    if (!_requireSession()) return;
    emit(switch (result) {
      CompletedDeliveriesLoaded(:final page) => CompletedDeliveriesState(
        status: CompletedDeliveriesStatus.loaded,
        items: page.items,
        nextCursor: page.nextCursor,
      ),
      CompletedDeliveriesNotConfigured() => const CompletedDeliveriesState(
        status: CompletedDeliveriesStatus.notConfigured,
      ),
      CompletedDeliveriesNoInternet() => const CompletedDeliveriesState(
        status: CompletedDeliveriesStatus.noInternet,
      ),
      CompletedDeliveriesFailure() => const CompletedDeliveriesState(
        status: CompletedDeliveriesStatus.failure,
      ),
    });
    if (_staleWhileLoading) {
      _staleWhileLoading = false;
      await load();
    }
  }

  /// Appends the next page («عرض المزيد»). A failure keeps the rows already
  /// shown and only marks the "more" read as failed.
  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (cursor == null ||
        state.isBusy ||
        state.status != CompletedDeliveriesStatus.loaded) {
      return;
    }
    if (!_requireSession()) return;
    final generation = ++_generation;
    emit(state._copyWith(loadingMore: true, moreFailed: false));

    final result = await _getCompleted(cursor: cursor);
    if (isClosed || generation != _generation) return;
    if (!_requireSession()) return;
    emit(switch (result) {
      CompletedDeliveriesLoaded(:final page) => CompletedDeliveriesState(
        status: CompletedDeliveriesStatus.loaded,
        items: [...state.items, ...page.items],
        nextCursor: page.nextCursor,
      ),
      _ => state._copyWith(loadingMore: false, moreFailed: true),
    });
  }

  /// The server's completed deliveries changed (a confirmed completion):
  /// re-read the first page. Before the first entry nothing is read; during
  /// a read one follow-up read is coalesced.
  Future<void> refresh() async {
    if (state.status == CompletedDeliveriesStatus.initial) return;
    if (state.isBusy) {
      _staleWhileLoading = true;
      return;
    }
    await load();
  }

  bool _requireSession() {
    if (_hasSession()) return true;
    _generation++;
    _staleWhileLoading = false;
    emit(
      const CompletedDeliveriesState(
        status: CompletedDeliveriesStatus.noSession,
      ),
    );
    return false;
  }
}
