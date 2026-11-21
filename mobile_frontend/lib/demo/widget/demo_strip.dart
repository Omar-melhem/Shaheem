// SHAHM DEMO (Task 37) — the always-visible demo badge and demo controls.
// Removed by `bash tool/demo/remove_demo.sh --apply`.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/demo/demo_state.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';

/// A dark strip above every screen of the demo app (Login, the shell,
/// pages above it and any open sheet or popup, which sit below it): «وضع تجريبي —
/// بيانات وهمية», and for a signed-in demo captain «إظهار طلب جديد» plus a
/// row of demo tools (active-order scenario, scheduled sample, reset, sign
/// out).
///
/// It is mounted by `MaterialApp.builder`, outside the Navigator, so it never
/// covers the navigation bar, a sheet's actions or the safe area: the app
/// below it gets the remaining height. It uses no tooltips or menus (they
/// need the Navigator's overlay). It only calls [DemoState] and the real
/// `AppSessionCubit.endSession`; the shell's `DemoShellBridge` makes the
/// real Cubits re-read.
class DemoStrip extends StatefulWidget {
  const DemoStrip({super.key, required this.state, required this.child});

  final DemoState state;

  /// The app below the strip.
  final Widget child;

  @override
  State<DemoStrip> createState() => _DemoStripState();
}

class _DemoStripState extends State<DemoStrip> {
  bool _toolsOpen = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final onStrip = theme.textTheme.labelLarge?.copyWith(
      color: AppColor.white,
      fontWeight: FontWeight.bold,
    );
    final signedIn = context.select<AppSessionCubit, bool>(
      (c) => c.state is SessionAuthenticated,
    );
    final state = widget.state;

    Widget tool(String label, IconData icon, VoidCallback onPressed) =>
        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: AppColor.white,
            minimumSize: const Size(48, 48),
          ),
          icon: Icon(icon, size: 20),
          label: Text(label),
          onPressed: onPressed,
        );

    final strip = Material(
      color: AppColor.secondary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: ListenableBuilder(
            listenable: state,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(l10n.demoBadge, style: onStrip),
                    ),
                    if (signedIn)
                      Wrap(
                        spacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColor.white,
                              foregroundColor: AppColor.secondary,
                              minimumSize: const Size(48, 40),
                            ),
                            icon: const Icon(Icons.add_alert_outlined),
                            label: Text(l10n.demoShowNewOffer),
                            onPressed: state.canInjectOffer
                                ? () => state.injectOffer()
                                : null,
                          ),
                          tool(
                            _toolsOpen ? l10n.demoToolsHide : l10n.demoTools,
                            _toolsOpen ? Icons.expand_less : Icons.tune,
                            () => setState(() => _toolsOpen = !_toolsOpen),
                          ),
                        ],
                      ),
                  ],
                ),
                if (signedIn && _toolsOpen)
                  Wrap(
                    spacing: 4,
                    children: [
                      tool(
                        l10n.demoScenarioNone,
                        state.scenario == DemoOrderScenario.none &&
                                state.activeOrder == null
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        () => state.setScenario(DemoOrderScenario.none),
                      ),
                      tool(
                        l10n.demoScenarioAssigned,
                        state.scenario == DemoOrderScenario.assigned
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        () => state.setScenario(DemoOrderScenario.assigned),
                      ),
                      tool(
                        l10n.demoShowScheduled,
                        Icons.schedule,
                        () => state.showScheduledSample(),
                      ),
                      tool(l10n.demoReset, Icons.restart_alt, state.reset),
                      tool(
                        l10n.demoSignOut,
                        Icons.logout,
                        () => unawaited(
                          context.read<AppSessionCubit>().endSession(),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return Column(
      children: [
        strip,
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
