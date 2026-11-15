// Test doubles for captain availability (backend and device permissions).
// Used only in tests; the app ships the honest "not configured" placeholders.

import 'dart:async';

import 'package:mobile_frontend/domain/entities/captain_availability.dart';
import 'package:mobile_frontend/domain/repositories/availability_permission_gateway.dart';
import 'package:mobile_frontend/domain/repositories/captain_availability_repository.dart';

/// Backend whose answers each test controls.
class FakeAvailabilityRepository implements CaptainAvailabilityRepository {
  FakeAvailabilityRepository({this.status = CaptainAvailability.unavailable});

  /// What the server currently reports (and what a confirmed change sets).
  CaptainAvailability status;

  /// When set, [getAvailability] throws this.
  Object? getError;

  /// When set, [setAvailability] throws this.
  Object? setError;

  /// When set, [getAvailability] waits on it.
  Completer<CaptainAvailability>? getPending;

  /// When set, [setAvailability] waits on it.
  Completer<CaptainAvailability>? setPending;

  /// What the server confirms for a request (default: the requested value).
  CaptainAvailability Function(CaptainAvailability requested)? confirm;

  int getCalls = 0;
  final setCalls = <CaptainAvailability>[];

  @override
  Future<CaptainAvailability> getAvailability() async {
    getCalls++;
    if (getPending != null) return getPending!.future;
    if (getError != null) throw getError!;
    return status;
  }

  @override
  Future<CaptainAvailability> setAvailability(
    CaptainAvailability requested,
  ) async {
    setCalls.add(requested);
    if (setPending != null) return setPending!.future;
    if (setError != null) throw setError!;
    status = confirm?.call(requested) ?? requested;
    return status;
  }
}

/// Device permissions whose statuses each test controls.
class FakePermissionGateway implements AvailabilityPermissionGateway {
  FakePermissionGateway(this.current, {this.afterRequest});

  /// What [check] reports.
  AvailabilityPrerequisites current;

  /// What the device reports after the prompts (null: unchanged).
  AvailabilityPrerequisites? afterRequest;

  int checkCalls = 0;
  int requestCalls = 0;
  int settingsCalls = 0;

  @override
  Future<AvailabilityPrerequisites> check() async {
    checkCalls++;
    return current;
  }

  @override
  Future<AvailabilityPrerequisites> requestMissing() async {
    requestCalls++;
    if (afterRequest != null) current = afterRequest!;
    return current;
  }

  @override
  Future<bool> openSettings() async {
    settingsCalls++;
    return true;
  }
}

/// All requirements [base], except the ones in [overrides].
AvailabilityPrerequisites prerequisites({
  RequirementStatus base = RequirementStatus.granted,
  Map<AvailabilityRequirement, RequirementStatus> overrides = const {},
}) => AvailabilityPrerequisites({
  for (final r in AvailabilityRequirement.values) r: overrides[r] ?? base,
});
