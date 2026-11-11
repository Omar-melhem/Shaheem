// Localized text for each Login submission failure.

import 'package:mobile_frontend/helper/translation/generated/app_localizations.dart';
import 'package:mobile_frontend/view/screens/authentication/cubit/login_cubit.dart';

/// The message shown (as an error toast) for a failed submission.
///
/// Rejected credentials always get the same generic text, which never says
/// whether the username exists.
///
/// Account status (blocked/suspended) is NOT disclosed on Login yet: showing
/// it requires both an explicit backend status and an approved
/// blocked-account policy (decision D-P16, still pending). Until then a
/// blocked account gets the same generic authentication error. The Cubit
/// still records [LoginFailure.accountBlocked], so enabling the specific
/// message later is a one-line change here.
String loginFailureMessage(AppLocalizations l10n, LoginFailure failure) =>
    switch (failure) {
      LoginFailure.invalidCredentials => l10n.loginInvalidCredentials,
      // Generic until D-P16 approves disclosing account status (see above).
      LoginFailure.accountBlocked => l10n.loginInvalidCredentials,
      LoginFailure.noInternet => l10n.loginNoInternet,
      LoginFailure.serviceUnavailable => l10n.serviceUnavailableMessage,
      LoginFailure.profileFailure => l10n.profileFailureMessage,
      LoginFailure.backendNotConfigured => l10n.loginBackendNotConfigured,
      LoginFailure.unexpected => l10n.unexpectedError,
    };
