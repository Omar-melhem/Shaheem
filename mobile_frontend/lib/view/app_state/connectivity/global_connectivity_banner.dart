// App-wide offline banner, mounted once around all routed content.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/view/app_state/connectivity/app_connectivity_cubit.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';

/// Wraps the routed app and shows a banner at the top while internet is
/// confirmed lost.
///
/// Mounted once in `MaterialApp.router`'s `builder`, so every route gets it
/// and no screen adds its own. It only presents [AppConnectivityCubit]
/// state; it does not monitor anything. It never navigates.
///
/// - Hidden while startup is unresolved (session unknown): during startup,
///   the dedicated No Internet screen handles being offline.
/// - Hidden for a failed/unknown check: that is not proof of being offline.
/// - Retry triggers the shared check; it is disabled while one is running.
class GlobalConnectivityBanner extends StatelessWidget {
  const GlobalConnectivityBanner({super.key, required this.child});

  /// Key of the visible bar, so tests can tell it apart from the No
  /// Internet screen (which uses the same Arabic title).
  static const Key barKey = Key('global-offline-bar');

  /// The routed app content (the Navigator from `MaterialApp.router`).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final connectivity = context.watch<AppConnectivityCubit>().state;
    final startupResolved =
        context.watch<AppSessionCubit>().state is! SessionUnknown;
    final showBanner = startupResolved && connectivity.isDisconnected;
    final mediaQuery = MediaQuery.of(context);

    // The child always stays at the same position in the tree, so showing
    // or hiding the banner never rebuilds routes from scratch or loses
    // their state.
    return Column(
      children: [
        if (showBanner)
          _OfflineBar(key: barKey, isChecking: connectivity.isChecking)
        else
          const SizedBox.shrink(),
        Expanded(
          // The banner already covers the status-bar inset, so remove it
          // from the pages below to avoid a double gap.
          child: MediaQuery(
            data: showBanner
                ? mediaQuery.removePadding(removeTop: true)
                : mediaQuery,
            child: child,
          ),
        ),
      ],
    );
  }
}

/// The visible bar: message plus Retry, inside the top safe area.
class _OfflineBar extends StatelessWidget {
  const _OfflineBar({super.key, required this.isChecking});

  final bool isChecking;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.primary,
      child: SafeArea(
        bottom: false,
        child: Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.wifi_off_rounded, color: AppColor.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.offlineBanner,
                    style: const TextStyle(
                      color: AppColor.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColor.white,
                    minimumSize: const Size(48, 40),
                  ),
                  onPressed: isChecking
                      ? null
                      : () => context.read<AppConnectivityCubit>().check(),
                  child: Text(context.l10n.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
