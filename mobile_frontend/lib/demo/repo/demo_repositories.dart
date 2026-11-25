// SHAHM DEMO (Task 37) — the feature repositories of the demonstration.
// Each implements the app's real domain contract over DemoState, so the real
// use cases, Cubits and screens run unchanged.
// Removed by `bash tool/demo/remove_demo.sh --apply`.

import 'package:mobile_frontend/demo/demo_state.dart';
import 'package:mobile_frontend/domain/entities/active_order.dart';
import 'package:mobile_frontend/domain/entities/captain_account.dart';
import 'package:mobile_frontend/domain/entities/captain_availability.dart';
import 'package:mobile_frontend/domain/entities/declined_offer.dart';
import 'package:mobile_frontend/domain/entities/order_offer.dart';
import 'package:mobile_frontend/domain/entities/order_workflow.dart';
import 'package:mobile_frontend/domain/entities/wallet.dart';
import 'package:mobile_frontend/domain/errors/captain_account_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/active_order_repository.dart';
import 'package:mobile_frontend/domain/repositories/availability_permission_gateway.dart';
import 'package:mobile_frontend/domain/repositories/captain_account_repository.dart';
import 'package:mobile_frontend/domain/repositories/captain_availability_repository.dart';
import 'package:mobile_frontend/domain/repositories/order_history_repository.dart';
import 'package:mobile_frontend/domain/repositories/order_offer_repository.dart';
import 'package:mobile_frontend/domain/repositories/order_workflow_repository.dart';
import 'package:mobile_frontend/domain/repositories/wallet_repository.dart';

/// Offers: list, simulated accept and decline (see [DemoState.accept] and
/// [DemoState.decline] for the server-like rules).
class DemoOfferRepository implements OrderOfferRepository {
  const DemoOfferRepository(this._state);

  final DemoState _state;

  @override
  Future<List<CaptainOrderOffer>> getEligibleOffers() async =>
      _state.eligibleOffers();

  @override
  Future<void> acceptOffer(String offerId) async => _state.accept(offerId);

  @override
  Future<void> declineOffer(String offerId) async => _state.decline(offerId);
}

/// The active order the demo server reports (none at start).
class DemoActiveOrderRepository implements ActiveOrderRepository {
  const DemoActiveOrderRepository(this._state);

  final DemoState _state;

  @override
  Future<ActiveOrder?> getActiveOrder() async => _state.activeOrder;
}

/// Offers this demo captain declined.
class DemoOrderHistoryRepository implements OrderHistoryRepository {
  const DemoOrderHistoryRepository(this._state);

  final DemoState _state;

  @override
  Future<List<DeclinedOfferRecord>> getDeclinedOffers() async =>
      _state.declinedOffers;

  /// Every demo completion in one page (the demo has no paging).
  @override
  Future<CompletedDeliveriesPage> getCompletedDeliveries({
    String? cursor,
  }) async => CompletedDeliveriesPage(items: _state.completedDeliveries);
}

/// The workflow commands against the demo "server" (pickup, start,
/// complete, outcome). Production uses the real contract once it exists.
class DemoOrderWorkflowRepository implements OrderWorkflowRepository {
  const DemoOrderWorkflowRepository(this._state);

  final DemoState _state;

  @override
  Future<ActiveOrder> confirmPickup(
    OrderCommandTarget target, {
    required String operationKey,
  }) async => _state.confirmPickup(target);

  @override
  Future<ActiveOrder> startDelivery(
    OrderCommandTarget target, {
    required String operationKey,
  }) async => _state.startDelivery(target);

  @override
  Future<DeliveryCompletionReceipt> completeDelivery(
    OrderCommandTarget target, {
    required String operationKey,
  }) async => _state.completeDelivery(target, operationKey);

  @override
  Future<OrderOutcome> getOrderOutcome(String orderId) async =>
      _state.outcome(orderId);
}

/// The fictional, read-only wallet and lifetime statistics. Every debit is
/// returned; the real `GetWallet` applies the rolling 7-day window, so
/// older rows are hidden. Statistics are lifetime (D-A76).
class DemoWalletRepository implements WalletRepository {
  const DemoWalletRepository(this._state);

  final DemoState _state;

  @override
  Future<WalletOverview> getWallet({required DateTime historySinceUtc}) async =>
      _state.wallet;

  @override
  Future<CaptainDeliveryStatistics> getDeliveryStatistics() async =>
      _state.deliveryStatistics;
}

/// Availability kept in demo memory only; never a server claim.
class DemoAvailabilityRepository implements CaptainAvailabilityRepository {
  const DemoAvailabilityRepository(this._state);

  final DemoState _state;

  @override
  Future<CaptainAvailability> getAvailability() async => _state.availability;

  @override
  Future<CaptainAvailability> setAvailability(
    CaptainAvailability requested,
  ) async {
    _state.availability = requested;
    return requested;
  }
}

/// Reports the device requirements as met **without asking the platform**:
/// no permission prompt, no GPS. Only for the demo, where the availability
/// switch is simulated.
class DemoPermissionGateway implements AvailabilityPermissionGateway {
  const DemoPermissionGateway();

  static final _granted = AvailabilityPrerequisites.all(
    RequirementStatus.granted,
  );

  @override
  Future<AvailabilityPrerequisites> check() async => _granted;

  @override
  Future<AvailabilityPrerequisites> requestMissing() async => _granted;

  @override
  Future<bool> openSettings() async => false;
}

/// The demo captain's rating from `captain.json` (fictional, 5-star
/// scale). It returns the fixture values unchanged: validation is the real
/// `GetCaptainRating`'s job, so an invalid fixture shows "unavailable".
///
/// Account deletion is **not** simulated: it reports "not configured"
/// exactly like production, so the demo never pretends an account was
/// deleted or a request was sent.
class DemoCaptainAccountRepository implements CaptainAccountRepository {
  const DemoCaptainAccountRepository(this._state);

  final DemoState _state;

  @override
  Future<CaptainRating> getRating() async => CaptainRating(
    ratingsCount: _state.fixtures.ratingsCount,
    average: _state.fixtures.ratingAverage,
  );

  @override
  Future<AccountDeletionStatus> requestAccountDeletion() async {
    throw const CaptainAccountBackendNotConfiguredException();
  }
}
