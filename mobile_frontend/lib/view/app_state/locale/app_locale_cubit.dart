// App-wide display language: Arabic (default) or English.

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The languages the captain can choose in Settings. Only these two are
/// supported; Arabic is the default.
enum AppLanguage {
  arabic(Locale('ar')),
  english(Locale('en'));

  const AppLanguage(this.locale);

  /// The locale `MaterialApp.router` uses for this language. Its text
  /// direction (RTL for Arabic, LTR for English) comes from localization,
  /// never from a manual `Directionality`.
  final Locale locale;
}

/// The one owner of the app's display language (owner-requested feature).
///
/// Created once in `MainApp` and provided above `MaterialApp.router`, which
/// reads [state] as its `locale`. Changing the language only rebuilds the
/// app's localizations and direction: the same router, session, Cubits and
/// active order stay in place (no new app key, no sign-out, no reload).
///
/// **Not persisted.** The project has no approved preference store (no
/// `shared_preferences` or similar dependency), so the choice lives in
/// memory and the app starts in Arabic again after a restart. Persisting it
/// needs an owner-approved storage dependency first.
class AppLocaleCubit extends Cubit<AppLanguage> {
  AppLocaleCubit([super.initial = AppLanguage.arabic]);

  /// Applies [language] immediately; choosing the current one is a no-op.
  void select(AppLanguage language) {
    if (language == state) return;
    emit(language);
  }
}
