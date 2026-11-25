// Home AppBar: greeting, Home emblem and availability (D-A71, D-A82).

import 'package:flutter/material.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/util/images.dart';
import 'package:mobile_frontend/util/responsive/app_breakpoints.dart';
import 'package:mobile_frontend/view/screens/home_screen/widget/home_availability_bar.dart';
import 'package:mobile_frontend/view/screens/home_screen/widget/home_greeting.dart';

/// The Home AppBar (D-A71, revised by D-A82):
///
/// 1. **First row:** the greeting with the captain's first name
///    ([HomeGreeting]) at the reading start, and the owner-provided emblem
///    ([AppImages.homeLogo]) at the logical end. The emblem is decorative
///    branding with no action: the former wallet shortcut was removed
///    (D-A82; Wallet is its own tab). It has bounded size and `BoxFit.contain`,
///    so the whole emblem shows without stretching or clipping, and it
///    reads no data. On a narrow screen or at large text the emblem moves
///    under the greeting instead of squeezing it.
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
  const HomeAppBar({super.key, required this.availableHeight});

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

  /// Key of the Home emblem, for tests.
  static const Key logoKey = Key('home-app-bar-logo');

  /// Height of the Home emblem; its width follows the asset's aspect ratio.
  static const double logoHeight = 44;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // The same side padding as the body, so the bar and the offer cards
    // share one content edge.
    final side = AppBreakpoints.screenPadding(context);
    // One announcement for the emblem (no duplicate text label).
    final logo = Image.asset(
      AppImages.homeLogo,
      key: logoKey,
      height: logoHeight,
      fit: BoxFit.contain,
      semanticLabel: l10n.homeLogoSemantics,
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
                  // A Wrap keeps the greeting first and moves the emblem to
                  // its own run when they cannot share one line.
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [const HomeGreeting(), logo],
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
