// The app's single source of truth for responsive breakpoints.

import 'package:flutter/widgets.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// Breakpoints used by `responsive_framework`, registered once in
/// `MainApp` via `ResponsiveBreakpoints.builder`. Never redefine them in
/// screens; read the current one with `ResponsiveBreakpoints.of(context)`
/// or the helpers below.
///
/// The package matches `start <= width <= end` and the FIRST matching entry
/// wins. Each range therefore starts at the previous range's end: a width
/// of exactly 450 is MOBILE, 450.5 is TABLET — no gaps, no ambiguity. In
/// whole logical pixels this is 0–450 / 451–800 / 801–1920 / 1921+.
abstract final class AppBreakpoints {
  /// Name of the large-screen breakpoint (the package has no constant).
  static const String fourK = '4K';

  static const List<Breakpoint> all = [
    Breakpoint(start: 0, end: 450, name: MOBILE),
    Breakpoint(start: 450, end: 800, name: TABLET),
    Breakpoint(start: 800, end: 1920, name: DESKTOP),
    Breakpoint(start: 1920, end: double.infinity, name: fourK),
  ];

  /// Maximum width for forms and single-column content (Login, messages).
  ///
  /// Note: `responsive_framework` measures the screen after the first frame
  /// and then rebuilds. During that first frame no breakpoint is active, so
  /// this returns the desktop cap (520) — harmless, as it is wider than any
  /// phone, and corrected one frame later.
  ///
  /// Mobile uses the full width (minus screen padding); larger screens keep
  /// the form at a comfortable reading width instead of stretching it.
  static double formMaxWidth(BuildContext context) {
    final breakpoints = ResponsiveBreakpoints.of(context);
    if (breakpoints.isMobile) return double.infinity;
    if (breakpoints.isTablet) return 480;
    return 520;
  }

  /// Horizontal screen padding: tighter on phones, roomier on larger screens.
  static double screenPadding(BuildContext context) =>
      ResponsiveBreakpoints.of(context).isMobile ? 20 : 32;
}
