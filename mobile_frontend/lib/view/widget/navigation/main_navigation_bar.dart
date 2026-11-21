// The visual main navigation bar: four equal destinations (D-A70).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/theme/text_themes.dart';
import 'package:mobile_frontend/view/widget/navigation/main_nav_destination.dart';

/// Bottom navigation bar for the main shell.
///
/// Presentation only. It knows nothing about routes, GoRouter or feature
/// state: the shell (`AppNavBar`) passes [selectedIndex] from the router and
/// handles [onDestinationSelected]. There are no indicator inputs: the
/// notification feed was removed (D-A72) and Current Order is a standalone
/// page, not a tab (D-A73).
///
/// Layout: the [MainNavDestination] items share the width equally in
/// reading order (Home is on the right in Arabic). The bottom safe-area
/// inset is applied here, once.
///
/// Look (D-A69): white surface with a light top divider. The selected item
/// has a dark Fill icon, a bold dark label and a neutral pill behind the
/// icon (a second cue beyond color); unselected items use medium gray
/// Regular icons and labels. Selection is never red.
///
/// Text: labels keep their size. When a label doesn't fit on one line (a
/// narrow screen or larger accessibility text), all labels get two lines
/// and the bar grows taller instead of shrinking the text. Text scaling is
/// honored up to [maxTextScale].
class MainNavigationBar extends StatelessWidget {
  const MainNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  }) : assert(
         selectedIndex >= 0,
         'MainNavigationBar: selectedIndex must be a MainNavDestination index '
         '(0 or more); pass the shell\'s currentIndex.',
       );

  /// Index into [MainNavDestination.values] of the open destination.
  /// Asserted to be in range: an invalid index would silently show no
  /// destination as selected.
  final int selectedIndex;

  /// Called with the tapped destination's index (also when it is already
  /// selected; the shell decides what that means).
  final ValueChanged<int> onDestinationSelected;

  /// Minimum height of the bar surface, without the safe-area inset. It
  /// grows when labels need two lines or text is scaled up.
  static const double barHeight = 64;

  /// Content width cap, so items don't drift apart on tablets and desktops.
  static const double maxContentWidth = 640;

  /// Largest text scale applied inside the bar. Beyond it a fixed bottom
  /// bar would take too much of the screen.
  static const double maxTextScale = 2;

  // Keys for widget tests.
  static const Key surfaceKey = Key('main-nav-surface');

  /// Key of the tappable item for [destination].
  static Key itemKey(MainNavDestination destination) =>
      ValueKey('main-nav-item-${destination.name}');

  /// Key of the neutral selection pill behind [destination]'s icon.
  static Key indicatorKey(MainNavDestination destination) =>
      ValueKey('main-nav-indicator-${destination.name}');

  @override
  Widget build(BuildContext context) {
    // The upper bound needs the enum's length, so it is checked here.
    assert(
      selectedIndex < MainNavDestination.values.length,
      'MainNavigationBar: selectedIndex $selectedIndex is out of range '
      '(${MainNavDestination.values.length} destinations); pass the shell\'s '
      'currentIndex.',
    );
    final l10n = context.l10n;
    final media = MediaQuery.of(context);
    final scaler = media.textScaler.clamp(maxScaleFactor: maxTextScale);
    final labels = [for (final d in MainNavDestination.values) d.label(l10n)];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Width one label really gets: an equal share of the content row.
        final contentWidth = math.min(
          constraints.maxWidth - media.padding.horizontal,
          maxContentWidth,
        );
        final metrics = _BarMetrics.measure(
          labels: labels,
          labelWidth: contentWidth / labels.length - 2 * _labelSidePadding,
          scaler: scaler,
          direction: Directionality.of(context),
        );

        return Semantics(
          container: true,
          explicitChildNodes: true,
          label: l10n.mainNavigationLabel,
          child: MediaQuery(
            data: media.copyWith(textScaler: scaler),
            child: Material(
              type: MaterialType.transparency,
              child: DecoratedBox(
                key: surfaceKey,
                // The surface also fills the bottom safe area, so nothing
                // shows through under the system navigation.
                decoration: const BoxDecoration(
                  color: AppColor.surface,
                  border: Border(top: BorderSide(color: AppColor.divider)),
                ),
                child: SafeArea(
                  top: false,
                  // heightFactor 1: as a Scaffold's bottomNavigationBar the
                  // bar receives the whole screen height; it must take
                  // only its own height.
                  child: Center(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: maxContentWidth,
                      ),
                      child: SizedBox(
                        height: metrics.itemHeight,
                        // Row follows Directionality: nothing is reversed
                        // by hand.
                        child: Row(
                          children: [
                            for (final d in MainNavDestination.values)
                              Expanded(
                                child: _Item(
                                  key: itemKey(d),
                                  destination: d,
                                  metrics: metrics,
                                  selected: selectedIndex == d.index,
                                  onTap: () => onDestinationSelected(d.index),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Vertical rhythm shared by all items, top to bottom:
// [_edgeGap] icon pill [_iconLabelGap] label [_edgeGap].
const double _edgeGap = 8;
const double _iconBox = 28;
const double _pillWidth = 56;
const double _iconLabelGap = 4;
const double _labelSidePadding = 2;

/// Sizes that depend on the available width and the text scale.
class _BarMetrics {
  const _BarMetrics({
    required this.labelLines,
    required this.labelHeight,
    required this.itemHeight,
  });

  /// 1, or 2 when at least one label doesn't fit on a single line.
  final int labelLines;

  /// Height reserved for the label block.
  final double labelHeight;

  /// Height of an item, which is also the bar surface's height.
  final double itemHeight;

  static TextStyle labelStyle({required bool selected, Color? color}) =>
      TextThemeStyle.subtitle2.copyWith(
        color: color,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
      );

  /// Measures every label at its widest (bold) weight. All items use the
  /// same number of lines so icons and labels stay aligned across the bar.
  static _BarMetrics measure({
    required List<String> labels,
    required double labelWidth,
    required TextScaler scaler,
    required TextDirection direction,
  }) {
    final style = labelStyle(selected: true);
    var lines = 1;
    for (final label in labels) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final fits = painter.width <= labelWidth;
      painter.dispose();
      if (!fits) {
        lines = 2;
        break;
      }
    }
    final lineHeight = scaler.scale(style.fontSize!) * style.height!;
    final labelHeight = (lines * lineHeight).ceilToDouble();
    return _BarMetrics(
      labelLines: lines,
      labelHeight: labelHeight,
      itemHeight: math.max(
        MainNavigationBar.barHeight,
        _edgeGap + _iconBox + _iconLabelGap + labelHeight + _edgeGap,
      ),
    );
  }
}

/// One destination: icon (in a neutral pill when selected) with its label
/// below. The whole item is the touch target (at least 48×48).
class _Item extends StatelessWidget {
  const _Item({
    super.key,
    required this.destination,
    required this.metrics,
    required this.selected,
    required this.onTap,
  });

  final MainNavDestination destination;
  final _BarMetrics metrics;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = selected ? AppColor.navSelected : AppColor.navUnselected;

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: destination.label(l10n),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: _edgeGap,
              horizontal: _labelSidePadding,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // The pill is always laid out (transparent when not
                // selected) so selecting an item never shifts anything.
                Container(
                  key: MainNavigationBar.indicatorKey(destination),
                  width: _pillWidth,
                  height: _iconBox,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColor.selectedTabContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(_iconBox / 2),
                  ),
                  child: Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    size: 24,
                    color: color,
                  ),
                ),
                const SizedBox(height: _iconLabelGap),
                SizedBox(
                  height: metrics.labelHeight,
                  child: Text(
                    destination.label(l10n),
                    textAlign: TextAlign.center,
                    maxLines: metrics.labelLines,
                    overflow: TextOverflow.ellipsis,
                    style: _BarMetrics.labelStyle(
                      selected: selected,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
