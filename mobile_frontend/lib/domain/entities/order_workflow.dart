// Domain types of the active-delivery workflow: command targets, completion
// receipts, outcomes and the completed-delivery history.

import 'package:mobile_frontend/domain/entities/active_order.dart';

/// Which order (and assignment) a command is for. Built from the last
/// authoritative read, never typed by the user.
class OrderCommandTarget {
  const OrderCommandTarget({required this.orderId, this.assignmentRef});

  final String orderId;
  final String? assignmentRef;
}

/// The server's confirmation that a delivery was completed: the order and,
/// when the contract supplies them, the authoritative time and a receipt
/// reference. The commission debit is a server effect of the same
/// transaction (D-A74); the app reads it through the wallet, never computes
/// it.
class DeliveryCompletionReceipt {
  const DeliveryCompletionReceipt({
    required this.orderId,
    this.deliveredAt,
    this.receiptRef,
  });

  final String orderId;
  final DateTime? deliveredAt;
  final String? receiptRef;
}

/// What the server says happened to an order whose last command outcome is
/// unknown. Used to reconcile an unconfirmed completion: a missing active
/// order alone never proves delivery.
sealed class OrderOutcome {
  const OrderOutcome();
}

/// The order is still active for this captain, in the given state.
final class OrderOutcomeActive extends OrderOutcome {
  const OrderOutcomeActive(this.order);

  final ActiveOrder order;
}

/// The order was delivered.
final class OrderOutcomeDelivered extends OrderOutcome {
  const OrderOutcomeDelivered(this.receipt);

  final DeliveryCompletionReceipt receipt;
}

/// The order was cancelled.
final class OrderOutcomeCancelled extends OrderOutcome {
  const OrderOutcomeCancelled();
}

/// The order was reassigned to another captain.
final class OrderOutcomeReassigned extends OrderOutcome {
  const OrderOutcomeReassigned();
}

/// The server has not resolved the operation yet.
final class OrderOutcomeUnresolved extends OrderOutcome {
  const OrderOutcomeUnresolved();
}

/// One completed delivery of this captain, as the server records it: the
/// **historical snapshot** of that order (D-A83), never today's customer or
/// merchant data and never a copy of the current active order. Read-only;
/// never created on the phone. No `toString` override.
class CompletedDelivery {
  const CompletedDelivery({
    required this.orderId,
    required this.deliveredAt,
    this.merchantName,
    this.deliveryAreaName,
    this.deliveryFeeFils,
    this.customerName,
    this.customerPhone,
    this.deliveryNotes,
  });

  final String orderId;

  /// Authoritative delivery time.
  final DateTime deliveredAt;

  final String? merchantName;
  final String? deliveryAreaName;

  /// Full delivery fee in integer fils, when the contract returns it.
  final int? deliveryFeeFils;

  /// Optional customer name recorded for this order (D-A83).
  final String? customerName;

  /// Optional customer phone recorded for this order (D-A83).
  final String? customerPhone;

  /// Optional delivery notes recorded for this order (D-A83).
  final String? deliveryNotes;
}

/// One page of completed deliveries, newest first as the server sorts them.
/// [nextCursor] is the server's opaque continuation token (null: no more).
class CompletedDeliveriesPage {
  const CompletedDeliveriesPage({required this.items, this.nextCursor});

  final List<CompletedDelivery> items;
  final String? nextCursor;
}
