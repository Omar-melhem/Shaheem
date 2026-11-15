// Temporary AvailabilityPermissionGateway used until the native permission
// configuration is approved.

import 'package:mobile_frontend/domain/entities/captain_availability.dart';
import 'package:mobile_frontend/domain/repositories/availability_permission_gateway.dart';

/// TEMPORARY — `location` and `permission_handler` are approved (D-A57) but
/// the native permission setup is incomplete: the app's Android manifest
/// declares nothing itself (the `location` plugin merges only fine/coarse
/// location and its foreground service), there is no
/// `ACCESS_BACKGROUND_LOCATION` or `POST_NOTIFICATIONS`, iOS `Info.plist`
/// has no `NSLocation…UsageDescription` keys, and the Podfile has no
/// `permission_handler` macros. Calling the plugins now would report
/// misleading denials for background location and notifications, and fail
/// on iOS.
///
/// Reports every requirement as `notConfigured`, shows no prompt and opens
/// nothing. Replace it with a plugin-backed adapter once the native
/// configuration and the permission copy are approved.
class AvailabilityPermissionGatewayPlaceholder
    implements AvailabilityPermissionGateway {
  const AvailabilityPermissionGatewayPlaceholder();

  static final _notConfigured = AvailabilityPrerequisites.all(
    RequirementStatus.notConfigured,
  );

  @override
  Future<AvailabilityPrerequisites> check() async => _notConfigured;

  @override
  Future<AvailabilityPrerequisites> requestMissing() async => _notConfigured;

  @override
  Future<bool> openSettings() async => false;
}
