// Order History: one offer this captain declined.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/domain/entities/declined_offer.dart';
import 'package:mobile_frontend/domain/entities/order_offer.dart';
import 'package:mobile_frontend/helper/date/date_time_format.dart';
import 'package:mobile_frontend/helper/money/jod_format.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';

/// Presentation only: the merchant (or a generic «عرض طلب»), the offer type
/// when the server sent it, «رفضتَ هذا العرض» and the server's time.
///
/// Worded as this captain's answer to an offer, never as a delivery or a
/// cancelled order. Read as one item by screen readers; not tappable.
class DeclinedOfferTile extends StatelessWidget {
  const DeclinedOfferTile({super.key, required this.record});

  final DeclinedOfferRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final name = record.merchantName?.trim().isNotEmpty ?? false
        ? record.merchantName!
        : l10n.declinedOfferGenericTitle;
    final kind = switch (record.kind) {
      OrderOfferKind.instant => l10n.offerKindInstant,
      OrderOfferKind.scheduled => l10n.offerKindScheduled,
      null => null,
    };
    final at = record.declinedAt;
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
              Icon(
                Icons.do_not_disturb_on_outlined,
                size: 24,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      kind == null
                          ? l10n.declinedOfferOutcome
                          : l10n.declinedOfferOutcomeWithKind(kind),
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (at != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        ltrIsolate(formatLocalDateTime(at)),
                        style: secondary,
                      ),
                    ],
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
