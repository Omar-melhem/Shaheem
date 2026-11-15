part of 'current_order_cubit.dart';

/// Why loading the active order failed.
enum CurrentOrderFailureKind { noInternet, serviceUnavailable, unexpected }

/// What the Current Order destination shows.
///
/// No state overrides `toString`, so order and restaurant details never
/// reach logs or debugging output.
@immutable
sealed class CurrentOrderState {
  const CurrentOrderState();

  /// Whether the server reported an active order in the latest lookup.
  /// False while loading and after any failure: the navigation bar must
  /// never show the active-order look on a guess.
  bool get hasActiveOrder => false;
}

/// Nothing has been looked up yet.
final class CurrentOrderInitial extends CurrentOrderState {
  const CurrentOrderInitial();
}

/// A lookup is running; further lookups are ignored until it ends.
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
/// two separate facts: this one state covers both cases, and [pickup] says
/// which. An order with missing restaurant coordinates is still fully an
/// active order; only its map is unavailable.
final class CurrentOrderActive extends CurrentOrderState {
  const CurrentOrderActive({
    required this.order,
    this.pickup,
    this.captainLocation,
  });

  final ActiveOrder order;

  /// The restaurant's well-formed coordinates (the map's destination), or
  /// null when the order has none usable. Never a default or guessed point.
  final GeoPoint? pickup;

  /// The captain's own position. Only read when [canShowMap]: null while it
  /// is being read (or not needed), then the outcome (found, permission
  /// denied, unavailable or not configured).
  final CaptainLocationResult? captainLocation;

  /// Whether a map may be shown for this order.
  bool get canShowMap => pickup != null;

  @override
  bool get hasActiveOrder => true;
}
