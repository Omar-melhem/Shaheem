// Temporary CaptainAvailabilityRepository used until the backend exists.

import 'package:mobile_frontend/domain/entities/captain_availability.dart';
import 'package:mobile_frontend/domain/errors/availability_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/captain_availability_repository.dart';

/// TEMPORARY — there is no availability backend or API contract yet
/// (D-A53, D-A54; the contract is TO SPECIFY).
///
/// Reports "backend not configured" for both reading and changing. It never
/// answers "unavailable" (a claim nobody checked) and never confirms
/// "available". Replace it with the API-backed implementation once the
/// contract is agreed.
class CaptainAvailabilityRepositoryPlaceholder
    implements CaptainAvailabilityRepository {
  const CaptainAvailabilityRepositoryPlaceholder();

  @override
  Future<CaptainAvailability> getAvailability() async {
    throw const AvailabilityBackendNotConfiguredException();
  }

  @override
  Future<CaptainAvailability> setAvailability(
    CaptainAvailability requested,
  ) async {
    throw const AvailabilityBackendNotConfiguredException();
  }
}
