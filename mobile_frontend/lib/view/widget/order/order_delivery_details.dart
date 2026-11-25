// Shared «تفاصيل الطلب» section of the delivery leg and of a completed
// order's page (D-A83).

import 'package:flutter/material.dart';
import 'package:mobile_frontend/domain/entities/active_order.dart';
import 'package:mobile_frontend/helper/money/jod_format.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

/// The order details the merchant supplied, presentation only:
///
/// | Detail | Business rule | When absent |
/// |---|---|---|
/// | Customer name | optional | row omitted |
/// | Customer phone | optional | row omitted (never blocks anything) |
/// | Destination area | required | «منطقة التسليم غير متوفرة» |
/// | Delivery notes | optional | row omitted |
/// | Full delivery fee | required | «أجرة التوصيل غير متوفرة» (never 0) |
///
/// Optional texts that are null, empty or whitespace-only are treated as
/// absent. An explicit fee of 0 is shown as 0. The phone and the amount are
/// LTR-isolated inside the RTL page; the phone is selectable so it can be
/// called outside SHAHM. No map, coordinates or address. Each row is one
/// screen-reader sentence.
///
/// Used by `ActiveOrderDeliveryView` (delivery leg) and
/// `CompletedOrderDetailsScreen` (a past order's snapshot). It owns no
/// state and performs no action.
class OrderDeliveryDetails extends StatelessWidget {
  const OrderDeliveryDetails({
    super.key,
    required this.deliveryAreaName,
    required this.deliveryFeeFils,
    this.customerName,
    this.customerPhone,
    this.deliveryNotes,
  });

  /// Required by the business; null/blank shows the unavailable text.
  final String? deliveryAreaName;

  /// Required by the business; null shows the unavailable text.
  final int? deliveryFeeFils;

  final String? customerName;
  final String? customerPhone;
  final String? deliveryNotes;

  /// Key of the section, for tests.
  static const Key sectionKey = Key('order-delivery-details');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final name = presentText(customerName);
    final phone = presentText(customerPhone);
    final area = presentText(deliveryAreaName);
    final notes = presentText(deliveryNotes);
    final fee = deliveryFeeFils;

    final rows = <Widget>[
      if (name != null)
        _DetailRow(
          icon: PhosphorIconsRegular.user,
          label: l10n.orderDetailCustomerName,
          value: name,
        ),
      if (phone != null)
        _DetailRow(
          icon: PhosphorIconsRegular.phone,
          label: l10n.orderDetailCustomerPhone,
          value: phone,
          ltr: true,
          selectable: true,
        ),
      _DetailRow(
        icon: PhosphorIconsRegular.flag,
        label: l10n.deliveryDestinationHeading,
        value: area ?? l10n.deliveryAreaUnavailable,
        unavailable: area == null,
        emphasized: true,
      ),
      if (notes != null)
        _DetailRow(
          icon: PhosphorIconsRegular.notepad,
          label: l10n.orderDetailDeliveryNotes,
          value: notes,
        ),
      _DetailRow(
        icon: PhosphorIconsRegular.money,
        label: l10n.offerDeliveryFeeLabel,
        value: fee == null
            ? l10n.orderDetailFeeUnavailable
            : '${ltrIsolate(formatJodFils(fee))} ${l10n.walletCurrencySymbol}',
        unavailable: fee == null,
      ),
    ];

    return DecoratedBox(
      key: sectionKey,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.orderDetailsHeading,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColor.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            for (final row in rows) ...[const SizedBox(height: 14), row],
          ],
        ),
      ),
    );
  }
}

/// One labelled detail: a decorative icon, the label and the value.
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.ltr = false,
    this.selectable = false,
    this.unavailable = false,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final String value;

  /// Digits (a phone) shown left to right inside the RTL page.
  final bool ltr;
  final bool selectable;

  /// The value is the "not available" text, shown in a secondary color.
  final bool unavailable;

  /// The destination area is the most important line of the delivery leg.
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final shown = ltr ? ltrIsolate(value) : value;
    final style = (emphasized ? textTheme.titleLarge : textTheme.bodyLarge)
        ?.copyWith(
          color: unavailable ? AppColor.textSecondary : AppColor.textPrimary,
          fontWeight: unavailable ? FontWeight.normal : FontWeight.w600,
        );
    return Semantics(
      container: true,
      label: l10n.orderDetailSemantics(label, value),
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppColor.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColor.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                selectable
                    ? SelectableText(shown, style: style)
                    : Text(shown, style: style),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
