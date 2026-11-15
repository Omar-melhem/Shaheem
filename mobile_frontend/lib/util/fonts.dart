// Font family names registered in pubspec.yaml.

/// Registered font families.
///
/// Values are Flutter **family names** from the `fonts:` section of
/// `pubspec.yaml`, never asset paths. IBM Plex Sans Arabic (D-A63) covers
/// Arabic and Latin, so one family serves the whole app. The obsolete
/// Tajawal/Inter names (which pointed at missing asset paths) were removed.
abstract final class AppFonts {
  /// IBM Plex Sans Arabic: weights 300, 400, 500, 600 and 700 are bundled
  /// in `assets/fonts/ibm_plex_sans_arabic/` (SIL OFL 1.1, see `OFL.txt`).
  static const String ibmPlexSansArabic = 'IBMPlexSansArabic';
}
