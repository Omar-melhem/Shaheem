// Opens the native Google Maps app with driving directions to the merchant.

import 'package:flutter/foundation.dart';
import 'package:mobile_frontend/domain/entities/active_order.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

/// Result of [PickupNavigationLauncher.open].
enum PickupNavigationOutcome {
  /// The Google Maps app was asked to open (the OS accepted the launch).
  launched,

  /// The Google Maps app is not installed or cannot be opened. No other
  /// map app or the browser was chosen instead.
  appUnavailable,

  /// The merchant point is missing or invalid: nothing was launched.
  invalidDestination,

  /// The launch itself failed, or the platform is not supported.
  failed,
}

/// The platform side of an external-app launch (injectable for tests).
abstract interface class ExternalAppLauncher {
  Future<bool> canOpen(Uri uri);

  Future<bool> open(Uri uri);
}

/// [ExternalAppLauncher] over `url_launcher`, always as an external,
/// **non-browser** application, so a missing Maps app is never reported as
/// success by opening a web page.
class UrlLauncherExternalAppLauncher implements ExternalAppLauncher {
  const UrlLauncherExternalAppLauncher();

  @override
  Future<bool> canOpen(Uri uri) => url_launcher.canLaunchUrl(uri);

  @override
  Future<bool> open(Uri uri) => url_launcher.launchUrl(
    uri,
    mode: url_launcher.LaunchMode.externalNonBrowserApplication,
  );
}

/// Opens Google Maps navigation to the **merchant pickup only** (D-A62,
/// D-A81). Separate from the in-app legal-page launcher on purpose.
///
/// It accepts a validated merchant [GeoPoint], never a free-form URL, and
/// builds the platform's Google Maps URI itself:
/// - Android: `google.navigation:q=<lat>,<lng>&mode=d` (handled only by the
///   Google Maps app; driving mode). Needs the matching `<queries>` entry.
/// - iOS: `comgooglemaps://?daddr=<lat>,<lng>&directionsmode=driving`.
///   Needs `comgooglemaps` in `LSApplicationQueriesSchemes`.
///
/// Latitude comes first in both. Returning to SHAHM triggers the existing
/// foreground recovery; opening Maps never changes the order's stage.
class PickupNavigationLauncher {
  const PickupNavigationLauncher({
    this.launcher = const UrlLauncherExternalAppLauncher(),
    this.platform,
  });

  final ExternalAppLauncher launcher;

  /// Overrides the platform (tests). Null: `defaultTargetPlatform`.
  final TargetPlatform? platform;

  /// A decimal coordinate without exponent notation.
  static String _coordinate(double value) => value.toStringAsFixed(7);

  /// The Google Maps navigation URI for [destination] on [platform], or
  /// null when the platform has no supported Google Maps URI.
  static Uri? googleMapsUri(GeoPoint destination, TargetPlatform platform) {
    final point =
        '${_coordinate(destination.latitude)},'
        '${_coordinate(destination.longitude)}';
    return switch (platform) {
      TargetPlatform.android => Uri.parse('google.navigation:q=$point&mode=d'),
      TargetPlatform.iOS => Uri.parse(
        'comgooglemaps://?daddr=$point&directionsmode=driving',
      ),
      _ => null,
    };
  }

  /// Opens Google Maps with driving directions to [destination].
  Future<PickupNavigationOutcome> open(GeoPoint? destination) async {
    if (destination == null || !destination.isValid) {
      return PickupNavigationOutcome.invalidDestination;
    }
    final uri = googleMapsUri(destination, platform ?? defaultTargetPlatform);
    if (uri == null) return PickupNavigationOutcome.failed;
    try {
      if (!await launcher.canOpen(uri)) {
        return PickupNavigationOutcome.appUnavailable;
      }
      return await launcher.open(uri)
          ? PickupNavigationOutcome.launched
          : PickupNavigationOutcome.appUnavailable;
    } on Object {
      return PickupNavigationOutcome.failed;
    }
  }
}
