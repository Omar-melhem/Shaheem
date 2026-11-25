// Use cases of the active-delivery workflow: confirm pickup, start
// delivery, complete delivery and reconcile an unknown outcome (D-A81).

import 'dart:async';
import 'dart:math';

import 'package:mobile_frontend/domain/entities/active_order.dart';
import 'package:mobile_frontend/domain/entities/order_workflow.dart';
import 'package:mobile_frontend/domain/errors/order_workflow_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/order_workflow_repository.dart';

/// Why the server refused a workflow command.
enum OrderCommandRejection {
  /// The order is no longer in a stage/assignment that allows the command.
  stateConflict,
}

/// Outcome of one workflow command. A timeout or a lost answer is
/// [OrderCommandUnconfirmed] — never success, never a rejection and never
/// "not sent" (R04, `GLOBAL_SERVICES.md` §3.4).
sealed class OrderCommandResult<T> {
  const OrderCommandResult();
}

/// The server confirmed the command and returned [value].
final class OrderCommandSucceeded<T> extends OrderCommandResult<T> {
  const OrderCommandSucceeded(this.value);

  final T value;
}

/// The server refused it.
final class OrderCommandRejected<T> extends OrderCommandResult<T> {
  const OrderCommandRejected(this.reason);

  final OrderCommandRejection reason;
}

/// No workflow backend is connected: nothing was sent.
final class OrderCommandNotConfigured<T> extends OrderCommandResult<T> {
  const OrderCommandNotConfigured();
}

/// Known offline: nothing was sent.
final class OrderCommandNoInternet<T> extends OrderCommandResult<T> {
  const OrderCommandNoInternet();
}

/// The outcome is unknown (timeout, lost answer, server error after
/// sending). Reconcile through the authoritative reads; retry only with
/// the same operation key.
final class OrderCommandUnconfirmed<T> extends OrderCommandResult<T> {
  const OrderCommandUnconfirmed();
}

Future<OrderCommandResult<T>> _command<T>(
  Future<T> Function() send,
  Duration timeout,
) async {
  try {
    return OrderCommandSucceeded(await send().timeout(timeout));
  } on OrderStateConflictException {
    return const OrderCommandRejected(OrderCommandRejection.stateConflict);
  } on OrderWorkflowNotConfiguredException {
    return const OrderCommandNotConfigured();
  } on OrderWorkflowNetworkUnavailableException {
    return const OrderCommandNoInternet();
  } on TimeoutException {
    // Command timeout (R04): the server may have applied it.
    return const OrderCommandUnconfirmed();
  } on Object {
    // Server error or anything unexpected after sending: unknown outcome.
    return const OrderCommandUnconfirmed();
  }
}

/// Creates stable operation keys for commands: 128 random bits as hex.
/// Injectable so tests can use deterministic keys.
typedef OperationKeyFactory = String Function();

/// The default [OperationKeyFactory] (cryptographically secure random).
String secureOperationKey() {
  final random = Random.secure();
  return List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

/// Confirms the pickup («تم الاستلام») without any verification code. The
/// order advances to `picked_up` only on the server's confirmation; a
/// timeout or lost answer is [OrderCommandUnconfirmed], never a pickup.
class ConfirmPickup {
  const ConfirmPickup(
    this._repository, {
    this.timeout = const Duration(seconds: 20),
  });

  final OrderWorkflowRepository _repository;
  final Duration timeout;

  Future<OrderCommandResult<ActiveOrder>> call(
    OrderCommandTarget target, {
    required String operationKey,
  }) => _command(
    () => _repository.confirmPickup(target, operationKey: operationKey),
    timeout,
  );
}

/// Starts the delivery after a confirmed pickup (separate action, D-A81).
class StartDelivery {
  const StartDelivery(
    this._repository, {
    this.timeout = const Duration(seconds: 20),
  });

  final OrderWorkflowRepository _repository;
  final Duration timeout;

  Future<OrderCommandResult<ActiveOrder>> call(
    OrderCommandTarget target, {
    required String operationKey,
  }) => _command(
    () => _repository.startDelivery(target, operationKey: operationKey),
    timeout,
  );
}

/// Completes the delivery. The server records the delivery and its one
/// commission debit in one transaction (D-A74); the app only sends the
/// command.
class CompleteDelivery {
  const CompleteDelivery(
    this._repository, {
    this.timeout = const Duration(seconds: 30),
  });

  final OrderWorkflowRepository _repository;
  final Duration timeout;

  Future<OrderCommandResult<DeliveryCompletionReceipt>> call(
    OrderCommandTarget target, {
    required String operationKey,
  }) => _command(
    () => _repository.completeDelivery(target, operationKey: operationKey),
    timeout,
  );
}

/// Outcome of [GetOrderOutcome].
sealed class OrderOutcomeResult {
  const OrderOutcomeResult();
}

final class OrderOutcomeLoaded extends OrderOutcomeResult {
  const OrderOutcomeLoaded(this.outcome);

  final OrderOutcome outcome;
}

final class OrderOutcomeNotConfigured extends OrderOutcomeResult {
  const OrderOutcomeNotConfigured();
}

final class OrderOutcomeNoInternet extends OrderOutcomeResult {
  const OrderOutcomeNoInternet();
}

/// Read failure or timeout: still unknown, retryable.
final class OrderOutcomeFailure extends OrderOutcomeResult {
  const OrderOutcomeFailure();
}

/// Asks the server what happened to an order whose command outcome is
/// unknown (a missing active order is not proof of delivery).
class GetOrderOutcome {
  const GetOrderOutcome(
    this._repository, {
    this.timeout = const Duration(seconds: 20),
  });

  final OrderWorkflowRepository _repository;
  final Duration timeout;

  Future<OrderOutcomeResult> call(String orderId) async {
    try {
      return OrderOutcomeLoaded(
        await _repository.getOrderOutcome(orderId).timeout(timeout),
      );
    } on OrderWorkflowNotConfiguredException {
      return const OrderOutcomeNotConfigured();
    } on OrderWorkflowNetworkUnavailableException {
      return const OrderOutcomeNoInternet();
    } on TimeoutException {
      return const OrderOutcomeFailure();
    } on Object {
      return const OrderOutcomeFailure();
    }
  }
}
