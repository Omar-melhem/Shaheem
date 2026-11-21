// The four primary destinations of the main navigation bar (D-A70).

import 'package:flutter/widgets.dart';
import 'package:mobile_frontend/helper/translation/generated/app_localizations.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

/// Primary destinations, in their logical (reading) order: in Arabic, Home
/// is on the right and My Account on the left.
///
/// The enum index is the branch index of the `StatefulShellRoute` in
/// `go_router.dart`, so the order here, the branch order there and
/// `mainShellRoutes` must stay identical. Nothing may assume a particular
/// count or a central item: Current Order is a standalone page (D-A73) and
/// the Notifications feed was removed (D-A72).
///
/// This type only describes presentation (icon and label). Routes live in
/// the router, never here.
enum MainNavDestination {
  /// «الرئيسية»: greeting, availability and pending offers.
  home,

  /// «طلباتي»: the existing Order History feature.
  orderHistory,

  /// «المحفظة»: balance, delivery statistics and commission debits.
  wallet,

  /// «حسابي»: the captain's profile, Settings, Terms and About.
  profile;

  /// Icon while the destination is not selected (Phosphor Regular).
  IconData get icon => switch (this) {
    home => PhosphorIconsRegular.house,
    orderHistory => PhosphorIconsRegular.clipboardText,
    wallet => PhosphorIconsRegular.wallet,
    profile => PhosphorIconsRegular.user,
  };

  /// Icon while the destination is selected: the Fill version of the same
  /// glyph, so selection is visible by shape and not by color alone.
  IconData get selectedIcon => switch (this) {
    home => PhosphorIconsFill.house,
    orderHistory => PhosphorIconsFill.clipboardText,
    wallet => PhosphorIconsFill.wallet,
    profile => PhosphorIconsFill.user,
  };

  /// Localized label, shared with the destination's screen title.
  String label(AppLocalizations l10n) => switch (this) {
    home => l10n.homeTitle,
    orderHistory => l10n.orderHistoryTitle,
    wallet => l10n.walletTitle,
    profile => l10n.profileTitle,
  };
}
