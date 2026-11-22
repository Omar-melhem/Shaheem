part of 'current_order_cubit.dart';

/// Why loading the active order failed.
enum CurrentOrderFailureKind { noInternet, serviceUnavailable, unexpected }

/// The workflow commands the Current Order page can send (D-A81).
enum OrderWorkflowAction { confirmPickup, startDelivery, completeDelivery }

/// Why the last command did not (knowingly) succeed. Each one has its own
/// message; none of them advances the stage.
enum OrderCommandError {
  /// Server: wrong PIN (attempts may remain).
  incorrectPin,

  /// Server: no PIN attempts left (Admin intervention).
  pinLocked,

  /// Server: the order changed; the authoritative order is being re-read.
  stateConflict,

  /// No workflow backend: nothing was sent.
  notConfigured,

  /// Offline: nothing was sent.
  noInternet,

  /// Outcome unknown (timeout / lost answer): reconcile before retrying.
  unconfirmed,

  /// The outcome lookup after [unconfirmed] failed: still unknown.
  checkFailed,

  /// The outcome lookup says the server has not resolved it yet.
  checkPending,
}

/// Feedback of the latest command for the shown order. While [sending] no
/// other command may start. Never holds the PIN.
@immutable
class OrderCommandFeedback {
  const OrderCommandFeedback.sending(this.action)
    : sending = true,
      error = null,
      remainingAttempts = null;

  const OrderCommandFeedback.failed(
    this.action,
    OrderCommandError this.error, {
    this.remainingAttempts,
  }) : sending = false;

  final OrderWorkflowAction action;
  final bool sending;
  final OrderCommandError? error;

  /// PIN attempts left, only when the server said so.
  final int? remainingAttempts;

  /// Whether the outcome is unknown and must be reconciled first.
  bool get needsReconciliation =>
      error == OrderCommandError.unconfirmed ||
      error == OrderCommandError.checkFailed ||
      error == OrderCommandError.checkPending;
}

/// What the Current Order destination shows.
///
/// No state overrides `toString`, so order, merchant and phone details
/// never reach logs or debugging output.
@immutable
sealed class CurrentOrderState {
  const CurrentOrderState();

  /// Whether the server reported an active order in the latest lookup.
  /// False while loading, after any failure and after the order ended.
  bool get hasActiveOrder => false;
}

/// Nothing has been looked up yet.
final class CurrentOrderInitial extends CurrentOrderState {
  const CurrentOrderInitial();
}

/// A first lookup is running (a re-read of a shown active order keeps
/// [CurrentOrderActive] on screen instead).
final class CurrentOrderLoading extends CurrentOrderState {
  const CurrentOrderLoading();
}

/// The server answered: no active order.
final class CurrentOrderEmpty extends CurrentOrderState {
  const CurrentOrderEmpty();
}

/// No orders backend is connected yet; nothing was checked.
final class CurrentOrderNotConfigured extends CurrentOrderState {
  const CurrentOrderNotConfigured();
}

/// The lookup failed. Not the same as "no active order".
final class CurrentOrderFailure extends CurrentOrderState {
  const CurrentOrderFailure(this.kind);

  final CurrentOrderFailureKind kind;
}

/// The server reported an active order.
///
/// Whether the order exists and whether its pickup point can be mapped are
/// two separate facts: [pickup] says which. The stage is always
/// `order.status` as the server reported it.
final class CurrentOrderActive extends CurrentOrderState {
  const CurrentOrderActive({
    required this.order,
    this.pickup,
    this.captainLocation,
    this.route,
    this.command,
  });

  final ActiveOrder order;

  /// The merchant's valid coordinates (the map's destination), or null.
  /// Never a default or guessed point.
  final GeoPoint? pickup;

  /// The captain's own position, read only on the pickup leg with a map:
  /// null while being read (or not needed), then the outcome.
  final CaptainLocationResult? captainLocation;

  /// The driving route to the merchant (pickup leg only): null while not
  /// read, then the routing source's outcome.
  final PickupRouteResult? route;

  /// The latest command's feedback for this order, if any.
  final OrderCommandFeedback? command;

  /// Whether a map may be shown for this order (pickup leg only).
  bool get canShowMap => pickup != null && order.leg == ActiveOrderLeg.pickup;

  /// Whether a command is being sent.
  bool get isSending => command?.sending ?? false;

  CurrentOrderActive copyWith({
    CaptainLocationResult? Function()? captainLocation,
    PickupRouteResult? Function()? route,
    OrderCommandFeedback? Function()? command,
  }) => CurrentOrderActive(
    order: order,
    pickup: pickup,
    captainLocation: captainLocation == null
        ? this.captainLocation
        : captainLocation(),
    route: route == null ? this.route : route(),
    command: command == null ? this.command : command(),
  );

  @override
  bool get hasActiveOrder => true;
}

/// The server confirmed the completion of the shown delivery (D-A81). The
/// commission debit is part of the same server transaction; the wallet and
/// history are re-read by their own owners.
final class CurrentOrderDelivered extends CurrentOrderState {
  const CurrentOrderDelivered(this.receipt);

  final DeliveryCompletionReceipt receipt;
}

/// How an order stopped being this captain's work, per the server.
enum CurrentOrderEndReason { cancelled, reassigned }

/// The outcome lookup reported that the order ended without delivery.
final class CurrentOrderEnded extends CurrentOrderState {
  const CurrentOrderEnded(this.reason);

  final CurrentOrderEndReason reason;
}
