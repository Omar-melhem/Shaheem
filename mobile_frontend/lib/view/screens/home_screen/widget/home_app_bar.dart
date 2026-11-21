// Home AppBar: greeting, wallet balance and availability (D-A71).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/util/responsive/app_breakpoints.dart';
import 'package:mobile_frontend/util/routes/routes_string.dart';
import 'package:mobile_frontend/view/screens/home_screen/widget/home_availability_bar.dart';
import 'package:mobile_frontend/view/screens/home_screen/widget/home_greeting.dart';
import 'package:mobile_frontend/view/screens/home_screen/widget/wallet_balance_chip.dart';

/// The Home AppBar (client revision, D-A71), following the hierarchy of the
/// client's reference image without its logo or patterned header:
///
/// 1. **First row:** the personalized greeting ([HomeGreeting]) at the
///    reading start, and the wallet balance chip ([WalletBalanceChip],
///    opening the Wallet tab) at the end. When both don't fit (narrow
///    screen, long name, large text) the chip moves under the greeting
///    instead of being dropped or truncated.
/// 2. **Second row:** the controlled availability switch and its status,
///    with any notice underneath ([HomeAvailabilityBar]).
///
/// There is no Profile button: Profile is the «حسابي» tab (D-A70). The
/// «الرئيسية» title is not drawn (the greeting replaces it visually) but is
/// kept as a screen-reader header.
///
/// **Adaptive height:** Material's `AppBar` needs a fixed preferred height,
/// which cannot fit a wrapping greeting plus a variable notice, so this is
/// a content-sized app bar placed above the scrollable body. It grows with
/// its content (narrow widths, text scale up to 3, error or rationale
/// text) and only becomes internally scrollable beyond [maxHeightFraction]
/// of the page's available height, so nothing is ever hidden and the body
/// never overflows. White surface, light bottom
/// divider, and the top safe area applied here once.
class HomeAppBar extends StatelessWidget {
  const HomeAppBar({
    super.key,
    required this.walletBalanceFils,
    required this.availableHeight,
  });

  /// Total wallet balance in integer fils from the single authoritative
  /// wallet source (the same value the Wallet tab shows). Null shows «—».
  final int? walletBalanceFils;

  /// The height the Home page actually has for the bar and the body (the
  /// Scaffold body's constraint, which already excludes the navigation bar
  /// and anything mounted above the app). The bar is capped at
  /// [maxHeightFraction] of it, so the offers below always keep room.
  final double availableHeight;

  /// The largest share of [availableHeight] the bar may take before its
  /// content scrolls inside it.
  static const double maxHeightFraction = 0.6;

  /// Key of the bar's surface, for tests.
  static const Key surfaceKey = Key('home-app-bar');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // The same side padding as the body, so the bar and the offer cards
    // share one content edge.
    final side = AppBreakpoints.screenPadding(context);
    final chip = WalletBalanceChip(
      balanceFils: walletBalanceFils,
      // The same canonical route as the Wallet tab: switches to that
      // branch instead of stacking a second Wallet page.
      onPressed: () => context.go(RoutesString.wallet),
    );

    return Material(
      key: surfaceKey,
      color: AppColor.background,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColor.divider)),
        ),
        child: SafeArea(
          bottom: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: availableHeight * maxHeightFraction,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsetsDirectional.fromSTEB(side, 12, side, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    label: l10n.homeTitle,
                    child: const SizedBox.shrink(),
                  ),
                  // A Wrap keeps the greeting first and moves the chip to
                  // its own run when they cannot share one line.
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [const HomeGreeting(), chip],
                  ),
                  const SizedBox(height: 8),
                  const HomeAvailabilityBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
