// Use cases: load the captain's actionable offers and accept or decline one.

import 'dart:async';

import 'package:mobile_frontend/domain/entities/order_offer.dart';
import 'package:mobile_frontend/domain/errors/order_offer_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/order_offer_repository.dart';

/// Outcome of [GetEligibleOffers].
sealed class EligibleOffersResult {
  const EligibleOffersResult();
}

/// The server answered; [offers] may be empty (confirmed: none).
final class EligibleOffersLoaded extends EligibleOffersResult {
  const EligibleOffersLoaded(this.offers);

  final List<CaptainOrderOffer> offers;
}

/// No offers backend is connected; nothing was checked.
final class EligibleOffersNotConfigured extends EligibleOffersResult {
  const EligibleOffersNotConfigured();
}

/// The device is offline.
final class EligibleOffersNoInternet extends EligibleOffersResult {
  const EligibleOffersNoInternet();
}

/// The server failed, timed out or answered unexpectedly.
final class EligibleOffersFailure extends EligibleOffersResult {
  const EligibleOffersFailure();
}

/// Outcome of [AcceptOrderOffer] and [DeclineOrderOffer].
sealed class OfferCommandResult {
  const OfferCommandResult();
}

/// The server confirmed the command.
final class OfferCommandConfirmed extends OfferCommandResult {
  const OfferCommandConfirmed();
}

/// The offer is no longer actionable for this captain.
final class OfferCommandNoLongerAvailable extends OfferCommandResult {
  const OfferCommandNoLongerAvailable();
}

/// The server refused the command; nothing changed.
final class OfferCommandRefused extends OfferCommandResult {
  const OfferCommandRefused();
}

/// No offers backend is connected; nothing was sent.
final class OfferCommandNotConfigured extends OfferCommandResult {
  const OfferCommandNotConfigured();
}

/// Offline, server failure or timeout: the outcome is unknown.
final class OfferCommandUnconfirmed extends OfferCommandResult {
  const OfferCommandUnconfirmed();
}

/// Loads the offers the server says this captain can act on now.
class GetEligibleOffers {
  const GetEligibleOffers(
    this._repository, {
    this.timeout = const Duration(seconds: 20),
  });

  final OrderOfferRepository _repository;

  /// Safety net if the server never answers.
  final Duration timeout;

  Future<EligibleOffersResult> call() async {
    try {
      final offers = await _repository.getEligibleOffers().timeout(timeout);
      return EligibleOffersLoaded(List.unmodifiable(offers));
    } on OrderOfferBackendNotConfiguredException {
      return const EligibleOffersNotConfigured();
    } on OrderOfferNetworkUnavailableException {
      return const EligibleOffersNoInternet();
    } on TimeoutException {
      // Read timeout (R04): retryable failure, never "offline" or "none".
      return const EligibleOffersFailure();
    } on Object {
      return const EligibleOffersFailure();
    }
  }
}

/// Maps a command's failures; anything unexpected is an unknown outcome,
/// never a success.
Future<OfferCommandResult> _command(
  Future<void> Function() send,
  Duration timeout,
) async {
  try {
    await send().timeout(timeout);
    return const OfferCommandConfirmed();
  } on OrderOfferBackendNotConfiguredException {
    return const OfferCommandNotConfigured();
  } on OrderOfferNoLongerAvailableException {
    return const OfferCommandNoLongerAvailable();
  } on OrderOfferRefusedException {
    return const OfferCommandRefused();
  } on TimeoutException {
    // Command timeout (R04): the server may have applied it. Unknown, so
    // neither success nor rejection; the authoritative offer/active-order
    // reads reconcile it.
    return const OfferCommandUnconfirmed();
  } on Object {
    return const OfferCommandUnconfirmed();
  }
}

/// Asks the server to assign an offer's order to this captain.
class AcceptOrderOffer {
  const AcceptOrderOffer(
    this._repository, {
    this.timeout = const Duration(seconds: 20),
  });

  final OrderOfferRepository _repository;

  /// Safety net if the server never answers (the outcome is then unknown).
  final Duration timeout;

  Future<OfferCommandResult> call(String offerId) =>
      _command(() => _repository.acceptOffer(offerId), timeout);
}

/// Declines an offer for this captain only.
class DeclineOrderOffer {
  const DeclineOrderOffer(
    this._repository, {
    this.timeout = const Duration(seconds: 20),
  });

  final OrderOfferRepository _repository;

  /// Safety net if the server never answers (the outcome is then unknown).
  final Duration timeout;

  Future<OfferCommandResult> call(String offerId) =>
      _command(() => _repository.declineOffer(offerId), timeout);
}
