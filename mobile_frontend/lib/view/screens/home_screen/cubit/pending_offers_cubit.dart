// State management for Home's "pending acceptance" offers section.

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/domain/entities/order_offer.dart';
import 'package:mobile_frontend/domain/use_cases/order_offers.dart';

part 'pending_offers_state.dart';

/// Loads the offers the server says this captain can still accept, and
/// sends accept/decline commands.
///
/// The server is the only authority: the list is replaced by each server
/// answer; nothing is filtered, expired or removed locally except after a
/// server-confirmed command. One command runs at a time. Results that
/// arrive after a newer operation, a sign-out ([hasSession] false) or
/// [close] are dropped.
///
/// Scoped to the Home route inside the main shell, so it is closed on
/// sign-out. It loads when Home opens, when Home is shown again after
/// another tab, on resume and on an explicit refresh: never by polling. It
/// asks for no device permission.
class PendingOffersCubit extends Cubit<PendingOffersState> {
  /// [onDeclineConfirmed] runs after the server confirmed a decline (the
  /// shell refreshes the declined-offers history, Task 38). It never
  /// navigates and never runs for a dismissed sheet or an unconfirmed/
  /// failed command. A confirmed acceptance is observed by
  /// `NewOfferSheetHost` from this Cubit's state (D-A73).
  PendingOffersCubit(
    this._getOffers,
    this._accept,
    this._decline,
    this._hasSession, {
    this.onDeclineConfirmed,
  }) : super(const PendingOffersState());

  final GetEligibleOffers _getOffers;
  final AcceptOrderOffer _accept;
  final DeclineOrderOffer _decline;

  /// Whether a real captain session exists right now.
  final bool Function() _hasSession;

  /// Runs after a server-confirmed decline (e.g. refresh Order History).
  final VoidCallback? onDeclineConfirmed;

  int _generation = 0;

  /// Loads the list from the server. Ignored while a load or a command is
  /// running (a command's answer is awaited first).
  Future<void> load() => _load(keepMessage: false);

  /// [keepMessage] keeps a just-confirmed result visible while the list is
  /// re-read after that command.
  Future<void> _load({required bool keepMessage}) async {
    if (state.status == PendingOffersStatus.loading || state.isCommandPending) {
      return;
    }
    if (!_requireSession()) return;
    final generation = ++_generation;
    emit(
      state._copyWith(
        status: PendingOffersStatus.loading,
        message: keepMessage ? null : () => null,
      ),
    );

    final result = await _getOffers();
    if (_isStale(generation)) return;
    emit(switch (result) {
      EligibleOffersLoaded(:final offers) => PendingOffersState(
        status: PendingOffersStatus.loaded,
        offers: offers,
        message: state.message,
      ),
      EligibleOffersNotConfigured() => const PendingOffersState(
        status: PendingOffersStatus.notConfigured,
      ),
      EligibleOffersNoInternet() => const PendingOffersState(
        status: PendingOffersStatus.noInternet,
      ),
      EligibleOffersFailure() => const PendingOffersState(
        status: PendingOffersStatus.failure,
      ),
    });
  }

  /// Accepts [offerId] for this captain (server-confirmed only).
  Future<void> accept(String offerId) => _run(offerId, OfferAction.accept);

  /// Declines [offerId] for this captain only (server-confirmed only).
  Future<void> decline(String offerId) => _run(offerId, OfferAction.decline);

  Future<void> _run(String offerId, OfferAction action) async {
    if (state.isCommandPending ||
        state.status != PendingOffersStatus.loaded ||
        (state.notices[offerId]?.blocksActions ?? false) ||
        !state.offers.any((o) => o.id == offerId)) {
      return;
    }
    if (!_requireSession()) return;
    final generation = ++_generation;
    emit(
      state._copyWith(
        pending: () => (offerId: offerId, action: action),
        notices: {...state.notices}..remove(offerId),
        message: () => null,
      ),
    );

    final result = switch (action) {
      OfferAction.accept => await _accept(offerId),
      OfferAction.decline => await _decline(offerId),
    };
    if (_isStale(generation)) return;

    if (result is OfferCommandConfirmed) {
      emit(
        PendingOffersState(
          status: PendingOffersStatus.loaded,
          offers: [
            for (final o in state.offers)
              if (o.id != offerId) o,
          ],
          notices: {...state.notices}..remove(offerId),
          message: action == OfferAction.accept
              ? PendingOffersMessage.accepted
              : PendingOffersMessage.declined,
        ),
      );
      if (action == OfferAction.decline) onDeclineConfirmed?.call();
      // Replace the local view with the server's current list.
      await _load(keepMessage: true);
      return;
    }
    final notice = switch (result) {
      OfferCommandNoLongerAvailable() => OfferCardNotice.noLongerAvailable,
      OfferCommandRefused() => OfferCardNotice.refused,
      OfferCommandNotConfigured() => OfferCardNotice.notConfigured,
      OfferCommandUnconfirmed() ||
      OfferCommandConfirmed() => OfferCardNotice.unconfirmed,
    };
    emit(
      state._copyWith(
        pending: () => null,
        notices: {...state.notices, offerId: notice},
      ),
    );
  }

  bool _requireSession() {
    if (_hasSession()) return true;
    _generation++;
    emit(const PendingOffersState(status: PendingOffersStatus.noSession));
    return false;
  }

  bool _isStale(int generation) {
    if (isClosed || generation != _generation) return true;
    if (!_hasSession()) {
      _requireSession();
      return true;
    }
    return false;
  }
}
