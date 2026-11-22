// State management for the captain's authoritative active order and its
// pickup → delivery → completion workflow (D-A73, D-A81).

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/domain/entities/active_order.dart';
import 'package:mobile_frontend/domain/entities/order_workflow.dart';
import 'package:mobile_frontend/domain/use_cases/get_active_order.dart';
import 'package:mobile_frontend/domain/use_cases/get_captain_location.dart';
import 'package:mobile_frontend/domain/use_cases/get_pickup_route.dart';
import 'package:mobile_frontend/domain/use_cases/order_workflow.dart';
import 'package:mobile_frontend/util/validators/validators.dart';

part 'current_order_state.dart';

/// The single owner of the captain's authoritative active order (D-A73)
/// and of its stage commands (D-A81).
///
/// **Reads.** It looks the active order up and, on the pickup leg with
/// usable merchant coordinates, the captain's position and the driving
/// route for the pickup map. "No active order" ([CurrentOrderEmpty]), "no
/// backend" ([CurrentOrderNotConfigured]) and a real failure
/// ([CurrentOrderFailure]) are never confused. A re-read of an order that
/// is already shown keeps it on screen (no loading flash) and keeps the
/// last command feedback only while the order, assignment and stage are
/// unchanged; any change drops it.
///
/// **Commands** ([confirmPickup], [startDelivery], [completeDelivery]) are
/// offered only for the stage the server reported, one at a time. The
/// stage changes only from the server's confirmed answer — never from a
/// tap, a timeout, opening Maps or elapsed time. Each attempt carries an
/// operation key; after an **unconfirmed** outcome the same key is kept for
/// that action and the action stays blocked until [checkCommandStatus]
/// reconciles it with the server (a completion is reconciled through the
/// outcome lookup: a missing active order is not proof of delivery). An
/// answer for a previous order, assignment or session is dropped.
///
/// **Scope:** one instance for the authenticated app, created by `MainApp`
/// above the router (startup redirect, Current Order page, offer flow,
/// recovery, and the shell's history/wallet invalidation all read it).
/// [reset] runs on sign-out.
///
/// Recovery reads ([refreshed]) are coalesced: a request made while a
/// lookup runs causes exactly one fresh follow-up lookup.
class CurrentOrderCubit extends Cubit<CurrentOrderState> {
  CurrentOrderCubit(
    this._getActiveOrder,
    this._getCaptainLocation, {
    this._confirmPickup,
    this._startDelivery,
    this._completeDelivery,
    this._getOrderOutcome,
    this._getPickupRoute,
    this._operationKey = secureOperationKey,
  }) : super(const CurrentOrderInitial());

  final GetActiveOrder _getActiveOrder;
  final GetCaptainLocation _getCaptainLocation;

  // Null when not wired (tests of reads only): commands then report "not
  // configured" and send nothing.
  final ConfirmPickup? _confirmPickup;
  final StartDelivery? _startDelivery;
  final CompleteDelivery? _completeDelivery;
  final GetOrderOutcome? _getOrderOutcome;
  final GetPickupRoute? _getPickupRoute;
  final OperationKeyFactory _operationKey;

  /// Identifies the latest lookup, so late answers to older work are
  /// dropped.
  int _generation = 0;

  /// Grows on every [reset], so work started for a previous session is
  /// dropped.
  int _session = 0;

  /// The lookup chain that is running, if any.
  Future<void>? _inFlight;

  /// Whether a request arrived while [_inFlight] was running.
  bool _followUp = false;

  /// The key kept for retrying an unconfirmed start/complete of one order.
  ({OrderWorkflowAction action, String orderId, String key})? _retryKey;

  // ---------------------------------------------------------------- reads

  /// Looks up the active order (Retry and refresh actions). Joins a running
  /// lookup instead of starting another.
  Future<void> load() => _inFlight ?? _start();

  /// Asks the server again and completes with the settled answer, never
  /// with [CurrentOrderLoading]. Null when reset or closed meanwhile.
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

  /// Forgets the current answer and drops every lookup or command still
  /// running (sign-out or a session change).
  void reset() {
    if (isClosed) return;
    _session++;
    _generation++;
    _followUp = false;
    _inFlight = null;
    _retryKey = null;
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
    // A shown order stays on screen while it is re-read.
    if (state is! CurrentOrderActive) emit(const CurrentOrderLoading());

    final result = await _getActiveOrder();
    if (isClosed || generation != _generation) return;

    switch (result) {
      case ActiveOrderFound(:final order):
        _showOrder(order, generation);
        if (_shouldLocate(order)) await _locateCaptain(generation);
      case ActiveOrderNone():
        // While a command for the shown order is in flight, "no active
        // order" cannot tell delivered from cancelled or reassigned: the
        // command's own answer (or the outcome lookup) decides instead.
        final current = state;
        if (current is CurrentOrderActive && current.isSending) return;
        _retryKey = null;
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

  /// Shows [order] as the authoritative active order, keeping what is
  /// still valid from the previous state of the same order.
  void _showOrder(ActiveOrder order, int generation) {
    final previous = state;
    final same =
        previous is CurrentOrderActive &&
        previous.order.orderId == order.orderId &&
        previous.order.assignmentRef == order.assignmentRef;
    final sameStage = same && previous.order.status == order.status;
    final retry = _retryKey;
    if (retry != null && retry.orderId != order.orderId) _retryKey = null;
    final pickup = order.mappablePickup;
    final keepMap = sameStage && order.leg == ActiveOrderLeg.pickup;
    emit(
      CurrentOrderActive(
        order: order,
        pickup: pickup,
        captainLocation: keepMap ? previous.captainLocation : null,
        route: keepMap ? previous.route : null,
        command: sameStage ? previous.command : null,
      ),
    );
  }

  /// The captain's position (and route) only matter on the pickup leg with
  /// a mappable merchant.
  bool _shouldLocate(ActiveOrder order) =>
      order.leg == ActiveOrderLeg.pickup && order.mappablePickup != null;

  /// Reads the captain's position again after a failure, on the user's
  /// request only.
  Future<void> retryLocation() async {
    final current = state;
    if (current is! CurrentOrderActive ||
        !current.canShowMap ||
        current.captainLocation == null) {
      return;
    }
    emit(current.copyWith(captainLocation: () => null, route: () => null));
    await _locateCaptain(_generation);
  }

  /// Location is requested only once an active order's pickup map is shown,
  /// never at app start. A found position is followed by one route read.
  Future<void> _locateCaptain(int generation) async {
    final result = await _getCaptainLocation();
    final current = state;
    if (isClosed ||
        generation != _generation ||
        current is! CurrentOrderActive ||
        !current.canShowMap) {
      return;
    }
    emit(current.copyWith(captainLocation: () => result, route: () => null));
    if (result is! CaptainLocationFound) return;

    final getRoute = _getPickupRoute;
    final route = getRoute == null
        ? const PickupRouteNotConfigured()
        : await getRoute(origin: result.location, destination: current.pickup!);
    final latest = state;
    if (isClosed ||
        generation != _generation ||
        latest is! CurrentOrderActive ||
        latest.order.orderId != current.order.orderId ||
        !latest.canShowMap) {
      return;
    }
    emit(latest.copyWith(route: () => route));
  }

  // ------------------------------------------------------------- commands

  /// The shown order when [action] may start now: the server-reported
  /// [status] matches, no command is being sent, and this action is not
  /// waiting for reconciliation.
  CurrentOrderActive? _commandable(
    OrderWorkflowAction action,
    bool Function(ActiveOrderStatus status) allowed,
  ) {
    final current = state;
    if (current is! CurrentOrderActive || current.isSending) return null;
    if (!allowed(current.order.status)) return null;
    final command = current.command;
    if (command != null &&
        command.action == action &&
        (command.needsReconciliation ||
            command.error == OrderCommandError.pinLocked)) {
      return null;
    }
    return current;
  }

  /// The state to apply a command answer to, or null when the answer is
  /// stale (another session, another order or assignment, or closed).
  CurrentOrderActive? _stillShowing(int session, ActiveOrder order) {
    final current = state;
    if (isClosed ||
        session != _session ||
        current is! CurrentOrderActive ||
        current.order.orderId != order.orderId ||
        current.order.assignmentRef != order.assignmentRef) {
      return null;
    }
    return current;
  }

  OrderCommandTarget _target(ActiveOrder order) => OrderCommandTarget(
    orderId: order.orderId,
    assignmentRef: order.assignmentRef,
  );

  /// The key for a start/complete attempt: the kept key after an
  /// unconfirmed attempt of the same action and order, otherwise a new one.
  String _keyFor(OrderWorkflowAction action, String orderId) {
    final kept = _retryKey;
    if (kept != null && kept.action == action && kept.orderId == orderId) {
      return kept.key;
    }
    final key = _operationKey();
    _retryKey = (action: action, orderId: orderId, key: key);
    return key;
  }

  /// Submits the pickup PIN typed by the captain (D-A81). Only the syntax
  /// is checked here (four digits after normalization); a malformed value
  /// sends nothing. The PIN is not stored in any state.
  Future<void> confirmPickup(String rawPin) async {
    const action = OrderWorkflowAction.confirmPickup;
    final active = _commandable(action, (s) => s.leg == ActiveOrderLeg.pickup);
    if (active == null || Validators.pickupPin(rawPin) != null) return;
    final useCase = _confirmPickup;
    if (useCase == null) {
      emit(_failed(active, action, OrderCommandError.notConfigured));
      return;
    }
    final session = _session;
    emit(
      active.copyWith(
        command: () => const OrderCommandFeedback.sending(action),
      ),
    );
    // Every PIN submission is a new attempt with its own key: the server
    // counts attempts; a repeat of a successful one is a state conflict.
    final result = await useCase(
      _target(active.order),
      PickupPinProof(Validators.normalizePickupPin(rawPin)),
      operationKey: _operationKey(),
    );
    final current = _stillShowing(session, active.order);
    if (current == null) return;
    _applyStepResult(current, action, result);
  }

  /// Starts the delivery (separate action after confirmed pickup, D-A81).
  Future<void> startDelivery() => _sendStep(
    OrderWorkflowAction.startDelivery,
    ActiveOrderStatus.pickedUp,
    _startDelivery,
  );

  Future<void> _sendStep(
    OrderWorkflowAction action,
    ActiveOrderStatus requiredStatus,
    StartDelivery? useCase,
  ) async {
    final active = _commandable(action, (s) => s == requiredStatus);
    if (active == null) return;
    if (useCase == null) {
      emit(_failed(active, action, OrderCommandError.notConfigured));
      return;
    }
    final session = _session;
    final key = _keyFor(action, active.order.orderId);
    emit(active.copyWith(command: () => OrderCommandFeedback.sending(action)));
    final result = await useCase(_target(active.order), operationKey: key);
    final current = _stillShowing(session, active.order);
    if (current == null) return;
    _applyStepResult(current, action, result);
  }

  /// Applies a pickup/start answer.
  void _applyStepResult(
    CurrentOrderActive current,
    OrderWorkflowAction action,
    OrderCommandResult<ActiveOrder> result,
  ) {
    switch (result) {
      case OrderCommandSucceeded(:final value):
        _retryKey = null;
        _showConfirmed(value);
      case OrderCommandRejected(:final reason, :final remainingAttempts):
        _retryKey = null;
        emit(
          _failed(
            current,
            action,
            _rejection(reason),
            remainingAttempts: remainingAttempts,
          ),
        );
        if (reason == OrderCommandRejection.stateConflict) unawaited(load());
      case OrderCommandNotConfigured():
        _retryKey = null;
        emit(_failed(current, action, OrderCommandError.notConfigured));
      case OrderCommandNoInternet():
        emit(_failed(current, action, OrderCommandError.noInternet));
      case OrderCommandUnconfirmed():
        emit(_failed(current, action, OrderCommandError.unconfirmed));
    }
  }

  /// Shows the order the server returned after a confirmed command.
  void _showConfirmed(ActiveOrder order) {
    final generation = ++_generation; // older lookups are now stale
    emit(CurrentOrderActive(order: order, pickup: order.mappablePickup));
    if (_shouldLocate(order)) unawaited(_locateCaptain(generation));
  }

  /// Completes the delivery after a confirmed start (D-A81). On the
  /// server's confirmation the page moves to [CurrentOrderDelivered]; the
  /// one commission debit is the server's effect, read back by the wallet.
  Future<void> completeDelivery() async {
    const action = OrderWorkflowAction.completeDelivery;
    final active = _commandable(action, (s) => s == ActiveOrderStatus.onTheWay);
    if (active == null) return;
    final useCase = _completeDelivery;
    if (useCase == null) {
      emit(_failed(active, action, OrderCommandError.notConfigured));
      return;
    }
    final session = _session;
    final key = _keyFor(action, active.order.orderId);
    emit(
      active.copyWith(
        command: () => const OrderCommandFeedback.sending(action),
      ),
    );
    final result = await useCase(_target(active.order), operationKey: key);
    final current = _stillShowing(session, active.order);
    if (current == null) return;
    switch (result) {
      case OrderCommandSucceeded(:final value)
          when value.orderId == current.order.orderId:
        _retryKey = null;
        _generation++;
        emit(CurrentOrderDelivered(value));
      case OrderCommandSucceeded():
        // A receipt for another order proves nothing about this one.
        emit(_failed(current, action, OrderCommandError.unconfirmed));
      case OrderCommandRejected(:final reason):
        _retryKey = null;
        emit(_failed(current, action, _rejection(reason)));
        if (reason == OrderCommandRejection.stateConflict) unawaited(load());
      case OrderCommandNotConfigured():
        _retryKey = null;
        emit(_failed(current, action, OrderCommandError.notConfigured));
      case OrderCommandNoInternet():
        emit(_failed(current, action, OrderCommandError.noInternet));
      case OrderCommandUnconfirmed():
        emit(_failed(current, action, OrderCommandError.unconfirmed));
    }
  }

  /// Reconciles an unconfirmed command with the server («تحقّق من حالة
  /// الطلب»). Pickup/start: re-read the active order (the stage shows what
  /// happened). Completion: ask the outcome lookup. Nothing is resent.
  Future<void> checkCommandStatus() async {
    final active = state;
    if (active is! CurrentOrderActive) return;
    final command = active.command;
    if (command == null || !command.needsReconciliation) return;

    if (command.action != OrderWorkflowAction.completeDelivery) {
      final session = _session;
      await refreshed();
      final current = _stillShowing(session, active.order);
      // Same stage after a fresh read: the command did not apply; it may be
      // tried again (start keeps its key).
      if (current != null &&
          current.order.status == active.order.status &&
          (current.command?.needsReconciliation ?? false)) {
        emit(current.copyWith(command: () => null));
      }
      return;
    }

    final lookup = _getOrderOutcome;
    if (lookup == null) {
      emit(_failed(active, command.action, OrderCommandError.checkFailed));
      return;
    }
    final session = _session;
    emit(
      active.copyWith(
        command: () => OrderCommandFeedback.sending(command.action),
      ),
    );
    final result = await lookup(active.order.orderId);
    final current = _stillShowing(session, active.order);
    if (current == null) return;
    switch (result) {
      case OrderOutcomeLoaded(outcome: OrderOutcomeDelivered(:final receipt)):
        _retryKey = null;
        _generation++;
        emit(CurrentOrderDelivered(receipt));
      case OrderOutcomeLoaded(outcome: OrderOutcomeActive(:final order)):
        // Not delivered: the same key stays for a retry of the same attempt.
        _showConfirmed(order);
      case OrderOutcomeLoaded(outcome: OrderOutcomeCancelled()):
        _retryKey = null;
        _generation++;
        emit(const CurrentOrderEnded(CurrentOrderEndReason.cancelled));
      case OrderOutcomeLoaded(outcome: OrderOutcomeReassigned()):
        _retryKey = null;
        _generation++;
        emit(const CurrentOrderEnded(CurrentOrderEndReason.reassigned));
      case OrderOutcomeLoaded(outcome: OrderOutcomeUnresolved()):
        emit(_failed(current, command.action, OrderCommandError.checkPending));
      case OrderOutcomeNotConfigured() ||
          OrderOutcomeNoInternet() ||
          OrderOutcomeFailure():
        emit(_failed(current, command.action, OrderCommandError.checkFailed));
    }
  }

  /// Drops a finished command's message (the PIN form opening or closing),
  /// except one that still blocks: unknown outcomes and a locked PIN.
  void clearCommandFeedback() {
    final current = state;
    if (current is! CurrentOrderActive) return;
    final command = current.command;
    if (command == null ||
        command.sending ||
        command.needsReconciliation ||
        command.error == OrderCommandError.pinLocked) {
      return;
    }
    emit(current.copyWith(command: () => null));
  }

  CurrentOrderActive _failed(
    CurrentOrderActive state,
    OrderWorkflowAction action,
    OrderCommandError error, {
    int? remainingAttempts,
  }) => state.copyWith(
    command: () => OrderCommandFeedback.failed(
      action,
      error,
      remainingAttempts: remainingAttempts,
    ),
  );

  static OrderCommandError _rejection(OrderCommandRejection reason) =>
      switch (reason) {
        OrderCommandRejection.incorrectPin => OrderCommandError.incorrectPin,
        OrderCommandRejection.pinLocked => OrderCommandError.pinLocked,
        OrderCommandRejection.stateConflict => OrderCommandError.stateConflict,
      };
}
