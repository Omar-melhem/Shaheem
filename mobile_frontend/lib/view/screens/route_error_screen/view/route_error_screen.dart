// The localized surface go_router shows when a location cannot be opened.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/util/routes/routes_string.dart';
import 'package:mobile_frontend/view/widget/status/app_status_message.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

/// Arabic replacement for go_router's default (English) error page (R01,
/// ARCH-08/LOC-01).
///
/// It is reached only after `resolveRedirect` has let the location through,
/// which today means a signed-in captain: signed-out and unresolved sessions
/// are redirected to Login / startup before an error page can be built, so
/// this surface never bypasses the auth policy.
///
/// [notFound] distinguishes an unknown path (for example the removed
/// notifications path) from any other routing failure, which is not
/// silently called "not found". Neither the location (it may carry private
/// query values) nor the exception text is shown.
///
/// The single action goes to Home with `context.go`; the redirect policy
/// still decides whether Home may open, so there is no loop and no side
/// effect in `build`.
class RouteErrorScreen extends StatelessWidget {
  const RouteErrorScreen({super.key, required this.notFound});

  /// Builds the screen for go_router's error [state].
  factory RouteErrorScreen.fromState(GoRouterState state) =>
      RouteErrorScreen(notFound: isRouteNotFound(state.error));

  /// Whether the failure was an unknown location.
  final bool notFound;

  /// go_router reports an unmatched location with a `GoException` whose
  /// message starts with this text (go_router 18, `configuration.dart`).
  /// Any other error is a different routing failure.
  static bool isRouteNotFound(Exception? error) =>
      error is GoException &&
      error.message.startsWith('no routes for location');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: AppStatusMessage(
          icon: notFound
              ? PhosphorIconsRegular.signpost
              : PhosphorIconsRegular.warningCircle,
          title: notFound ? l10n.routeNotFoundTitle : l10n.routeErrorTitle,
          message: notFound
              ? l10n.routeNotFoundMessage
              : l10n.routeErrorMessage,
          actionLabel: l10n.routeErrorBackHome,
          onAction: () => context.go(RoutesString.home),
        ),
      ),
    );
  }
}
