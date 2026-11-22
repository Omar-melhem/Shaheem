// Current Order, delivery leg: destination area, optional customer phone
// and the Start Delivery / Complete Delivery actions (D-A81). No map.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/domain/entities/active_order.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/util/responsive/app_breakpoints.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/cubit/current_order_cubit.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/widget/customer_contact_card.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/widget/order_command_notice.dart';
import 'package:mobile_frontend/view/widget/buttons/app_button.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

/// The delivery leg after a server-confirmed pickup:
/// - `picked_up`: «بدء التوصيل» (the separate start action, D-A81);
/// - `on_the_way`: «تم تسليم الطلب».
///
/// There is deliberately **no map** and no customer location: only the
/// destination area and, when the merchant supplied one, the customer
/// phone. Which action shows depends only on the server-reported status;
/// a failed or unknown command keeps the last confirmed stage.
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
    final phone = order.contactPhone;
    final area = order.deliveryAreaName?.trim();
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
              const SizedBox(height: 12),
              _DestinationCard(
                area: area == null || area.isEmpty ? null : area,
                merchant: order.restaurantName,
              ),
              if (phone != null) ...[
                const SizedBox(height: 12),
                CustomerContactCard(phone: phone),
              ],
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

/// The destination area, shown prominently, and where the order came from.
class _DestinationCard extends StatelessWidget {
  const _DestinationCard({required this.area, required this.merchant});

  /// Null when the server sent none (shown honestly, never invented).
  final String? area;
  final String merchant;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
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
                PhosphorIconsFill.flag,
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
                    l10n.deliveryDestinationHeading,
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColor.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    area ?? l10n.deliveryAreaUnavailable,
                    style: textTheme.headlineSmall?.copyWith(
                      color: area == null
                          ? AppColor.textSecondary
                          : AppColor.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.pickedUpFromLine(merchant),
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColor.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
