// Domain types for the captain's availability for new order offers.

/// The captain's availability as the **backend** reports it.
///
/// Only a server answer produces one of these values. An OS permission
/// grant, a toggle tap or a stored flag never does (D-A48, D-A57, D-A58).
enum CaptainAvailability { available, unavailable }

/// Device conditions the captain needs before the backend may make them
/// Available (D-A48, D-A57, D-A58). Checked again on every attempt.
enum AvailabilityRequirement {
  /// The device location service (GPS) is switched on.
  locationService,

  /// Precise (not approximate) foreground location permission.
  preciseLocation,

  /// Background ("always") location permission, so positions can be
  /// reported while the app is not on screen.
  backgroundLocation,

  /// Permission to show notifications. Not the same as a working push
  /// token or guaranteed delivery: those belong to the future FCM/APNs
  /// integration.
  notifications,
}

/// The state of one [AvailabilityRequirement], as a platform adapter reads
/// it. Adapters report only what the platform really exposes.
enum RequirementStatus {
  /// Allowed / switched on.
  granted,

  /// Never asked yet: the system prompt can be shown.
  notDetermined,

  /// Refused, but the system still lets the app ask again.
  denied,

  /// Refused for good: only the system settings can change it.
  permanentlyDenied,

  /// Blocked by device policy (e.g. parental controls); the captain may not
  /// be able to change it.
  restricted,

  /// The location service is switched off.
  serviceDisabled,

  /// iOS provisional (quiet) notifications: not enough for offer alerts.
  provisional,

  /// The platform cannot provide this requirement at all.
  unsupported,

  /// This app build cannot check it yet (no native configuration or no
  /// adapter). Never treated as granted.
  notConfigured;

  /// Whether the requirement is met.
  bool get isGranted => this == granted;

  /// Whether the system prompt can still be shown for it.
  bool get canRequestInApp => this == notDetermined || this == denied;

  /// Whether only the system settings can fix it.
  bool get needsSettings =>
      this == permanentlyDenied ||
      this == serviceDisabled ||
      this == provisional;

  /// Whether this build cannot handle it at all (nothing to ask for).
  bool get isUnavailableInApp => this == unsupported || this == notConfigured;
}

/// The statuses of all [AvailabilityRequirement]s from one check.
///
/// A requirement missing from [statuses] counts as [RequirementStatus]
/// `notConfigured` (it was not checked), never as granted.
class AvailabilityPrerequisites {
  const AvailabilityPrerequisites(this.statuses);

  /// Every requirement reported as [status].
  AvailabilityPrerequisites.all(RequirementStatus status)
    : statuses = {for (final r in AvailabilityRequirement.values) r: status};

  /// Status per requirement, as read from the platform.
  final Map<AvailabilityRequirement, RequirementStatus> statuses;

  /// The status of [requirement] (`notConfigured` when not checked).
  RequirementStatus status(AvailabilityRequirement requirement) =>
      statuses[requirement] ?? RequirementStatus.notConfigured;

  /// Requirements that are not granted, in declaration order.
  List<AvailabilityRequirement> get missing => [
    for (final r in AvailabilityRequirement.values)
      if (!status(r).isGranted) r,
  ];

  /// Whether every requirement is met.
  bool get allGranted => missing.isEmpty;

  /// Whether a missing requirement can be asked for with a system prompt.
  bool get anyRequestable => missing.any((r) => status(r).canRequestInApp);

  /// Whether a missing requirement can only be fixed in the settings.
  bool get anyNeedsSettings => missing.any((r) => status(r).needsSettings);

  /// Whether this build cannot check or request a missing requirement.
  bool get anyUnavailableInApp =>
      missing.any((r) => status(r).isUnavailableInApp);
}
