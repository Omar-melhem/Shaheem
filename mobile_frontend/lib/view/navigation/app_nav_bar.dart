// Main navigation shell: connects GoRouter's branches to the visual bar.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_frontend/view/widget/navigation/main_nav_destination.dart';
import 'package:mobile_frontend/view/widget/navigation/main_navigation_bar.dart';

/// Persistent shell around the four main destinations (D-A70).
///
/// Each destination is a branch of the `StatefulShellRoute.indexedStack` in
/// `go_router.dart`. This widget owns the GoRouter side; the look of the bar
/// is in [MainNavigationBar].
///
/// - **Selection** is read from [navigationShell] on every build. There is
///   no local selected-index state, so deep links, redirects and browser
///   navigation always show the right destination.
/// - **Switching** uses `goBranch`, which restores the branch's own stack.
///   Tapping the current destination does not reset it.
/// - **System back:** a nested route pops first (GoRouter asks the branch's
///   Navigator before this route). At the root of another branch, back
///   returns to Home. At the Home root, back is not intercepted, so the
///   platform's normal behavior (leaving the app) applies.
/// - **Keyboard:** the bar is hidden while the software keyboard is open.
///
/// The bar has no indicators: Current Order is a standalone page (D-A73)
/// and the notification feed was removed (D-A72).
class AppNavBar extends StatelessWidget {
  const AppNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final homeIndex = MainNavDestination.home.index;
    final onHome = navigationShell.currentIndex == homeIndex;
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return PopScope(
      // Only reached when the current branch has nothing left to pop.
      canPop: onHome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) navigationShell.goBranch(homeIndex);
      },
      child: Scaffold(
        // The body ends above the bar, so pages are never covered by it.
        body: navigationShell,
        bottomNavigationBar: keyboardVisible
            ? null
            : MainNavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: navigationShell.goBranch,
              ),
      ),
    );
  }
}
