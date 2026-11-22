// Wallet: one card per commission-debit history entry (D-A76; the captain
// UI lists no recharge credits).

import 'package:flutter/material.dart';
import 'package:mobile_frontend/domain/entities/wallet.dart';
import 'package:mobile_frontend/helper/date/date_time_format.dart';
import 'package:mobile_frontend/helper/money/jod_format.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';

/// A final commission debit: merchant, delivery area, date and time, and
/// the commission (never the delivery fee). Missing merchant or area show
/// «غير متوفر»; nothing is invented. Read-only; full width, content height.
class WalletDebitCard extends StatelessWidget {
  const WalletDebitCard({super.key, required this.debit});

  final WalletCommissionDebit debit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String orUnavailable(String? value) => value == null || value.trim().isEmpty
        ? l10n.walletFieldUnavailable
        : value;
    final merchant = orUnavailable(debit.merchantName);
    final area = orUnavailable(debit.deliveryAreaName);
    final amount = formatJodFils(debit.commissionFils);
    final date = formatLocalDateTime(debit.debitedAt);
    return _EntryFrame(
      semanticsLabel: l10n.walletDebitSemantics(amount, merchant, area, date),
      children: [
        _EntryLine(
          icon: Icons.storefront_outlined,
          text: l10n.walletDebitMerchantLine(merchant),
          emphasized: true,
        ),
        const SizedBox(height: 14),
        _EntryLine(
          icon: Icons.flag_outlined,
          text: l10n.offerDeliveryAreaLine(area),
        ),
        const SizedBox(height: 10),
        _EntryLine(
          icon: Icons.event_outlined,
          text: l10n.walletDebitDateLine(ltrIsolate(date)),
        ),
        const SizedBox(height: 10),
        _EntryLine(
          icon: Icons.payments_outlined,
          text: l10n.walletDebitAmountLine(
            ltrIsolate(amount),
            l10n.walletCurrencySymbol,
          ),
        ),
      ],
    );
  }
}

/// The card frame, with one screen-reader summary.
class _EntryFrame extends StatelessWidget {
  const _EntryFrame({required this.semanticsLabel, required this.children});

  final String semanticsLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: semanticsLabel,
    excludeSemantics: true,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  );
}

/// A decorative icon at the logical start of a line that wraps beside it.
class _EntryLine extends StatelessWidget {
  const _EntryLine({
    required this.icon,
    required this.text,
    this.emphasized = false,
  });

  final IconData icon;
  final String text;

  /// Bold title style (the debit's merchant line).
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: emphasized ? 24 : 22,
          color: theme.colorScheme.secondary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: emphasized
                ? theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )
                : theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
