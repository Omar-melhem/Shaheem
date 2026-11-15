// Opens SHAHM legal pages strictly inside the app (never an external browser).

import 'package:flutter/foundation.dart';
import 'package:mobile_frontend/helper/legal/legal_links.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

/// Outcome of trying to open a legal page. Only [opened] means the page is
/// on screen; every other value must be shown to the user truthfully.
enum LegalPageOpenResult {
  /// The in-app view was presented.
  opened,

  /// No URL is configured yet (see [LegalLinks]).
  notConfigured,

  /// The configured value is not a trusted absolute HTTPS URL.
  invalidUrl,

  /// This platform cannot guarantee an in-app view, so nothing was opened.
  unsupported,

  /// The in-app view could not be presented or loaded.
  failed,
}

/// The only way the app presents a web page: an **in-app** view that the
/// user closes to return to the app.
///
/// An interface so tests can verify the decision logic without a platform
/// channel. Implementations must never fall back to an external browser,
/// another app or an OS chooser.
abstract interface class InAppWebPageLauncher {
  /// Whether the in-app web view mode is available on this device.
  Future<bool> supportsInAppWebView();

  /// Presents [url] in the in-app web view. Returns false, or throws, when
  /// it could not be presented; it must not try any other mode.
  Future<bool> openInAppWebView(Uri url);
}

/// [InAppWebPageLauncher] backed by the already-declared `url_launcher`
/// (6.3.3; verified for `url_launcher_android` 6.3.33 and
/// `url_launcher_ios` 6.4.2 — re-verify after any upgrade).
///
/// Only [url_launcher.LaunchMode.inAppWebView] is ever requested, never
/// `platformDefault` or an external mode:
/// - Android: always the plugin's own in-app `WebViewActivity` (Custom Tabs
///   are explicitly skipped for this mode); if it cannot start, the plugin
///   throws instead of falling back. Links and redirects stay inside that
///   view. There is no JavaScript bridge or download handler; JavaScript and
///   DOM storage are switched **off** here (enable only with owner approval
///   if the published page needs them).
/// - iOS: `SFSafariViewController`, an in-app, sandboxed Safari view with a
///   Done button; failures throw or return false, with no fallback. Its
///   JavaScript cannot be disabled, and its toolbar lets the user choose to
///   open the page in Safari themselves.
class UrlLauncherInAppWebPageLauncher implements InAppWebPageLauncher {
  const UrlLauncherInAppWebPageLauncher();

  @override
  Future<bool> supportsInAppWebView() =>
      url_launcher.supportsLaunchMode(url_launcher.LaunchMode.inAppWebView);

  @override
  Future<bool> openInAppWebView(Uri url) => url_launcher.launchUrl(
    url,
    mode: url_launcher.LaunchMode.inAppWebView,
    webViewConfiguration: const url_launcher.WebViewConfiguration(
      enableJavaScript: false,
      enableDomStorage: false,
    ),
  );
}

/// Opens SHAHM legal pages in-app after checking the URL and the platform.
///
/// Presentational code calls [openTermsAndConditions] and shows the result;
/// it never launches URLs itself. No external-browser path exists here.
class LegalPageLauncher {
  /// [termsUrl] defaults to [LegalLinks.termsAndConditions]; [platform]
  /// defaults to the running platform. Both are injectable for tests.
  const LegalPageLauncher({
    this.launcher = const UrlLauncherInAppWebPageLauncher(),
    this.termsUrl = LegalLinks.termsAndConditions,
    this.platform,
  });

  /// The in-app presenter; never an external launcher.
  final InAppWebPageLauncher launcher;

  /// The configured Terms & Conditions URL ('' = not provided yet).
  final String termsUrl;

  /// Overrides the running platform (tests only); null uses the real one.
  final TargetPlatform? platform;

  /// Platforms whose in-app behavior was verified (the app targets these).
  static const _verifiedPlatforms = {
    TargetPlatform.android,
    TargetPlatform.iOS,
  };

  /// Returns [raw] as a trusted URL, or null when it is not an absolute
  /// `https` URL with a host and without embedded credentials. The value is
  /// used exactly as configured (no trimming or rewriting).
  static Uri? trustedHttpsUri(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        !uri.isAbsolute ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    return uri;
  }

  /// Opens the Terms & Conditions page in-app, or explains why it did not.
  Future<LegalPageOpenResult> openTermsAndConditions() => _open(termsUrl);

  Future<LegalPageOpenResult> _open(String raw) async {
    if (raw.isEmpty) return LegalPageOpenResult.notConfigured;
    final uri = trustedHttpsUri(raw);
    if (uri == null) return LegalPageOpenResult.invalidUrl;

    // Web and desktop are not targets and were not verified as in-app.
    if (kIsWeb ||
        !_verifiedPlatforms.contains(platform ?? defaultTargetPlatform)) {
      return LegalPageOpenResult.unsupported;
    }
    try {
      if (!await launcher.supportsInAppWebView()) {
        return LegalPageOpenResult.unsupported;
      }
      final opened = await launcher.openInAppWebView(uri);
      return opened ? LegalPageOpenResult.opened : LegalPageOpenResult.failed;
    } on Object {
      // Platform errors are reported as a failure; no other mode is tried.
      return LegalPageOpenResult.failed;
    }
  }
}
