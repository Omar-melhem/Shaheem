import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Main navigation shell for signed-in users.
///
/// Each tab is a branch of the `StatefulShellRoute` in `go_router.dart`.
/// Only Home exists so far, and Material's bottom navigation needs at least
/// two destinations, so the bar is hidden until a second tab is specified.
class AppNavBar extends StatelessWidget {
  const AppNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: navigationShell);
  }
}
