// Platform boundary for the device conditions availability requires.

import 'package:mobile_frontend/domain/entities/captain_availability.dart';

/// Checks and requests the location and notification conditions a captain
/// needs before becoming Available (D-A48, D-A57, D-A58).
///
/// Rules every implementation follows:
/// - [check] never shows a prompt.
/// - [requestMissing] is called only after an explicit user action, and
///   asks only for requirements still requestable, in the platform's
///   required order (Android: foreground precise location first and
///   background location as a separate later step on Android 11+; never
///   both together. iOS: When In Use before Always).
/// - [openSettings] is called only when the user taps the settings action.
/// - A permission grant is never availability: only the backend decides.
abstract interface class AvailabilityPermissionGateway {
  /// The current status of every requirement. No prompts.
  Future<AvailabilityPrerequisites> check();

  /// Shows the system prompts for the requestable missing requirements and
  /// returns the statuses afterwards.
  Future<AvailabilityPrerequisites> requestMissing();

  /// Opens this app's page in the system settings. Returns false when that
  /// is not possible.
  Future<bool> openSettings();
}
