// Current Order, pickup leg: merchant, actions, captain location, route and
// the merchant pickup map (D-A62, D-A81).

import 'package:flutter/material.dart';
import 'package:mobile_frontend/domain/use_cases/get_captain_location.dart';
import 'package:mobile_frontend/domain/use_cases/get_pickup_route.dart';
import 'package:mobile_frontend/helper/money/jod_format.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/util/responsive/app_breakpoints.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/cubit/current_order_cubit.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/widget/order_command_notice.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/widget/pickup_map.dart';
import 'package:mobile_frontend/view/widget/buttons/app_button.dart';
import 'package:mobile_frontend/view/widget/buttons/app_text_button.dart';
import 'package:mobile_frontend/view/widget/status/app_status_message.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

/// The pickup leg (`accepted` / `heading_to_pickup`, one presentation):
/// the merchant card, «تم الاستلام» and «فتح في خرائط Google», the
/// captain's location state, the route summary and the map area.
///
/// The merchant card and the pickup action are always shown: a missing
/// map, route or captain position never hides the order or disables a
/// valid pickup. The map area shows, by priority: "merchant location
/// unavailable" (no valid coordinates; never a default point), "map
/// unavailable" (no provider configured), or the map. The destination is
/// always the merchant.
///
/// Presentation only: every callback is handled by the Cubit or the page.
class ActiveOrderPickupView extends StatelessWidget {
  const ActiveOrderPickupView({
    super.key,
    required this.state,
    required this.onRetryLocation,
    required this.onRefresh,
    required this.onConfirmPickup,
    required this.onOpenNavigation,
    required this.onCheckStatus,
    this.mapBuilder,
  });

  final CurrentOrderActive state;
  final VoidCallback onRetryLocation;

  /// Looks the order up again (it may have gained coordinates).
  final VoidCallback onRefresh;

  /// Sends the pickup confirmation directly (no verification code).
  final VoidCallback onConfirmPickup;

  /// Opens Google Maps navigation to the merchant.
  final VoidCallback onOpenNavigation;

  /// Reconciles an unconfirmed pickup.
  final VoidCallback onCheckStatus;

  /// Null while no maps provider is configured.
  final PickupMapBuilder? mapBuilder;

  /// Key of the map area, for tests.
  static const Key mapAreaKey = Key('current-order-map-area');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final location = state.captainLocation;
    final pickup = state.pickup;
    final padding = AppBreakpoints.screenPadding(context);
    final command = state.command;
    final pickupCommand = command?.action == OrderWorkflowAction.confirmPickup
        ? command
        : null;
    // An unknown outcome blocks a resend until it is reconciled.
    final blocked = pickupCommand?.needsReconciliation ?? false;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: padding, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            // Wider than a form: a map benefits from the room.
            constraints: const BoxConstraints(maxWidth: 840),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PickupCard(state: state),
                const SizedBox(height: 12),
                // One tap sends the command; while it is being sent the
                // button shows its spinner and ignores taps (the Cubit
                // also refuses a second command).
                AppButton(
                  label: l10n.pickupConfirmAction,
                  icon: const Icon(PhosphorIconsRegular.package),
                  isLoading: state.isSending,
                  onPressed: blocked ? null : onConfirmPickup,
                ),
                // The pickup outcome (not sent, rejected, unknown) stays
                // visible under the button; unknown adds the status check.
                if (pickupCommand != null)
                  OrderCommandNotice(
                    feedback: pickupCommand,
                    onCheckStatus: onCheckStatus,
                  ),
                const SizedBox(height: 4),
                AppTextButton(
                  label: l10n.openInGoogleMaps,
                  icon: const Icon(PhosphorIconsRegular.navigationArrow),
                  onPressed: pickup == null ? null : onOpenNavigation,
                ),
                // The captain's position is only read when a map can show.
                if (pickup != null) ...[
                  _LocationStatus(result: location, onRetry: onRetryLocation),
                  if (location is CaptainLocationFound)
                    _RouteStatus(route: state.route),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  key: mapAreaKey,
                  // Most of the body on tall screens, never tiny on short
                  // ones (the page scrolls instead).
                  height: (constraints.maxHeight * 0.55).clamp(
                    240.0,
                    double.infinity,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ColoredBox(
                      color: Theme.of(context).colorScheme.surface,
                      child: pickup == null
                          ? AppStatusMessage(
                              icon: PhosphorIconsRegular.mapPinArea,
                              title: l10n.pickupLocationInvalidTitle,
                              message: l10n.pickupLocationInvalidMessage(
                                state.order.restaurantName,
                              ),
                              actionLabel: l10n.retry,
                              onAction: onRefresh,
                            )
                          : mapBuilder == null
                          ? AppStatusMessage(
                              icon: PhosphorIconsRegular.mapTrifold,
                              title: l10n.mapUnavailableTitle,
                              message: l10n.mapUnavailableMessage,
                            )
                          : mapBuilder!(
                              context,
                              PickupMapData(
                                orderId: state.order.orderId,
                                restaurantName: state.order.restaurantName,
                                pickup: pickup,
                                captainLocation:
                                    location is CaptainLocationFound
                                    ? location.location
                                    : null,
                                routePath: switch (state.route) {
                                  PickupRouteFound(:final route) => route.path,
                                  _ => null,
                                },
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Merchant name, the "pickup point" label and any pickup instructions.
class _PickupCard extends StatelessWidget {
  const _PickupCard({required this.state});

  final CurrentOrderActive state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final instructions = state.order.pickupInstructions?.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ExcludeSemantics(
              child: Icon(
                PhosphorIconsFill.storefront,
                size: 32,
                color: AppColor.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.pickupPointLabel,
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColor.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.order.restaurantName,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColor.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (instructions != null && instructions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.pickupInstructionsLabel,
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColor.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      instructions,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColor.textPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One line about the captain's own location; nothing once it is known.
class _LocationStatus extends StatelessWidget {
  const _LocationStatus({required this.result, required this.onRetry});

  /// Null while the position is being read.
  final CaptainLocationResult? result;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (String text, bool canRetry) = switch (result) {
      null => (l10n.locationLocating, false),
      CaptainLocationFound() => ('', false),
      // The reason is explained; a new prompt happens only if the user
      // presses Retry.
      CaptainLocationPermissionDenied() => (
        '${l10n.locationPermissionDenied} ${l10n.locationPermissionRationale}',
        true,
      ),
      CaptainLocationUnavailable() => (l10n.locationUnavailable, true),
      CaptainLocationNotConfigured() => (l10n.locationNotConfigured, false),
    };
    if (text.isEmpty) return const SizedBox.shrink();
    return _StatusLine(
      icon: PhosphorIconsRegular.crosshair,
      text: text,
      action: canRetry
          ? AppTextButton(label: l10n.retry, onPressed: onRetry)
          : null,
    );
  }
}

/// The road route summary, or why there is none. Only real routing data
/// is shown; there is never a straight-line estimate.
class _RouteStatus extends StatelessWidget {
  const _RouteStatus({required this.route});

  /// Null while the route is being read.
  final PickupRouteResult? route;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = switch (route) {
      null => l10n.loading,
      PickupRouteFound(:final route) => l10n.routeDistanceAndTime(
        ltrIsolate((route.distanceMeters / 1000).toStringAsFixed(1)),
        (route.durationSeconds / 60).ceil(),
      ),
      PickupRouteNotConfigured() => l10n.routeNotConfigured,
      PickupRouteUnavailable() => l10n.routeUnavailable,
    };
    return _StatusLine(icon: PhosphorIconsRegular.path, text: text);
  }
}

/// A small icon + text status line (live region).
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Semantics(
      container: true,
      liveRegion: true,
      child: Row(
        children: [
          ExcludeSemantics(
            child: Icon(icon, size: 20, color: AppColor.textSecondary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColor.textSecondary),
            ),
          ),
          ?action,
        ],
      ),
    ),
  );
}
