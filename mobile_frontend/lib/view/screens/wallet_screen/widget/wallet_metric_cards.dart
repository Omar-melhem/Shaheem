// Wallet: the two lifetime metric cards (delivered orders, earnings).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/helper/money/jod_format.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/view/screens/wallet_screen/cubit/wallet_cubit.dart';
import 'package:mobile_frontend/view/widget/buttons/app_text_button.dart';

/// Exactly two cards (D-A76): **delivered orders** and **earnings**, both
/// lifetime totals since the captain started work, from the statistics
/// read of [WalletCubit] (never counted from the debit list, a page,
/// pending or declined offers).
///
/// Side by side when they fit; stacked on narrow screens or large text.
/// While loading, unavailable, not configured or failed, each card shows
/// «—» with a line that says why — never a zero. Earnings stay
/// "unavailable" until the owner decides the formula (D-P36) and a source
/// supplies it. A statistics failure has its own Retry and never touches
/// the balance.
class WalletMetricCards extends StatelessWidget {
  const WalletMetricCards({super.key});

  /// Below this width per card the two cards are stacked.
  static const double minCardWidth = 160;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<WalletCubit>().state;
    final stats = state.statistics;
    final status = state.statisticsStatus;

    final reason = switch (status) {
      WalletStatus.initial || WalletStatus.loading => l10n.walletLoading,
      WalletStatus.notConfigured => l10n.walletMetricsNotConfigured,
      WalletStatus.noInternet => l10n.walletNoInternet,
      WalletStatus.failure => l10n.walletMetricsLoadFailed,
      WalletStatus.noSession => l10n.walletNoSession,
      WalletStatus.loaded => null,
    };
    final delivered = stats == null
        ? null
        : ltrIsolate('${stats.deliveredCount}');
    final earningsFils = stats?.earningsFils;
    final earnings = earningsFils == null
        ? null
        : '${ltrIsolate(formatJodFils(earningsFils))} '
              '${l10n.walletCurrencySymbol}';

    final cards = [
      _MetricCard(
        icon: Icons.inventory_2_outlined,
        label: l10n.walletDeliveredCount,
        value: delivered,
        note: delivered == null ? reason : l10n.walletMetricsLifetimeNote,
      ),
      _MetricCard(
        icon: Icons.trending_up,
        label: l10n.walletEarnings,
        value: earnings,
        // A loaded answer without earnings: the formula is not decided.
        note: earnings == null
            ? (reason ?? l10n.walletEarningsUnavailable)
            : l10n.walletMetricsLifetimeNote,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final scale = MediaQuery.textScalerOf(context).scale(1);
            final sideBySide =
                constraints.maxWidth / 2 >= minCardWidth * scale.clamp(1, 3);
            if (!sideBySide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [cards[0], const SizedBox(height: 12), cards[1]],
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[1]),
                ],
              ),
            );
          },
        ),
        if (state.canRetryStatistics)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppTextButton(
              label: l10n.retry,
              onPressed: () =>
                  unawaited(context.read<WalletCubit>().retryStatistics()),
            ),
          ),
      ],
    );
  }
}

/// One metric: icon, label, value (or «—») and an explanatory note.
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.note,
  });

  final IconData icon;
  final String label;

  /// Formatted value; null when unknown.
  final String? value;

  /// Why the value is missing, or the lifetime period note.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final shown = value ?? l10n.walletBalanceUnknownValue;
    final spoken = value == null ? l10n.walletValueUnknownSemantics : shown;
    return Semantics(
      container: true,
      label: [label, spoken, ?note].join('. '),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.divider),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 22, color: theme.colorScheme.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                shown,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColor.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (note != null) ...[
                const SizedBox(height: 4),
                Text(
                  note!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColor.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
