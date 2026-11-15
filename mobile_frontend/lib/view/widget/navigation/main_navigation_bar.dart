// The visual main navigation bar: five destinations with a raised central
// Current Order button.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/theme/text_themes.dart';
import 'package:mobile_frontend/view/widget/navigation/main_nav_destination.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

/// Bottom navigation bar for the main shell.
///
/// Presentation only. It knows nothing about routes, GoRouter or feature
/// state: the shell (`AppNavBar`) passes [selectedIndex] from the router and
/// handles [onDestinationSelected]; the indicators are plain inputs.
///
/// - [unreadCount] > 0 shows a small dot on Notifications.
/// - [hasActiveOrder] changes the central button's background and adds a
///   badge. It is independent of selection: the central button can be
///   selected, have an active order, both or neither.
/// - [isCheckingActiveOrder] shows a small spinner in the central button
///   instead of its icon; the button keeps its size.
///
/// Layout: the five items share the width equally in reading order (Home
/// is on the right in Arabic), so the third item is always centered. The
/// central circle rises [centerButtonRise] above the bar surface; that
/// strip is part of this widget's height, so the whole circle stays
/// tappable and never overlaps page content. The bottom safe-area inset is
/// applied here, once.
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
    this.unreadCount = 0,
    this.hasActiveOrder = false,
    this.isCheckingActiveOrder = false,
  }) : assert(
         selectedIndex >= 0,
         'MainNavigationBar: selectedIndex must be a MainNavDestination index '
         '(0 or more); pass the shell\'s currentIndex.',
       ),
       assert(
         unreadCount >= 0,
         'MainNavigationBar: unreadCount must not be negative; pass 0 when '
         'there is nothing unread.',
       );

  /// Index into [MainNavDestination.values] of the open destination.
  /// Asserted to be in range: an invalid index would silently show no
  /// destination as selected.
  final int selectedIndex;

  /// Called with the tapped destination's index (also when it is already
  /// selected; the shell decides what that means).
  final ValueChanged<int> onDestinationSelected;

  /// Number of unread notifications, supplied by the caller (0 by default;
  /// the shell does not pass one yet). Only "zero or not" is shown; a
  /// negative value asserts.
  final int unreadCount;

  /// Whether the server reports an active order.
  final bool hasActiveOrder;

  /// Whether the active order is being looked up right now.
  final bool isCheckingActiveOrder;

  /// Minimum height of the bar surface, without the safe-area inset. It
  /// grows when labels need two lines or text is scaled up.
  static const double barHeight = 64;

  /// Diameter of the central circular button.
  static const double centerButtonSize = 56;

  /// How far the central button rises above the bar surface.
  static const double centerButtonRise = 20;

  /// Content width cap, so items don't drift apart on tablets and desktops.
  static const double maxContentWidth = 640;

  /// Largest text scale applied inside the bar. Beyond it a fixed bottom
  /// bar would take too much of the screen.
  static const double maxTextScale = 2;

  // Keys for widget tests.
  static const Key surfaceKey = Key('main-nav-surface');
  static const Key centerButtonKey = Key('main-nav-center-button');
  static const Key centerProgressKey = Key('main-nav-center-progress');
  static const Key notificationDotKey = Key('main-nav-notification-dot');
  static const Key activeOrderBadgeKey = Key('main-nav-active-order-badge');

  /// Key of the tappable item for [destination].
  static Key itemKey(MainNavDestination destination) =>
      ValueKey('main-nav-item-${destination.name}');

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
    final colors = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final scaler = media.textScaler.clamp(maxScaleFactor: maxTextScale);
    final labels = [for (final d in MainNavDestination.values) d.label(l10n)];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Width one label really gets: an equal fifth of the content row.
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
              child: SizedBox(
                // The only place the bottom inset is added.
                height:
                    centerButtonRise +
                    metrics.itemHeight +
                    media.padding.bottom,
                child: Stack(
                  children: [
                    // Bar surface. It also fills the bottom safe area, so
                    // nothing shows through under the system navigation.
                    PositionedDirectional(
                      top: centerButtonRise,
                      start: 0,
                      end: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        key: surfaceKey,
                        decoration: BoxDecoration(
                          color: colors.surface,
                          border: Border(
                            top: BorderSide(color: colors.outline),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: SafeArea(
                        top: false,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: maxContentWidth,
                            ),
                            // Row follows Directionality: nothing is
                            // reversed by hand.
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                for (final d in MainNavDestination.values)
                                  Expanded(child: _buildItem(d, metrics)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItem(MainNavDestination destination, _BarMetrics metrics) {
    final selected = selectedIndex == destination.index;
    void onTap() => onDestinationSelected(destination.index);

    if (destination == MainNavDestination.currentOrder) {
      return _CenterItem(
        key: itemKey(destination),
        metrics: metrics,
        selected: selected,
        hasActiveOrder: hasActiveOrder,
        isChecking: isCheckingActiveOrder,
        onTap: onTap,
      );
    }
    return _Item(
      key: itemKey(destination),
      destination: destination,
      metrics: metrics,
      selected: selected,
      showDot:
          destination == MainNavDestination.notifications && unreadCount > 0,
      onTap: onTap,
    );
  }
}

// Vertical rhythm shared by all five items, top to bottom:
// [_edgeGap] icon [_iconLabelGap] label [_edgeGap].
const double _edgeGap = 8;
const double _iconBox = 28;
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

  /// Height of a regular item, which is also the bar surface's height.
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

/// A regular destination: icon with its label below.
class _Item extends StatelessWidget {
  const _Item({
    super.key,
    required this.destination,
    required this.metrics,
    required this.selected,
    required this.showDot,
    required this.onTap,
  });

  final MainNavDestination destination;
  final _BarMetrics metrics;
  final bool selected;

  /// Shows the unread dot (Notifications only).
  final bool showDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final color = selected ? colors.primary : AppColor.textSecondary;

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: destination.label(l10n),
      // The dot is announced in words, not left as a colored mark.
      value: showDot ? l10n.navUnreadNotifications : null,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: metrics.itemHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox.square(
                dimension: _iconBox,
                // The dot is overlaid, so it never moves the icon or label.
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: PhosphorIcon(
                        selected ? destination.selectedIcon : destination.icon,
                        size: 24,
                        color: color,
                      ),
                    ),
                    if (showDot)
                      PositionedDirectional(
                        top: 0,
                        end: 0,
                        child: Container(
                          key: MainNavigationBar.notificationDotKey,
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            // Existing semantic error color; no new token.
                            color: colors.error,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.surface,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: _iconLabelGap),
              _Label(
                text: destination.label(l10n),
                selected: selected,
                metrics: metrics,
              ),
              const SizedBox(height: _edgeGap),
            ],
          ),
        ),
      ),
    );
  }
}

/// The central Current Order destination: a raised circle with its label.
class _CenterItem extends StatelessWidget {
  const _CenterItem({
    super.key,
    required this.metrics,
    required this.selected,
    required this.hasActiveOrder,
    required this.isChecking,
    required this.onTap,
  });

  final _BarMetrics metrics;

  /// The Current Order route is open (from the router).
  final bool selected;

  /// The server reports an active order (independent of [selected]).
  final bool hasActiveOrder;

  /// The active order is being looked up.
  final bool isChecking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    const destination = MainNavDestination.currentOrder;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: destination.label(l10n),
      // Says what a tap does: open the active order, not create one.
      hint: l10n.navCurrentOrderHint,
      value: isChecking
          ? l10n.navCheckingActiveOrder
          : (hasActiveOrder ? l10n.navActiveOrder : null),
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: metrics.itemHeight + MainNavigationBar.centerButtonRise,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Material animates color and border changes by itself;
                  // the animation is skipped when the user asked for less
                  // motion.
                  Material(
                    key: MainNavigationBar.centerButtonKey,
                    elevation: 4,
                    animationDuration: reduceMotion
                        ? Duration.zero
                        : kThemeChangeDuration,
                    // Active order: secondary instead of primary background.
                    color: hasActiveOrder ? colors.secondary : colors.primary,
                    // Selected: accent ring instead of a surface-colored one.
                    shape: CircleBorder(
                      side: BorderSide(
                        color: selected ? AppColor.sand : colors.surface,
                        width: 3,
                      ),
                    ),
                    child: SizedBox.square(
                      dimension: MainNavigationBar.centerButtonSize,
                      child: Center(
                        // The spinner replaces the icon inside the same
                        // circle, so the button's size never changes.
                        child: isChecking
                            ? SizedBox.square(
                                key: MainNavigationBar.centerProgressKey,
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: colors.onPrimary,
                                ),
                              )
                            : PhosphorIcon(
                                selected
                                    ? destination.selectedIcon
                                    : destination.icon,
                                size: 28,
                                color: colors.onPrimary,
                              ),
                      ),
                    ),
                  ),
                  // A badge as well, so an active order is never signalled
                  // by the background color alone. It sits above the
                  // circle (not inside it), so the ring can't cover it.
                  if (hasActiveOrder)
                    PositionedDirectional(
                      top: 0,
                      end: 0,
                      child: Container(
                        key: MainNavigationBar.activeOrderBadgeKey,
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: colors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.secondary),
                        ),
                        child: PhosphorIcon(
                          PhosphorIconsFill.package,
                          size: 12,
                          color: colors.secondary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: _iconLabelGap),
              _Label(
                text: destination.label(l10n),
                selected: selected,
                metrics: metrics,
              ),
              const SizedBox(height: _edgeGap),
            ],
          ),
        ),
      ),
    );
  }
}

/// Destination label at its real size: one line, or two when the bar
/// measured that a label needs them. Never scaled down.
class _Label extends StatelessWidget {
  const _Label({
    required this.text,
    required this.selected,
    required this.metrics,
  });

  final String text;
  final bool selected;
  final _BarMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: _labelSidePadding,
      ),
      child: SizedBox(
        height: metrics.labelHeight,
        // Top-aligned, so first lines share a baseline across the bar.
        child: Align(
          alignment: Alignment.topCenter,
          child: Text(
            text,
            maxLines: metrics.labelLines,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            // Selected: bold and primary; unselected: regular and muted.
            style: _BarMetrics.labelStyle(
              selected: selected,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : AppColor.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
