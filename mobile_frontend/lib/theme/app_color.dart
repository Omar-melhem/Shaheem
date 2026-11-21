import 'package:flutter/painting.dart';

/// SHAHM's single color palette (D-A69, client revision 2026-11-20): white
/// backgrounds, red primary actions and neutral text/navigation.
///
/// Every screen reads colors from here, usually through `ColorScheme` and
/// the component themes in `AppTheme`, so the owner can revise a shade in
/// one place. The exact hex values are an implementation selection for the
/// requested red/white direction (see `docs/ui/DESIGN_SYSTEM.md` §1 for the
/// contrast checks). There is no second brand palette.
class AppColor {
  AppColor._();

  // ── Brand red ──────────────────────────────────────────────────────────

  /// Prominent primary actions, including Accept (5.62:1 on white).
  static const Color primary = Color(0xFFC62828);

  /// Content drawn on [primary].
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Pressed state of a red action.
  static const Color primaryPressed = Color(0xFFA61B1B);

  /// Low-emphasis red tint for status/highlight backgrounds.
  static const Color primaryContainer = Color(0xFFFDECEC);

  /// Text and icons on [primaryContainer].
  static const Color onPrimaryContainer = Color(0xFF8F1D1D);

  // ── Neutral surfaces ───────────────────────────────────────────────────

  static const Color white = Color(0xFFFFFFFF);

  /// Screens (Scaffold) and the Home AppBar.
  static const Color background = white;

  /// Cards, navigation bar, sheets and dialogs.
  static const Color surface = white;

  /// Neutral inset surfaces where grouping needs a subtle fill.
  static const Color surfaceContainer = Color(0xFFF5F5F5);

  /// Opaque black, used only for the translucent iOS loading overlay.
  static const Color black = Color(0xFF000000);

  // ── Text and navigation ────────────────────────────────────────────────

  /// Main text (17.93:1 on white).
  static const Color textPrimary = Color(0xFF171717);

  /// Secondary readable text (6.19:1 on white).
  static const Color textSecondary = Color(0xFF616161);

  /// Neutral emphasis mapped to `ColorScheme.secondary` (icons, section
  /// headings). It is **not** a success color; use [success] for that.
  static const Color secondary = textPrimary;

  /// Selected tab icon and label (dark, never red).
  static const Color navSelected = textPrimary;

  /// Unselected tab icon and label.
  static const Color navUnselected = textSecondary;

  /// Neutral pill behind the selected tab icon (second cue beyond color).
  static const Color selectedTabContainer = Color(0xFFEEEEEE);

  // ── Boundaries ─────────────────────────────────────────────────────────

  /// Visible control boundary such as a text field (4.74:1 on white,
  /// above the 3:1 non-text minimum).
  static const Color inputOutline = Color(0xFF737373);

  /// Decorative separators and card outlines. Never an input boundary.
  static const Color divider = Color(0xFFE5E5E5);

  /// Visible keyboard-focus outline (combined with a wider stroke).
  static const Color focus = textPrimary;

  // ── Disabled ───────────────────────────────────────────────────────────

  static const Color disabledBackground = Color(0xFFF0F0F0);
  static const Color disabledForeground = Color(0xFF767676);

  // ── Semantic status ────────────────────────────────────────────────────

  /// Available/success state only (e.g. the availability switch), never a
  /// primary action.
  static const Color success = Color(0xFF166534);

  /// Validation, failure and destructive actions such as account deletion.
  static const Color error = Color(0xFFB91C1C);

  /// Semantic warning.
  static const Color warning = Color(0xFF92400E);
}
