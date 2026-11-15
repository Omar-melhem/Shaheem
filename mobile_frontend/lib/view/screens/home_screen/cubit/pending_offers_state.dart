part of 'pending_offers_cubit.dart';

/// What the "pending acceptance" section is showing.
enum PendingOffersStatus {
  /// Not loaded yet.
  initial,

  /// Loading from the server.
  loading,

  /// No signed-in captain (e.g. the debug preview): nothing is loaded.
  noSession,

  /// No offers backend is connected; nothing was checked.
  notConfigured,

  /// Offline while loading.
  noInternet,

  /// The server failed while loading.
  failure,

  /// The server answered (the list may be empty: confirmed none).
  loaded,
}

/// Which command is running for an offer.
enum OfferAction { accept, decline }

/// Why an offer card shows an explanation.
enum OfferCardNotice {
  /// The server says the offer is no longer actionable (expired, withdrawn,
  /// taken). Actions are off until the list is refreshed.
  noLongerAvailable,

  /// The server refused the command; the offer did not change.
  refused,

  /// No offers backend is connected; nothing was sent.
  notConfigured,

  /// The outcome is unknown (offline, failure, timeout). Actions are off
  /// until the list is refreshed, so nothing is sent twice by accident.
  unconfirmed;

  /// Whether the card's actions must stay off until a refresh.
  bool get blocksActions => this == noLongerAvailable || this == unconfirmed;
}

/// A confirmed result shown once above the list.
enum PendingOffersMessage { accepted, declined }

/// State of the Home "pending acceptance" section.
///
/// [offers] is always the last list the server returned; a card leaves it
/// only after a server-confirmed answer or a new server list. No state
/// overrides `toString`, so order details never reach logs.
@immutable
class PendingOffersState {
  const PendingOffersState({
    this.status = PendingOffersStatus.initial,
    this.offers = const [],
    this.pending,
    this.notices = const {},
    this.message,
  });

  final PendingOffersStatus status;

  /// The last list from the server (empty unless [status] is loaded, or a
  /// reload is running over it).
  final List<CaptainOrderOffer> offers;

  /// The command in flight, if any: offer id and action. Only one at a
  /// time, so a double tap or a second card cannot send another.
  final ({String offerId, OfferAction action})? pending;

  /// Per-offer explanations, by offer id.
  final Map<String, OfferCardNotice> notices;

  /// A confirmed result to announce, if any.
  final PendingOffersMessage? message;

  /// Whether a command is running.
  bool get isCommandPending => pending != null;

  PendingOffersState _copyWith({
    PendingOffersStatus? status,
    List<CaptainOrderOffer>? offers,
    ({String offerId, OfferAction action})? Function()? pending,
    Map<String, OfferCardNotice>? notices,
    PendingOffersMessage? Function()? message,
  }) => PendingOffersState(
    status: status ?? this.status,
    offers: offers ?? this.offers,
    pending: pending == null ? this.pending : pending(),
    notices: notices ?? this.notices,
    message: message == null ? this.message : message(),
  );
}
