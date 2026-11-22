// Current Order, delivery leg: the optional customer phone (D-A81).

import 'package:flutter/material.dart';
import 'package:mobile_frontend/helper/money/jod_format.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

/// Shows the customer phone the merchant supplied, LTR-isolated inside the
/// RTL page and selectable so the captain can call it outside SHAHM.
///
/// The phone is **optional**: callers build this card only when
/// `ActiveOrder.contactPhone` is non-null (a null, empty or blank phone
/// shows nothing — no empty card, no disabled call button, no invented
/// number). The app never records or requires that a call happened.
class CustomerContactCard extends StatelessWidget {
  const CustomerContactCard({super.key, required this.phone});

  /// A non-blank phone from the authoritative order.
  final String phone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: l10n.customerPhoneSemantics(phone),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.divider),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(
                PhosphorIconsRegular.phone,
                size: 24,
                color: AppColor.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.customerPhoneHeading,
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColor.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      ltrIsolate(phone),
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColor.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
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
