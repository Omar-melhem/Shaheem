// Startup status area of the Splash screen (spinner or error + Retry).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/util/responsive/app_breakpoints.dart';
import 'package:mobile_frontend/helper/translation/generated/app_localizations.dart';
import 'package:mobile_frontend/view/screens/splash_screen/cubit/splash_cubit.dart';

/// Startup progress shown under the Splash logo.
///
/// A spinner while startup runs (or is about to navigate away); for a
/// recoverable failure (connectivity check failed, service unavailable,
/// profile failure, blocked account, unexpected error) the matching Arabic
/// message plus Retry.
/// Reads `SplashCubit` from the tree; it holds no state of its own.
class SplashStartupStatus extends StatelessWidget {
  const SplashStartupStatus({super.key});

  /// The localized message for each recoverable error state, or null when
  /// startup is still running or has resolved.
  static String? _errorMessage(AppLocalizations l10n, SplashState state) =>
      switch (state) {
        SplashConnectivityCheckFailed() => l10n.connectivityCheckFailedMessage,
        SplashServiceUnavailable() => l10n.serviceUnavailableMessage,
        SplashProfileFailure() => l10n.profileFailureMessage,
        SplashBlocked() => l10n.accountBlockedMessage,
        SplashFailure() => l10n.startupFailureMessage,
        SplashInitial() ||
        SplashChecking() ||
        SplashOffline() ||
        SplashResolved() => null,
      };

  @override
  Widget build(BuildContext context) {
    final message = _errorMessage(
      context.l10n,
      context.watch<SplashCubit>().state,
    );

    if (message == null) {
      return const SizedBox(
        height: 28,
        width: 28,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }

    return ConstrainedBox(
      // Shared responsive width (one breakpoint source of truth).
      constraints: BoxConstraints(
        maxWidth: AppBreakpoints.formMaxWidth(context),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColor.textPrimary),
          ),
          const SizedBox(height: 16),
          FilledButton(
            // The cubit ignores retry while a check is running.
            onPressed: () => context.read<SplashCubit>().retry(),
            child: Text(context.l10n.retry),
          ),
        ],
      ),
    );
  }
}
