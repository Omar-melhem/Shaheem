// Temporary OrderWorkflowRepository used until the orders backend exists.

import 'package:mobile_frontend/domain/entities/active_order.dart';
import 'package:mobile_frontend/domain/entities/order_workflow.dart';
import 'package:mobile_frontend/domain/errors/order_workflow_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/order_workflow_repository.dart';

/// TEMPORARY — no workflow API contract exists yet (backend empty).
///
/// Every command reports "not configured": nothing is sent, no stage
/// advances and no delivery or debit is ever claimed.
class OrderWorkflowRepositoryPlaceholder implements OrderWorkflowRepository {
  const OrderWorkflowRepositoryPlaceholder();

  @override
  Future<ActiveOrder> confirmPickup(
    OrderCommandTarget target, {
    required String operationKey,
  }) async => throw const OrderWorkflowNotConfiguredException();

  @override
  Future<ActiveOrder> startDelivery(
    OrderCommandTarget target, {
    required String operationKey,
  }) async => throw const OrderWorkflowNotConfiguredException();

  @override
  Future<DeliveryCompletionReceipt> completeDelivery(
    OrderCommandTarget target, {
    required String operationKey,
  }) async => throw const OrderWorkflowNotConfiguredException();

  @override
  Future<OrderOutcome> getOrderOutcome(String orderId) async =>
      throw const OrderWorkflowNotConfiguredException();
}
