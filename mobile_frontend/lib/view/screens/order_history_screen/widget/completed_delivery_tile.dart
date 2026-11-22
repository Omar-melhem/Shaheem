// My Orders: one delivery this captain completed (D-A81).

import 'package:flutter/material.dart';
import 'package:mobile_frontend/domain/entities/order_workflow.dart';
import 'package:mobile_frontend/helper/date/date_time_format.dart';
import 'package:mobile_frontend/helper/money/jod_format.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';

/// Presentation only: merchant, destination area, «تم التسليم», the
/// server's delivery time and — when the server returns it — the full
/// delivery fee (never the commission or a net amount). Missing optional
/// data is omitted, never invented. Read as one item; not tappable.
class CompletedDeliveryTile extends StatelessWidget {
  const CompletedDeliveryTile({super.key, required this.delivery});

  final CompletedDelivery delivery;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final name = delivery.merchantName?.trim();
    final area = delivery.deliveryAreaName?.trim();
    final fee = delivery.deliveryFeeFils;
    final secondary = theme.textTheme.bodySmall?.copyWith(
      color: AppColor.textSecondary,
    );

    return MergeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.divider),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 24,
                color: AppColor.success,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name == null || name.isEmpty
                          ? l10n.completedDeliveryOutcome
                          : name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (area != null && area.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.offerDeliveryAreaLine(area),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    if (fee != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.completedDeliveryFeeLine(
                          ltrIsolate(formatJodFils(fee)),
                          l10n.walletCurrencySymbol,
                        ),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      l10n.completedDeliveryOutcome,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColor.success,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ltrIsolate(formatLocalDateTime(delivery.deliveredAt)),
                      style: secondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
