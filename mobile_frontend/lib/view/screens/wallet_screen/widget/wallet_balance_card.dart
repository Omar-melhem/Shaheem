// Wallet: the single balance, shown prominently (D-A74).

import 'package:flutter/material.dart';
import 'package:mobile_frontend/domain/entities/wallet.dart';
import 'package:mobile_frontend/helper/money/jod_format.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';

/// The server's single wallet balance, or «—» when [summary] is null (not
/// loaded, not configured, failed). Never a calculated or zero stand-in;
/// negative values keep their sign and a balance above the 5.000 JOD
/// recharge ceiling is shown exactly as reported (D-A75 is enforced by the
/// server on new credits, never by clamping here). There are no held or
/// "available" amounts (D-A74).
class WalletBalanceCard extends StatelessWidget {
  const WalletBalanceCard({super.key, required this.summary});

  /// The server's balance; null when unknown.
  final WalletSummary? summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final fils = summary?.balanceFils;
    final (String visible, String spoken) = fils == null
        ? (l10n.walletBalanceUnknownValue, l10n.walletValueUnknownSemantics)
        : (
            '${ltrIsolate(formatJodFils(fils))} ${l10n.walletCurrencySymbol}',
            '${formatJodFils(fils)} ${l10n.walletCurrencySymbol}',
          );

    return Semantics(
      container: true,
      label: l10n.walletBalanceCardSemantics(spoken),
      excludeSemantics: true,
      child: DecoratedBox(
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
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 24,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.walletTotalBalance,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                visible,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColor.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
