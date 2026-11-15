// Current Order screen: the captain's active order and its pickup map.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/cubit/current_order_cubit.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/widget/active_order_pickup_view.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/widget/pickup_map.dart';
import 'package:mobile_frontend/view/widget/status/app_status_message.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

/// Root screen of the central branch of the main shell.
///
/// A shortcut to the order the captain is currently working on: it shows
/// where to collect it (the restaurant). It is NOT an order-creation screen
/// and has no form or submit action.
///
/// Expects a [CurrentOrderCubit] above it (provided by the shell route) and
/// renders one state at a time: loading, no active order, backend not
/// connected (no Retry: it is not a temporary outage), a network or service
/// failure with Retry, or the active order's pickup view (which itself says
/// so when the restaurant location or the map is unavailable). Opening the screen by a deep link starts the lookup; taps
/// on the navigation bar start it from the shell.
class CurrentOrderScreen extends StatefulWidget {
  const CurrentOrderScreen({super.key, this.pickupMapBuilder});

  /// The map implementation; null while none is configured.
  final PickupMapBuilder? pickupMapBuilder;

  @override
  State<CurrentOrderScreen> createState() => _CurrentOrderScreenState();
}

class _CurrentOrderScreenState extends State<CurrentOrderScreen> {
  @override
  void initState() {
    super.initState();
    // Only when nothing was looked up yet (e.g. direct route entry). A tap
    // on the bar has already started a lookup by now.
    final cubit = context.read<CurrentOrderCubit>();
    if (cubit.state is CurrentOrderInitial) cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<CurrentOrderCubit>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.currentOrderTitle),
        actions: [
          // Always asks the server again; ignored while a lookup runs.
          IconButton(
            onPressed: cubit.load,
            tooltip: l10n.refresh,
            icon: const Icon(PhosphorIconsRegular.arrowsClockwise),
          ),
        ],
      ),
      body: BlocBuilder<CurrentOrderCubit, CurrentOrderState>(
        builder: (context, state) => switch (state) {
          CurrentOrderInitial() || CurrentOrderLoading() => AppStatusMessage(
            icon: PhosphorIconsRegular.mapPin,
            title: l10n.currentOrderLoading,
            isLoading: true,
          ),
          CurrentOrderEmpty() => AppStatusMessage(
            icon: PhosphorIconsRegular.mapPin,
            title: l10n.currentOrderEmptyTitle,
            message: l10n.currentOrderEmptyMessage,
            actionLabel: l10n.refresh,
            onAction: cubit.load,
          ),
          // Deliberately no Retry and no "try again later" wording: nothing
          // is down, the integration simply does not exist yet.
          CurrentOrderNotConfigured() => AppStatusMessage(
            icon: PhosphorIconsRegular.plugs,
            title: l10n.currentOrderNotConfiguredTitle,
            message: l10n.currentOrderNotConfiguredMessage,
          ),
          CurrentOrderFailure(:final kind) => AppStatusMessage(
            icon: PhosphorIconsRegular.warningCircle,
            title: l10n.currentOrderLoadFailedTitle,
            message: switch (kind) {
              CurrentOrderFailureKind.noInternet => l10n.currentOrderNoInternet,
              CurrentOrderFailureKind.serviceUnavailable =>
                l10n.serviceUnavailableMessage,
              CurrentOrderFailureKind.unexpected => l10n.unexpectedError,
            },
            actionLabel: l10n.retry,
            onAction: cubit.load,
          ),
          CurrentOrderActive() => ActiveOrderPickupView(
            state: state,
            onRetryLocation: cubit.retryLocation,
            onRefresh: cubit.load,
            mapBuilder: widget.pickupMapBuilder,
          ),
        },
      ),
    );
  }
}
