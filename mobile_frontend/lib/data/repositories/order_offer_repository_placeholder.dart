// Temporary OrderOfferRepository used until the offers backend exists.

import 'package:mobile_frontend/domain/entities/order_offer.dart';
import 'package:mobile_frontend/domain/errors/order_offer_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/order_offer_repository.dart';

/// TEMPORARY — there is no offers/dispatch backend or API contract yet
/// (D-A53, D-A54; the contract is TO SPECIFY).
///
/// Reports "backend not configured" for loading and for both commands. It
/// never answers "no offers" (a claim nobody checked), never returns an
/// offer and never confirms an acceptance or a decline.
class OrderOfferRepositoryPlaceholder implements OrderOfferRepository {
  const OrderOfferRepositoryPlaceholder();

  @override
  Future<List<CaptainOrderOffer>> getEligibleOffers() async {
    throw const OrderOfferBackendNotConfiguredException();
  }

  @override
  Future<void> acceptOffer(String offerId) async {
    throw const OrderOfferBackendNotConfiguredException();
  }

  @override
  Future<void> declineOffer(String offerId) async {
    throw const OrderOfferBackendNotConfiguredException();
  }
}
