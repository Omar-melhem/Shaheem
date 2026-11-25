// «تفاصيل الطلب المكتمل»: one completed order's historical details (D-A83).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_frontend/domain/entities/order_workflow.dart';
import 'package:mobile_frontend/helper/date/date_time_format.dart';
import 'package:mobile_frontend/helper/money/jod_format.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/util/responsive/app_breakpoints.dart';
import 'package:mobile_frontend/util/routes/routes_string.dart';
import 'package:mobile_frontend/view/screens/order_history_screen/cubit/completed_deliveries_cubit.dart';
import 'package:mobile_frontend/view/widget/order/order_delivery_details.dart';
import 'package:mobile_frontend/view/widget/status/app_status_message.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

/// The protected, **read-only** page of one completed order, pushed inside
/// the My Orders branch (Back returns to the list, which keeps its state).
///
/// It shows the exact record for [orderId] that this session received from
/// the server ([CompletedDeliveriesState.recordFor]): order reference,
/// merchant, «تم التسليم», the server's completion time, and the shared
/// [OrderDeliveryDetails] (optional name/phone/notes, area, full fee) as
/// recorded for that order. Nothing is fetched here: no per-order detail
/// contract exists yet, and no row is prefetched. When the record is not in
/// this session's history (a direct link, or it was never loaded), the page
/// says so explicitly — it never shows another order, the current active
/// order or an invented record. There is no pickup/start/complete action.
class CompletedOrderDetailsScreen extends StatelessWidget {
  const CompletedOrderDetailsScreen({super.key, required this.orderId});

  /// The route key of the order; only used to look the record up.
  final String orderId;

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutesString.orderHistory);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final record = context.select<CompletedDeliveriesCubit, CompletedDelivery?>(
      (cubit) => cubit.state.recordFor(orderId),
    );
    final status = context
        .select<CompletedDeliveriesCubit, CompletedDeliveriesStatus>(
          (cubit) => cubit.state.status,
        );

    final Widget body;
    if (record != null) {
      body = _Details(record: record);
    } else if (status == CompletedDeliveriesStatus.loading) {
      // A list read already running may bring the record; this page never
      // starts one (and "not read yet" falls through to "unavailable", so
      // a direct link never spins forever).
      body = AppStatusMessage(
        icon: PhosphorIconsRegular.receipt,
        title: l10n.completedDeliveriesLoading,
        isLoading: true,
      );
    } else if (status == CompletedDeliveriesStatus.notConfigured) {
      body = AppStatusMessage(
        icon: PhosphorIconsRegular.plugs,
        title: l10n.completedOrderUnavailableTitle,
        message: l10n.completedDeliveriesNotConfigured,
      );
    } else {
      body = AppStatusMessage(
        icon: PhosphorIconsRegular.receipt,
        title: l10n.completedOrderUnavailableTitle,
        message: l10n.completedOrderUnavailableMessage,
        actionLabel: l10n.completedOrderBack,
        onAction: () => _back(context),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => _back(context)),
        title: Text(l10n.completedOrderTitle),
      ),
      body: body,
    );
  }
}

/// The record's identity, merchant, status, time and delivery details.
class _Details extends StatelessWidget {
  const _Details({required this.record});

  final CompletedDelivery record;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final merchant = record.merchantName?.trim();
    final secondary = textTheme.bodyMedium?.copyWith(
      color: AppColor.textSecondary,
    );
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
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppColor.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.completedDeliveryOutcome,
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColor.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (merchant != null && merchant.isNotEmpty) ...[
                Text(
                  l10n.completedOrderMerchantLine(merchant),
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColor.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                l10n.completedOrderIdLine(ltrIsolate(record.orderId)),
                style: secondary,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.completedOrderDeliveredAtLine(
                  ltrIsolate(formatLocalDateTime(record.deliveredAt)),
                ),
                style: secondary,
              ),
              const SizedBox(height: 16),
              OrderDeliveryDetails(
                customerName: record.customerName,
                customerPhone: record.customerPhone,
                deliveryAreaName: record.deliveryAreaName,
                deliveryNotes: record.deliveryNotes,
                deliveryFeeFils: record.deliveryFeeFils,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
