// Typed failures of the active-delivery commands (pickup, start, complete)
// and of the outcome lookup.

/// Base type for workflow command failures that the server (or the
/// transport) reports to the domain.
sealed class OrderWorkflowException implements Exception {
  const OrderWorkflowException();
}

/// No workflow backend is connected yet: nothing was sent.
final class OrderWorkflowNotConfiguredException extends OrderWorkflowException {
  const OrderWorkflowNotConfiguredException();
}

/// The device was known to be offline: the command was not sent.
final class OrderWorkflowNetworkUnavailableException
    extends OrderWorkflowException {
  const OrderWorkflowNetworkUnavailableException();
}

/// The request may have been sent but no usable answer came back (server
/// error, connection lost after sending). The outcome is unknown.
final class OrderWorkflowServiceUnavailableException
    extends OrderWorkflowException {
  const OrderWorkflowServiceUnavailableException();
}

/// The order is no longer in a state (or assignment) that allows this
/// command: already advanced, cancelled, reassigned or expired. The app
/// re-reads the authoritative order instead of guessing.
final class OrderStateConflictException extends OrderWorkflowException {
  const OrderStateConflictException();
}
