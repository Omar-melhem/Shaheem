// Contract for the captain's authoritative availability on the backend.

import 'package:mobile_frontend/domain/entities/captain_availability.dart';

/// Reads and changes the signed-in captain's availability for new order
/// offers on the SHAHM backend, which is the only source of truth.
///
/// Implementations must not cache an answer as truth, store an optimistic
/// flag, or return a status the server did not send.
///
/// **API contract: TO SPECIFY** (D-A54). The endpoint paths, DTOs, Problem
/// Details codes and response shapes do not exist yet. A change is a
/// business command (D-A54): the HTTP implementation must send a stable
/// `Idempotency-Key` for one user attempt and reuse it when retrying that
/// same attempt (D-A56). How the key is generated and carried is also TO
/// SPECIFY; this interface does not invent it.
abstract interface class CaptainAvailabilityRepository {
  /// The current status on the server.
  ///
  /// Throws an `AvailabilityException` for "not configured", network or
  /// server failures.
  Future<CaptainAvailability> getAvailability();

  /// Asks the server to set the status to [requested] and returns the
  /// status the server confirmed (which may differ from [requested]).
  ///
  /// Throws `AvailabilityRejectedException` when the server refuses, and
  /// other `AvailabilityException`s when the outcome is unknown.
  Future<CaptainAvailability> setAvailability(CaptainAvailability requested);
}
