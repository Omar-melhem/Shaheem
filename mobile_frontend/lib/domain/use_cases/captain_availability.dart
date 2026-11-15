// Use cases: read and change the captain's availability on the backend.

import 'dart:async';

import 'package:mobile_frontend/domain/entities/captain_availability.dart';
import 'package:mobile_frontend/domain/errors/availability_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/captain_availability_repository.dart';

/// Outcome of reading or changing availability.
sealed class AvailabilityResult {
  const AvailabilityResult();
}

/// The server confirmed [availability].
final class AvailabilityConfirmed extends AvailabilityResult {
  const AvailabilityConfirmed(this.availability);

  final CaptainAvailability availability;
}

/// No availability backend is connected; nothing was checked or changed.
final class AvailabilityNotConfigured extends AvailabilityResult {
  const AvailabilityNotConfigured();
}

/// The server refused the change; the status did not change.
final class AvailabilityRejected extends AvailabilityResult {
  const AvailabilityRejected();
}

/// The device is offline. For a change, the outcome is unknown.
final class AvailabilityNoInternet extends AvailabilityResult {
  const AvailabilityNoInternet();
}

/// The server failed, timed out or answered unexpectedly. For a change,
/// the outcome is unknown.
final class AvailabilityServiceUnavailable extends AvailabilityResult {
  const AvailabilityServiceUnavailable();
}

/// Maps repository failures to [AvailabilityResult]s.
Future<AvailabilityResult> _guard(
  Future<CaptainAvailability> Function() request,
  Duration timeout,
) async {
  try {
    return AvailabilityConfirmed(await request().timeout(timeout));
  } on AvailabilityBackendNotConfiguredException {
    return const AvailabilityNotConfigured();
  } on AvailabilityRejectedException {
    return const AvailabilityRejected();
  } on AvailabilityNetworkUnavailableException {
    return const AvailabilityNoInternet();
  } on AvailabilityServiceUnavailableException {
    return const AvailabilityServiceUnavailable();
  } on TimeoutException {
    return const AvailabilityServiceUnavailable();
  } on Object {
    // Anything else is an unknown outcome, never a success.
    return const AvailabilityServiceUnavailable();
  }
}

/// Reads the captain's current availability from the server.
class GetCaptainAvailability {
  const GetCaptainAvailability(
    this._repository, {
    this.timeout = const Duration(seconds: 20),
  });

  final CaptainAvailabilityRepository _repository;

  /// Safety net if the server never answers.
  final Duration timeout;

  Future<AvailabilityResult> call() =>
      _guard(_repository.getAvailability, timeout);
}

/// Asks the server to change the captain's availability. The result is
/// what the server confirmed, never the requested value by assumption.
class ChangeCaptainAvailability {
  const ChangeCaptainAvailability(
    this._repository, {
    this.timeout = const Duration(seconds: 20),
  });

  final CaptainAvailabilityRepository _repository;

  /// Safety net if the server never answers (the outcome is then unknown).
  final Duration timeout;

  Future<AvailabilityResult> call(CaptainAvailability requested) =>
      _guard(() => _repository.setAvailability(requested), timeout);
}
