// Short access to the generated localizations from any widget.

import 'package:flutter/widgets.dart';
import 'package:mobile_frontend/helper/translation/generated/app_localizations.dart';

/// `context.l10n.someKey` instead of `AppLocalizations.of(context).someKey`.
///
/// All user-facing text comes from `app_ar.arb` through this accessor; never
/// hard-code UI strings in widgets.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
