// The five primary destinations of the main navigation bar.

import 'package:flutter/widgets.dart';
import 'package:mobile_frontend/helper/translation/generated/app_localizations.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

/// Primary destinations, in their logical (reading) order.
///
/// The enum index is the branch index of the `StatefulShellRoute` in
/// `go_router.dart`, so the order here, the branch order there and
/// `mainShellRoutes` must stay identical. [currentOrder] is the emphasized
/// central item: the captain's shortcut to their active order and its
/// pickup map. It never creates an order, so it must never use a plus icon.
///
/// This type only describes presentation (icon and label). Routes live in
/// the router, never here.
enum MainNavDestination {
  home,
  notifications,
  currentOrder,
  orderHistory,
  profile;

  /// Icon while the destination is not selected (Phosphor Regular).
  IconData get icon => switch (this) {
    home => PhosphorIconsRegular.house,
    notifications => PhosphorIconsRegular.bell,
    currentOrder => PhosphorIconsRegular.mapPin,
    orderHistory => PhosphorIconsRegular.clockCounterClockwise,
    profile => PhosphorIconsRegular.userCircle,
  };

  /// Icon while the destination is selected: the Fill version of the same
  /// glyph, so selection is visible by shape and not by color alone.
  IconData get selectedIcon => switch (this) {
    home => PhosphorIconsFill.house,
    notifications => PhosphorIconsFill.bell,
    currentOrder => PhosphorIconsFill.mapPin,
    orderHistory => PhosphorIconsFill.clockCounterClockwise,
    profile => PhosphorIconsFill.userCircle,
  };

  /// Localized label, shared with the destination's screen title.
  String label(AppLocalizations l10n) => switch (this) {
    home => l10n.homeTitle,
    notifications => l10n.notificationsTitle,
    currentOrder => l10n.currentOrderTitle,
    orderHistory => l10n.orderHistoryTitle,
    profile => l10n.profileTitle,
  };
}
