// Current Order, delivery leg: the order details (D-A83) and the Start
// Delivery / Complete Delivery actions (D-A81). No map.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/domain/entities/active_order.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/util/responsive/app_breakpoints.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/cubit/current_order_cubit.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/widget/order_command_notice.dart';
import 'package:mobile_frontend/view/widget/buttons/app_button.dart';
import 'package:mobile_frontend/view/widget/order/order_delivery_details.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

/// The delivery leg after a server-confirmed pickup:
/// - `picked_up`: «بدء التوصيل» (the separate start action, D-A81);
/// - `on_the_way`: «تم تسليم الطلب».
///
/// There is deliberately **no map** and no customer location. The shared
/// [OrderDeliveryDetails] section shows the merchant-supplied details
/// (D-A83): optional customer name and phone, the required destination
/// area, optional delivery notes and the full delivery fee. No optional
/// detail ever blocks an action. Which action shows depends only on the
/// server-reported status; a failed or unknown command keeps the last
/// confirmed stage.
///
/// Presentation only: the page wires the callbacks to the Cubit.
class ActiveOrderDeliveryView extends StatelessWidget {
  const ActiveOrderDeliveryView({
    super.key,
    required this.state,
    required this.onStartDelivery,
    required this.onCompleteDelivery,
    required this.onCheckStatus,
  });

  final CurrentOrderActive state;
  final VoidCallback onStartDelivery;

  /// Asks for confirmation, then completes (see the page).
  final VoidCallback onCompleteDelivery;

  /// Reconciles an unconfirmed command.
  final VoidCallback onCheckStatus;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final order = state.order;
    final onTheWay = order.status == ActiveOrderStatus.onTheWay;
    final action = onTheWay
        ? OrderWorkflowAction.completeDelivery
        : OrderWorkflowAction.startDelivery;
    final command = state.command?.action == action ? state.command : null;
    final blocked = command?.needsReconciliation ?? false;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppBreakpoints.screenPadding(context),
        vertical: 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppBreakpoints.formMaxWidth(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                liveRegion: true,
                child: Text(
                  onTheWay
                      ? l10n.deliveryStatusOnTheWay
                      : l10n.deliveryStatusPickedUp,
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColor.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.pickedUpFromLine(order.restaurantName),
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColor.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              OrderDeliveryDetails(
                customerName: order.customerName,
                customerPhone: order.customerPhone,
                deliveryAreaName: order.deliveryAreaName,
                deliveryNotes: order.deliveryNotes,
                deliveryFeeFils: order.deliveryFeeFils,
              ),
              const SizedBox(height: 20),
              AppButton(
                label: onTheWay
                    ? l10n.completeDeliveryAction
                    : l10n.startDeliveryAction,
                icon: Icon(
                  onTheWay
                      ? PhosphorIconsRegular.checkCircle
                      : PhosphorIconsRegular.moped,
                ),
                isLoading: state.isSending,
                onPressed: blocked
                    ? null
                    : (onTheWay ? onCompleteDelivery : onStartDelivery),
              ),
              if (command != null)
                OrderCommandNotice(
                  feedback: command,
                  onCheckStatus: onCheckStatus,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
