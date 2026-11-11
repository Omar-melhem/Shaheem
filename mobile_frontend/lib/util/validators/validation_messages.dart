// Maps validation error codes to localized text shown under form fields.

import 'package:mobile_frontend/helper/translation/generated/app_localizations.dart';
import 'package:mobile_frontend/util/validators/validation_error.dart';

/// The localized message for [error].
///
/// Validators and Cubits only deal in [ValidationError] codes; the text is
/// resolved here, at presentation time, from the ARB resources. Wording can
/// therefore change (or new languages be added) without touching the rules.
String validationMessage(AppLocalizations l10n, ValidationError error) =>
    switch (error) {
      ValidationError.required => l10n.fieldRequired,
      ValidationError.usernameRequired => l10n.usernameRequired,
      ValidationError.passwordRequired => l10n.passwordRequired,
      ValidationError.invalidPhone => l10n.invalidPhone,
    };
