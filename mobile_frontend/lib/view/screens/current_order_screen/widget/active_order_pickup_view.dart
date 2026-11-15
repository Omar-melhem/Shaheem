// Body of the Current Order screen when an active order can be mapped.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/domain/use_cases/get_captain_location.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/util/responsive/app_breakpoints.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/cubit/current_order_cubit.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/widget/pickup_map.dart';
import 'package:mobile_frontend/view/widget/buttons/app_text_button.dart';
import 'package:mobile_frontend/view/widget/status/app_status_message.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

/// Shows the active order's pickup: the restaurant card, the state of the
/// captain's own location, and the map area.
///
/// The restaurant card is always shown, because the order is active
/// regardless of its coordinates. The map area shows, in this order of
/// priority: "restaurant location unavailable" when the order has no usable
/// coordinates (never a default location), "map unavailable" when no map is
/// configured, or the map. The destination is always the restaurant pickup
/// point from the order.
///
/// Presentation only: the callbacks are handled by the Cubit.
class ActiveOrderPickupView extends StatelessWidget {
  const ActiveOrderPickupView({
    super.key,
    required this.state,
    required this.onRetryLocation,
    required this.onRefresh,
    this.mapBuilder,
  });

  final CurrentOrderActive state;
  final VoidCallback onRetryLocation;

  /// Looks the order up again (it may have gained coordinates).
  final VoidCallback onRefresh;

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
                // The captain's position is only read when a map can show.
                if (pickup != null)
                  _LocationStatus(result: location, onRetry: onRetryLocation),
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

/// Restaurant name, the "pickup point" label and any pickup instructions.
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
        border: Border.all(color: AppColor.border),
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

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Semantics(
        container: true,
        liveRegion: true,
        child: Row(
          children: [
            const ExcludeSemantics(
              child: Icon(
                PhosphorIconsRegular.crosshair,
                size: 20,
                color: AppColor.textSecondary,
              ),
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
            if (canRetry) AppTextButton(label: l10n.retry, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
