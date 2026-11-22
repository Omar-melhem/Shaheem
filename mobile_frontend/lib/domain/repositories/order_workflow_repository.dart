// Contract for the captain's active-delivery commands (D-A67, D-A81).

import 'package:mobile_frontend/domain/entities/active_order.dart';
import 'package:mobile_frontend/domain/entities/order_workflow.dart';

/// Task-oriented commands on the captain's active order, plus the outcome
/// lookup that reconciles an unknown command result.
///
/// **API contract: TO SPECIFY** (`docs/quality/reports/2026-11-22-post-fix/
/// 03_SYSTEM_DATA_REQUIREMENTS.md`). The server derives the actor from the
/// session, validates assignment and stage, records the transition and —
/// for completion only — appends the one commission debit atomically. The
/// app never sends a target status, an amount or another captain.
///
/// Every command carries an [operationKey]: the same key for a retry of the
/// same attempt (so a lost response cannot create a second effect), a new
/// key for a new attempt. Implementations map failures to
/// `OrderWorkflowException` subtypes.
abstract interface class OrderWorkflowRepository {
  /// Submits the pickup [proof] for [target]. Returns the authoritative
  /// order after a confirmed pickup (status `picked_up`).
  Future<ActiveOrder> confirmPickup(
    OrderCommandTarget target,
    PickupProof proof, {
    required String operationKey,
  });

  /// Starts the delivery (`picked_up` → `on_the_way`). Returns the
  /// authoritative order after confirmation.
  Future<ActiveOrder> startDelivery(
    OrderCommandTarget target, {
    required String operationKey,
  });

  /// Completes the delivery. Returns the server's completion receipt.
  Future<DeliveryCompletionReceipt> completeDelivery(
    OrderCommandTarget target, {
    required String operationKey,
  });

  /// What happened to [orderId] (still active, delivered, cancelled,
  /// reassigned, or not resolved yet).
  Future<OrderOutcome> getOrderOutcome(String orderId);
}
