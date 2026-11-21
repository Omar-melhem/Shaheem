// State management for the Order History «العروض المرفوضة» section.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/domain/entities/declined_offer.dart';
import 'package:mobile_frontend/domain/use_cases/get_declined_offers.dart';

part 'declined_offers_state.dart';

/// Loads the offers this captain declined, as the server records them.
///
/// Read-only: a decline elsewhere in the app never inserts a row here; the
/// section shows only what the server returns. Answers that arrive after a
/// newer load, a sign-out ([hasSession] false) or [close] are dropped.
///
/// Scoped to the main shell (Task 38; it was the Order History branch in
/// Task 36), like `CurrentOrderCubit`: a server-confirmed decline anywhere
/// in the shell (Home card or the new-offer sheet) calls [refresh] through
/// `PendingOffersCubit.onDeclineConfirmed`, so the list is current even
/// while Order History is the visible tab. It is still closed with the
/// shell on sign-out, and it reads nothing until Order History first
/// opens.
class DeclinedOffersCubit extends Cubit<DeclinedOffersState> {
  DeclinedOffersCubit(this._getDeclinedOffers, this._hasSession)
    : super(const DeclinedOffersState());

  final GetDeclinedOffers _getDeclinedOffers;

  /// Whether a real captain session exists right now.
  final bool Function() _hasSession;

  int _generation = 0;

  /// Set when [refresh] arrives during a load: the running answer may
  /// predate the change, so exactly one more read follows it.
  bool _staleWhileLoading = false;

  /// Reads the declined offers. Ignored while a load is running (the
  /// screen's own triggers: first entry, tab return, resume, Retry).
  Future<void> load() async {
    if (state.status == DeclinedOffersStatus.loading) return;
    if (!_requireSession()) return;
    final generation = ++_generation;
    _staleWhileLoading = false;
    emit(
      DeclinedOffersState(
        status: DeclinedOffersStatus.loading,
        records: state.records,
      ),
    );

    final result = await _getDeclinedOffers();
    if (isClosed || generation != _generation) return;
    if (!_requireSession()) return;
    emit(switch (result) {
      DeclinedOffersLoaded(:final records) => DeclinedOffersState(
        status: DeclinedOffersStatus.loaded,
        records: records,
      ),
      DeclinedOffersNotConfigured() => const DeclinedOffersState(
        status: DeclinedOffersStatus.notConfigured,
      ),
      DeclinedOffersNoInternet() => const DeclinedOffersState(
        status: DeclinedOffersStatus.noInternet,
      ),
      DeclinedOffersFailure() => const DeclinedOffersState(
        status: DeclinedOffersStatus.failure,
      ),
    });
    if (_staleWhileLoading) {
      // One follow-up read for every invalidation that arrived meanwhile.
      _staleWhileLoading = false;
      await load();
    }
  }

  /// The server's declined records changed (a confirmed decline, or a
  /// demo reset): re-read through the normal path.
  ///
  /// - Before Order History first opened ([DeclinedOffersStatus.initial])
  ///   nothing is read; the first entry loads the fresh list anyway.
  /// - During a load, the request is remembered and coalesced: however
  ///   many arrive, one read follows the running one.
  /// - Otherwise one read starts now. No row is added locally.
  Future<void> refresh() async {
    switch (state.status) {
      case DeclinedOffersStatus.initial:
        return;
      case DeclinedOffersStatus.loading:
        _staleWhileLoading = true;
        return;
      default:
        await load();
    }
  }

  /// Emits the no-session state (clearing any data) when nobody is signed
  /// in, and returns false.
  bool _requireSession() {
    if (_hasSession()) return true;
    _generation++;
    _staleWhileLoading = false;
    emit(const DeclinedOffersState(status: DeclinedOffersStatus.noSession));
    return false;
  }
}
