// Home app bar: title (when it fits) and the wallet total.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/util/responsive/app_breakpoints.dart';
import 'package:mobile_frontend/view/screens/home_screen/widget/wallet_balance_chip.dart';

/// App bar: title (only when it fits beside the balance) and the wallet
/// total. Grows with the text scale so the balance is never clipped.
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({
    super.key,
    required this.walletTotalFils,
    required this.height,
  });

  final int? walletTotalFils;

  /// Toolbar height from [heightFor]. The Scaffold sizes the app bar from
  /// [preferredSize], which has no context, so the caller passes it.
  final double height;

  static const double _verticalPadding = 8;

  /// At least the standard toolbar height, taller when the text scale
  /// needs it: room for two lines of balance text (amount and currency may
  /// wrap onto separate lines on narrow screens with large text).
  static double heightFor(BuildContext context) {
    final chipStyle = WalletBalanceChip.textStyle(Theme.of(context));
    final line =
        MediaQuery.textScalerOf(context).scale(chipStyle.fontSize!) * 1.5;
    return math.max(
      kToolbarHeight,
      2 * line + 2 * WalletBalanceChip.verticalPadding + 2 * _verticalPadding,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final titleStyle =
        theme.appBarTheme.titleTextStyle ?? theme.textTheme.titleLarge!;

    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: false,
      toolbarHeight: height,
      titleSpacing: AppBreakpoints.screenPadding(context),
      title: LayoutBuilder(
        builder: (context, constraints) {
          final chip = WalletBalanceChip(totalFils: walletTotalFils);
          final titleWidth = _textWidth(l10n.homeTitle, titleStyle, scaler);
          final chipWidth = WalletBalanceChip.naturalWidth(
            context,
            walletTotalFils,
          );
          final titleFits = titleWidth + 16 + chipWidth <= constraints.maxWidth;
          return Row(
            children: [
              if (titleFits)
                Text(l10n.homeTitle, style: titleStyle, maxLines: 1)
              else
                // Kept for screen readers when there is no room to show it.
                Semantics(
                  header: true,
                  label: l10n.homeTitle,
                  child: const SizedBox.shrink(),
                ),
              const Spacer(),
              Flexible(flex: 0, child: chip),
            ],
          );
        },
      ),
    );
  }

  static double _textWidth(String text, TextStyle style, TextScaler scaler) {
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
}
