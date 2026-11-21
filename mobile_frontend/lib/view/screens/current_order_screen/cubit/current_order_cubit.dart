// State management for the captain's authoritative active order.

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/domain/entities/active_order.dart';
import 'package:mobile_frontend/domain/use_cases/get_active_order.dart';
import 'package:mobile_frontend/domain/use_cases/get_captain_location.dart';

part 'current_order_state.dart';

/// The single owner of the captain's authoritative active order (D-A73).
///
/// It looks the active order up and, when it has usable restaurant
/// coordinates, the captain's own position for the pickup map.
///
/// Three outcomes that must never be confused have their own states: the
/// server says there is no active order ([CurrentOrderEmpty]); no orders
/// backend is connected, so nothing was checked
/// ([CurrentOrderNotConfigured], a permanent condition, not an outage); and
/// a real network or service failure ([CurrentOrderFailure], retryable).
/// Neither of the last two is ever treated as "no order".
///
/// **Scope:** one instance for the authenticated part of the app, created
/// by `MainApp` and provided above the router, because four places share
/// it: the startup redirect (`resolveRedirect` reads its state), the
/// standalone Current Order page, the offer flow (confirmed acceptance) and
/// foreground-return recovery. [reset] runs on sign-out, so no previous
/// captain's order survives a session change.
///
/// **Recovery reads** ([refreshed]) are coalesced: while a lookup runs, a
/// new request does not start a parallel one; it marks the running answer
/// as possibly stale and exactly one fresh follow-up lookup runs after it.
/// So an older "none" can never hide an assignment the captain accepted a
/// moment later. Every caller awaits the same settled answer.
///
/// It never creates, accepts or changes an order, never navigates, and
/// keeps no cache: every lookup asks the server again and replaces what
/// was shown (a confirmed absence replaces a previous active order).
class CurrentOrderCubit extends Cubit<CurrentOrderState> {
  CurrentOrderCubit(this._getActiveOrder, this._getCaptainLocation)
    : super(const CurrentOrderInitial());

  final GetActiveOrder _getActiveOrder;
  final GetCaptainLocation _getCaptainLocation;

  /// Identifies the latest lookup, so late answers to older work are
  /// dropped.
  int _generation = 0;

  /// Grows on every [reset], so work started for a previous session is
  /// dropped.
  int _session = 0;

  /// The lookup chain that is running, if any.
  Future<void>? _inFlight;

  /// Whether a request arrived while [_inFlight] was running, so one more
  /// lookup must follow it.
  bool _followUp = false;

  /// Looks up the active order (the screen's Retry and refresh actions).
  /// While a lookup is running this joins it instead of starting another,
  /// so repeated taps cannot start overlapping requests.
  Future<void> load() => _inFlight ?? _start();

  /// Asks the server again and completes with the settled answer, never
  /// with [CurrentOrderLoading]. A request made while a lookup runs causes
  /// one fresh follow-up lookup, whose answer is returned. Null when the
  /// Cubit was reset or closed meanwhile (sign-out).
  ///
  /// Used wherever a decision needs a fresh answer: startup after sign-in,
  /// foreground return and a confirmed instant acceptance (which opens
  /// Current Order only for the matching order).
  Future<CurrentOrderState?> refreshed() async {
    final session = _session;
    final running = _inFlight;
    if (running != null) {
      _followUp = true;
      await running;
    } else {
      await _start();
    }
    if (isClosed || session != _session) return null;
    return state;
  }

  /// Forgets the current answer and drops every lookup still running
  /// (sign-out or a session change). The next session starts from
  /// [CurrentOrderInitial].
  void reset() {
    if (isClosed) return;
    _session++;
    _generation++;
    _followUp = false;
    _inFlight = null;
    emit(const CurrentOrderInitial());
  }

  Future<void> _start() {
    final chain = _runChain();
    _inFlight = chain;
    return chain;
  }

  Future<void> _runChain() async {
    final session = _session;
    try {
      do {
        _followUp = false;
        await _lookup(session);
      } while (_followUp && !isClosed && session == _session);
    } finally {
      if (session == _session) _inFlight = null;
    }
  }

  Future<void> _lookup(int session) async {
    if (isClosed || session != _session) return;
    final generation = ++_generation;
    emit(const CurrentOrderLoading());

    final result = await _getActiveOrder();
    // A newer lookup, a reset (sign-out) or close: drop the answer.
    if (isClosed || generation != _generation) return;

    switch (result) {
      case ActiveOrderFound(:final order):
        // The order is active whether or not it can be mapped.
        final pickup = order.mappablePickup;
        emit(CurrentOrderActive(order: order, pickup: pickup));
        // The captain's position only matters once there is a map.
        if (pickup != null) await _locateCaptain(generation);
      case ActiveOrderNone():
        emit(const CurrentOrderEmpty());
      case ActiveOrderNotConfigured():
        emit(const CurrentOrderNotConfigured());
      case ActiveOrderNoInternet():
        emit(const CurrentOrderFailure(CurrentOrderFailureKind.noInternet));
      case ActiveOrderServiceUnavailable():
        emit(
          const CurrentOrderFailure(CurrentOrderFailureKind.serviceUnavailable),
        );
      case ActiveOrderFailure():
        emit(const CurrentOrderFailure(CurrentOrderFailureKind.unexpected));
    }
  }

  /// Reads the captain's position again after a failure, on the user's
  /// request only. Ignored while a read is running or when there is no map.
  Future<void> retryLocation() async {
    final current = state;
    if (current is! CurrentOrderActive ||
        !current.canShowMap ||
        current.captainLocation == null) {
      return;
    }
    emit(CurrentOrderActive(order: current.order, pickup: current.pickup));
    await _locateCaptain(_generation);
  }

  /// Location is requested here, only once an active order's map is shown,
  /// never at app start or just because the navigation bar exists.
  Future<void> _locateCaptain(int generation) async {
    final result = await _getCaptainLocation();
    final current = state;
    if (isClosed ||
        generation != _generation ||
        current is! CurrentOrderActive) {
      return;
    }
    emit(
      CurrentOrderActive(
        order: current.order,
        pickup: current.pickup,
        captainLocation: result,
      ),
    );
  }
}
