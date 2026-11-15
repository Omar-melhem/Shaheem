// Home app bar: the read-only total wallet balance chip.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/helper/money/jod_format.dart';
import 'package:mobile_frontend/helper/translation/generated/app_localizations.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

/// Read-only total wallet balance (no action until a Wallet route exists).
class WalletBalanceChip extends StatelessWidget {
  const WalletBalanceChip({super.key, required this.totalFils});

  final int? totalFils;

  static const double iconSize = 20;
  static const double gap = 6;
  static const double horizontalPadding = 12;
  static const double verticalPadding = 6;

  static TextStyle textStyle(ThemeData theme) => theme.textTheme.titleSmall!
      .copyWith(color: AppColor.textPrimary, fontWeight: FontWeight.bold);

  /// The visible text: the LTR-isolated amount and the currency, or «—».
  static String visibleText(AppLocalizations l10n, int? fils) => fils == null
      ? l10n.walletBalanceUnknownValue
      : '${ltrIsolate(formatJodFils(fils))} ${l10n.walletCurrencySymbol}';

  /// Width of the chip on one line.
  static double naturalWidth(BuildContext context, int? fils) =>
      _singleLineWidth(
        visibleText(context.l10n, fils),
        textStyle(Theme.of(context)),
        MediaQuery.textScalerOf(context),
      ) +
      iconSize +
      gap +
      2 * horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final fils = totalFils;

    return Semantics(
      container: true,
      label: fils == null
          ? l10n.walletBalanceUnavailableSemantics
          : l10n.walletBalanceSemantics(formatJodFils(fils)),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColor.border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIconsRegular.wallet,
                size: iconSize,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: gap),
              Flexible(
                // Wraps only at the space between amount and currency.
                child: Text(visibleText(l10n, fils), style: textStyle(theme)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Width of [text] on one line (the chip decides whether it fits).
double _singleLineWidth(String text, TextStyle style, TextScaler scaler) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.rtl,
    textScaler: scaler,
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}
