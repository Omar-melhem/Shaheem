// Screen shown when startup finds no usable internet connection.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/util/responsive/app_breakpoints.dart';
import 'package:mobile_frontend/view/screens/splash_screen/cubit/splash_cubit.dart';

/// Explains that an internet connection is required and offers Retry.
///
/// Retry re-runs the shared startup sequence in `SplashCubit`; this widget
/// has no connectivity logic of its own. It does not navigate: when the
/// retry succeeds, the router's redirect moves the user on.
class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isChecking = context.watch<SplashCubit>().state is SplashChecking;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: AppBreakpoints.screenPadding(context),
              vertical: 24,
            ),
            child: ConstrainedBox(
              // Shared responsive width (one breakpoint source of truth).
              constraints: BoxConstraints(
                maxWidth: AppBreakpoints.formMaxWidth(context),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    size: 72,
                    color: AppColor.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.l10n.noInternetTitle,
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(
                      color: AppColor.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.noInternetMessage,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColor.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    // Disabled while checking, so taps can't overlap.
                    onPressed: isChecking
                        ? null
                        : () => context.read<SplashCubit>().retry(),
                    child: isChecking
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.l10n.retry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
