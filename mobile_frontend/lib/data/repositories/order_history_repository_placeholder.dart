// Temporary OrderHistoryRepository used until the history backend exists.

import 'package:mobile_frontend/domain/entities/declined_offer.dart';
import 'package:mobile_frontend/domain/errors/order_history_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/order_history_repository.dart';

/// TEMPORARY — there is no history backend or API contract yet.
///
/// Always reports "backend not configured": it never answers "no declined
/// offers" (a claim nobody checked) and never returns a record.
class OrderHistoryRepositoryPlaceholder implements OrderHistoryRepository {
  const OrderHistoryRepositoryPlaceholder();

  @override
  Future<List<DeclinedOfferRecord>> getDeclinedOffers() async {
    throw const OrderHistoryBackendNotConfiguredException();
  }
}
