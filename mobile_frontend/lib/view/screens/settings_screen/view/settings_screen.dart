// Settings (D-A78): the display language, and the account-deletion entry
// with its outcome.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/util/responsive/app_breakpoints.dart';
import 'package:mobile_frontend/view/app_state/locale/app_locale_cubit.dart';
import 'package:mobile_frontend/view/screens/settings_screen/cubit/account_deletion_cubit.dart';
import 'package:mobile_frontend/view/screens/settings_screen/widget/account_deletion_confirmation.dart';
import 'package:mobile_frontend/view/widget/buttons/app_text_button.dart';

/// The protected Settings page above the shell (pushed from «حسابي»; Back
/// returns there).
///
/// It first offers the display language (العربية / English, the current one
/// marked; a tap applies it at once through the app-wide `AppLocaleCubit`,
/// without leaving the page or the session). Separately, under «الحساب», it
/// holds an easy-to-find, clearly destructive «حذف الحساب» entry. A tap
/// never deletes anything: it opens [showAccountDeletionConfirmation] with
/// separate Cancel and Confirm controls, and only Confirm calls
/// [AccountDeletionCubit.submitConfirmed] (once; repeated taps are
/// ignored). The outcome is shown under the entry in plain language and is
/// never overstated: "pending" is not "deleted", and a missing backend,
/// offline or failure say nothing was deleted.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _startDeletion(BuildContext context) async {
    final cubit = context.read<AccountDeletionCubit>();
    if (!cubit.canSubmit) return;
    final confirmed = await showAccountDeletionConfirmation(context);
    if (confirmed) await cubit.submitConfirmed();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<AccountDeletionCubit>();
    final state = context.watch<AccountDeletionCubit>().state;
    final submitting = state == AccountDeletionFlow.submitting;

    final String? outcome = switch (state) {
      AccountDeletionFlow.notSent ||
      AccountDeletionFlow.submitting ||
      AccountDeletionFlow.completed => null,
      AccountDeletionFlow.notConfigured => l10n.accountDeletionNotConfigured,
      AccountDeletionFlow.noInternet => l10n.accountDeletionNoInternet,
      AccountDeletionFlow.failure => l10n.accountDeletionFailed,
      AccountDeletionFlow.unconfirmed => l10n.accountDeletionUnconfirmed,
      AccountDeletionFlow.reauthenticationRequired =>
        l10n.accountDeletionReauthRequired,
      AccountDeletionFlow.pending => l10n.accountDeletionPending,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final side = AppBreakpoints.screenPadding(context);
          final maxWidth = AppBreakpoints.formMaxWidth(context);
          final end = math.max(side, constraints.maxWidth - side - maxWidth);
          return ListView(
            padding: EdgeInsetsDirectional.fromSTEB(side, 16, end, 24),
            children: [
              const _LanguageSection(),
              const SizedBox(height: 24),
              Text(
                l10n.settingsAccountSection,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColor.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Destructive, but not a primary red button: an outlined
              // error-colored row with a delete icon and an explicit label.
              // Its own Material, so the tile's ink is visible on the white
              // surface.
              Material(
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: cubit.canSubmit ? AppColor.error : AppColor.divider,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  minTileHeight: 56,
                  enabled: cubit.canSubmit,
                  leading: submitting
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Icon(
                          Icons.delete_outline,
                          color: cubit.canSubmit
                              ? AppColor.error
                              : AppColor.disabledForeground,
                        ),
                  title: Text(
                    submitting
                        ? l10n.accountDeletionSubmitting
                        : l10n.accountDeletionEntry,
                    style: TextStyle(
                      color: cubit.canSubmit
                          ? AppColor.error
                          : AppColor.disabledForeground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(l10n.accountDeletionEntryHint),
                  onTap: () => unawaited(_startDeletion(context)),
                ),
              ),
              if (outcome != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  container: true,
                  liveRegion: true,
                  child: Text(
                    outcome,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColor.textPrimary,
                    ),
                  ),
                ),
                if (state == AccountDeletionFlow.reauthenticationRequired)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AppTextButton(
                      label: l10n.accountDeletionSignInAgain,
                      onPressed: () => unawaited(cubit.reauthenticate()),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// «اللغة»: the two supported languages, each shown in its own language,
/// with the current one marked (check icon and the selected semantics).
/// A tap applies the language immediately; choosing the current one does
/// nothing. Not persisted across restarts (see `AppLocaleCubit`).
class _LanguageSection extends StatelessWidget {
  const _LanguageSection();

  /// Key of one language option, for tests.
  static Key optionKey(AppLanguage language) =>
      Key('settings-language-${language.name}');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final current = context.watch<AppLocaleCubit>().state;
    final cubit = context.read<AppLocaleCubit>();

    Widget option(AppLanguage language, String label) {
      final selected = language == current;
      return ListTile(
        key: optionKey(language),
        minTileHeight: 56,
        selected: selected,
        selectedColor: AppColor.textPrimary,
        leading: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: selected ? theme.colorScheme.primary : AppColor.inputOutline,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: selected
            ? Icon(Icons.check, color: theme.colorScheme.primary)
            : null,
        onTap: () => cubit.select(language),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.settingsLanguageSection,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColor.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColor.divider),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              children: [
                option(AppLanguage.arabic, l10n.languageArabic),
                const Divider(height: 1, color: AppColor.divider),
                option(AppLanguage.english, l10n.languageEnglish),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
