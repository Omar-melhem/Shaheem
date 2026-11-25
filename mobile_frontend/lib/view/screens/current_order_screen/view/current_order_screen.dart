// Current Order screen: the captain's active order through pickup, delivery
// and completion (D-A73, D-A81).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_frontend/domain/entities/active_order.dart';
import 'package:mobile_frontend/helper/navigation/pickup_navigation_launcher.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/util/routes/routes_string.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/cubit/current_order_cubit.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/widget/active_order_delivery_view.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/widget/active_order_pickup_view.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/widget/pickup_map.dart';
import 'package:mobile_frontend/view/widget/pop_up_screen/app_popup.dart';
import 'package:mobile_frontend/view/widget/status/app_status_message.dart';
import 'package:mobile_frontend/view/widget/toast/app_toast.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

/// The protected standalone Current Order page (D-A73), above the shell.
///
/// Renders the app-level [CurrentOrderCubit]'s state: loading, no active
/// order, backend not connected (no Retry), a failure with Retry, and for
/// an active order the view of its **server-reported** stage (D-A81):
/// - pickup leg → [ActiveOrderPickupView] (map, Google Maps, «تم الاستلام»);
/// - delivery leg → [ActiveOrderDeliveryView] (no map; «بدء التوصيل» then
///   «تم تسليم الطلب»);
/// - unknown status → an explanation and no action.
///
/// One page for every stage (no route per stage, no new tab). The page
/// owns only presentation effects: the completion
/// confirmation, the Google Maps launch outcome and — once per confirmed
/// completion — a success toast and the switch to «طلباتي». History and
/// wallet are re-read by their own owners in the shell.
///
/// **Back:** pops to the page below, or goes Home when this is the first
/// page (startup recovery).
class CurrentOrderScreen extends StatefulWidget {
  const CurrentOrderScreen({
    super.key,
    this.pickupMapBuilder,
    this.navigationLauncher = const PickupNavigationLauncher(),
  });

  /// The map implementation; null while none is configured.
  final PickupMapBuilder? pickupMapBuilder;

  /// Opens Google Maps navigation to the merchant (tests pass a fake).
  final PickupNavigationLauncher navigationLauncher;

  @override
  State<CurrentOrderScreen> createState() => _CurrentOrderScreenState();
}

class _CurrentOrderScreenState extends State<CurrentOrderScreen> {
  /// Ignores a second Maps tap while the first launch is running.
  bool _launching = false;

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

  Future<void> _openNavigation(GeoPoint? merchant) async {
    if (_launching) return;
    _launching = true;
    try {
      final outcome = await widget.navigationLauncher.open(merchant);
      if (!mounted) return;
      final l10n = context.l10n;
      final message = switch (outcome) {
        PickupNavigationOutcome.launched => null,
        PickupNavigationOutcome.appUnavailable => l10n.googleMapsAppUnavailable,
        PickupNavigationOutcome.invalidDestination =>
          l10n.pickupNavigationUnavailable,
        PickupNavigationOutcome.failed => l10n.googleMapsLaunchFailed,
      };
      if (message != null) {
        showAppToast(context, message: message, type: AppToastType.warning);
      }
    } finally {
      _launching = false;
    }
  }

  /// Completion is financial (one commission debit), so it needs an
  /// explicit confirmation; Cancel, the barrier and Back send nothing.
  Future<void> _confirmCompletion() async {
    final l10n = context.l10n;
    final cubit = context.read<CurrentOrderCubit>();
    final confirmed = await showAppPopup<bool>(
      context,
      title: l10n.completeDeliveryConfirmTitle,
      message: l10n.completeDeliveryConfirmMessage,
      actions: [
        AppPopupAction(label: l10n.cancel),
        AppPopupAction<bool>(
          label: l10n.completeDeliveryConfirmAction,
          isPrimary: true,
          result: true,
        ),
      ],
    );
    if (confirmed == true) unawaited(cubit.completeDelivery());
  }

  /// One success message and one switch to «طلباتي» per confirmed
  /// completion (the listener fires only on the transition).
  void _onDelivered(BuildContext context, CurrentOrderState state) {
    showAppToast(
      context,
      message: context.l10n.deliveryCompletedTitle,
      type: AppToastType.success,
    );
    context.go(RoutesString.orderHistory);
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
        body: BlocConsumer<CurrentOrderCubit, CurrentOrderState>(
          listenWhen: (previous, current) =>
              previous is! CurrentOrderDelivered &&
              current is CurrentOrderDelivered,
          listener: _onDelivered,
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
            CurrentOrderDelivered() => AppStatusMessage(
              icon: PhosphorIconsRegular.checkCircle,
              title: l10n.deliveryCompletedTitle,
              message: l10n.deliveryCompletedMessage,
            ),
            CurrentOrderEnded(:final reason) => AppStatusMessage(
              icon: PhosphorIconsRegular.info,
              title: switch (reason) {
                CurrentOrderEndReason.cancelled => l10n.orderCancelledTitle,
                CurrentOrderEndReason.reassigned => l10n.orderReassignedTitle,
              },
              message: l10n.orderEndedMessage,
              actionLabel: l10n.currentOrderBackHome,
              onAction: () => context.go(RoutesString.home),
            ),
            CurrentOrderActive(:final order) => switch (order.leg) {
              ActiveOrderLeg.pickup => ActiveOrderPickupView(
                state: state,
                onRetryLocation: cubit.retryLocation,
                onRefresh: cubit.load,
                onConfirmPickup: () => unawaited(cubit.confirmPickup()),
                onOpenNavigation: () =>
                    unawaited(_openNavigation(state.pickup)),
                onCheckStatus: () => unawaited(cubit.checkCommandStatus()),
                mapBuilder: widget.pickupMapBuilder,
              ),
              ActiveOrderLeg.delivery => ActiveOrderDeliveryView(
                state: state,
                onStartDelivery: () => unawaited(cubit.startDelivery()),
                onCompleteDelivery: () => unawaited(_confirmCompletion()),
                onCheckStatus: () => unawaited(cubit.checkCommandStatus()),
              ),
              ActiveOrderLeg.unknown => AppStatusMessage(
                icon: PhosphorIconsRegular.question,
                title: l10n.orderStatusUnsupportedTitle,
                message: l10n.orderStatusUnsupportedMessage,
                actionLabel: l10n.refresh,
                onAction: cubit.load,
              ),
            },
          },
        ),
      ),
    );
  }
}
