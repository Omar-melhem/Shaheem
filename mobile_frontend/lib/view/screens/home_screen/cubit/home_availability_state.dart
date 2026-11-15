part of 'home_availability_cubit.dart';

/// What the availability card is doing right now.
enum AvailabilityActivity {
  /// Nothing running; the toggle accepts intents.
  idle,

  /// Reading the status from the server.
  loading,

  /// Checking readiness and device requirements before enabling.
  checkingRequirements,

  /// The system permission prompts are open.
  requestingPermissions,

  /// The server is asked to make the captain Available.
  enabling,

  /// The server is asked to make the captain not Available.
  disabling,
}

/// Why the card shows an explanation instead of (or next to) the status.
@immutable
sealed class AvailabilityNotice {
  const AvailabilityNotice();
}

/// No availability backend is connected; nothing can be enabled.
final class AvailabilityNoticeNotConfigured extends AvailabilityNotice {
  const AvailabilityNoticeNotConfigured();
}

/// No signed-in captain (e.g. the debug preview).
final class AvailabilityNoticeNoSession extends AvailabilityNotice {
  const AvailabilityNoticeNoSession();
}

/// The status could not be read because the device is offline.
final class AvailabilityNoticeNoInternet extends AvailabilityNotice {
  const AvailabilityNoticeNoInternet();
}

/// The status could not be read because the server failed.
final class AvailabilityNoticeServiceUnavailable extends AvailabilityNotice {
  const AvailabilityNoticeServiceUnavailable();
}

/// The server refused to make the captain Available.
final class AvailabilityNoticeRejected extends AvailabilityNotice {
  const AvailabilityNoticeRejected();
}

/// This build cannot check or request the permissions yet.
final class AvailabilityNoticePermissionsNotConfigured
    extends AvailabilityNotice {
  const AvailabilityNoticePermissionsNotConfigured();
}

/// Requirements are missing, so the captain stays not Available.
final class AvailabilityNoticeMissingRequirements extends AvailabilityNotice {
  const AvailabilityNoticeMissingRequirements(
    this.missing, {
    required this.settingsRequired,
  });

  /// What is still missing, in a stable order.
  final List<AvailabilityRequirement> missing;

  /// Whether only the system settings can fix at least one of them.
  final bool settingsRequired;
}

/// Confirmed Available, but a requirement is no longer granted. The server
/// decides what that means (D-A48); the app does not switch off by itself.
final class AvailabilityNoticeRequirementsLost extends AvailabilityNotice {
  const AvailabilityNoticeRequirementsLost(this.missing);

  final List<AvailabilityRequirement> missing;
}

/// A change was sent but its outcome is unknown (offline, server failure,
/// timeout). [HomeAvailabilityState.confirmed] is the last confirmed status.
final class AvailabilityNoticeUnconfirmed extends AvailabilityNotice {
  const AvailabilityNoticeUnconfirmed();
}

/// What the Home availability card shows.
///
/// [confirmed] is the only source of the toggle's value, and only a server
/// answer sets it. No state overrides `toString`.
@immutable
class HomeAvailabilityState {
  const HomeAvailabilityState({
    this.confirmed,
    this.activity = AvailabilityActivity.idle,
    this.notice,
    this.pendingRationale,
  });

  /// The last status the server confirmed; null when none is known.
  final CaptainAvailability? confirmed;

  /// What is running.
  final AvailabilityActivity activity;

  /// The explanation to show, if any.
  final AvailabilityNotice? notice;

  /// Requirements the explanation is waiting for the captain to accept
  /// before the system prompts are shown; null when no explanation is open.
  final List<AvailabilityRequirement>? pendingRationale;

  /// Whether the server confirmed the captain is Available.
  bool get isAvailable => confirmed == CaptainAvailability.available;

  /// Whether work is running.
  bool get isBusy => activity != AvailabilityActivity.idle;

  /// Whether a change can be attempted at all (false when nothing could
  /// work: no backend or no session).
  bool get canChange =>
      notice is! AvailabilityNoticeNotConfigured &&
      notice is! AvailabilityNoticeNoSession;
}
