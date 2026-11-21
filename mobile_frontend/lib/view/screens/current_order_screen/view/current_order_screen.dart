// Current Order screen: the captain's active order and its pickup map.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/util/routes/routes_string.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/cubit/current_order_cubit.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/widget/active_order_pickup_view.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/widget/pickup_map.dart';
import 'package:mobile_frontend/view/widget/status/app_status_message.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

/// The protected standalone Current Order page (D-A73), above the shell.
///
/// Shows the order the captain is currently working on and where to
/// collect it (the restaurant). It is NOT an order-creation screen and has
/// no form or submit action.
///
/// Expects the app-level [CurrentOrderCubit] above it and renders one state
/// at a time: loading, no active order (a confirmed absence, e.g. the order
/// was completed or reassigned elsewhere), backend not connected (no Retry:
/// it is not a temporary outage), a network or service failure with Retry,
/// or the active order's pickup view (which itself says so when the
/// restaurant location or the map is unavailable).
///
/// **Back:** when the page was pushed above a tab (acceptance, recovery),
/// Back returns there; when it is the first page (startup recovery), Back
/// goes to Home. There is no navigation bar and no selected tab here.
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
    // Only when nothing was looked up yet (e.g. a direct deep link);
    // acceptance, startup and recovery have already read it.
    final cubit = context.read<CurrentOrderCubit>();
    if (cubit.state is CurrentOrderInitial) cubit.load();
  }

  /// Pops back to the page below, or goes Home when this is the first page.
  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutesString.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<CurrentOrderCubit>();
    final canPop = context.canPop();

    return PopScope(
      // With nothing below (startup recovery), system back goes Home
      // instead of leaving the app.
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(RoutesString.home);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => _back(context)),
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
                CurrentOrderFailureKind.noInternet =>
                  l10n.currentOrderNoInternet,
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
      ),
    );
  }
}
