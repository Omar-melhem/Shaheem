// The single source of truth for SHAHM's public legal page addresses.

/// Public legal page URLs, configured here and nowhere else.
///
/// **Terms & Conditions: not yet provided.** The page will be published
/// later on the SHAHM web site. Leave [termsAndConditions] empty until the
/// owner supplies the real, legally reviewed public **HTTPS** address; never
/// put an example, guessed domain or placeholder document here. While it is
/// empty, the Login Terms action shows a truthful "not available yet" popup.
///
/// The Privacy Policy is a separate, mandatory store deliverable and is not
/// replaced by the Terms page; it has no entry yet.
abstract final class LegalLinks {
  /// Terms & Conditions page. Empty means "not configured yet".
  static const String termsAndConditions = '';
}
