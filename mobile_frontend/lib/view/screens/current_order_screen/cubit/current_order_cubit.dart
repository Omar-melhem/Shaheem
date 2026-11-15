// State management for the Current Order destination.

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/domain/entities/active_order.dart';
import 'package:mobile_frontend/domain/use_cases/get_active_order.dart';
import 'package:mobile_frontend/domain/use_cases/get_captain_location.dart';

part 'current_order_state.dart';

/// Looks up the captain's active order and, when it has usable restaurant
/// coordinates, the captain's own position for the pickup map.
///
/// Three outcomes that must never be confused have their own states: the
/// server says there is no active order ([CurrentOrderEmpty]); no orders
/// backend is connected, so nothing was checked
/// ([CurrentOrderNotConfigured], a permanent condition, not an outage); and
/// a real network or service failure ([CurrentOrderFailure], retryable).
///
/// Scoped to the main shell (created by the shell route, closed when the
/// shell leaves the tree on sign-out), because two places read it: the
/// Current Order screen and the navigation bar's active-order indicator.
/// It is the only holder of this state.
///
/// It never creates, accepts or changes an order, and keeps no cache:
/// every [load] asks the server again and replaces what was shown.
class CurrentOrderCubit extends Cubit<CurrentOrderState> {
  CurrentOrderCubit(this._getActiveOrder, this._getCaptainLocation)
    : super(const CurrentOrderInitial());

  final GetActiveOrder _getActiveOrder;
  final GetCaptainLocation _getCaptainLocation;

  /// Identifies the latest lookup, so late answers to older work are dropped.
  int _generation = 0;

  /// Looks up the active order. Ignored while a lookup is already running,
  /// so repeated taps cannot start overlapping requests.
  Future<void> load() async {
    if (state is CurrentOrderLoading) return;
    final generation = ++_generation;
    emit(const CurrentOrderLoading());

    final result = await _getActiveOrder();
    // Closed means the shell is gone (sign-out); drop the answer.
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
