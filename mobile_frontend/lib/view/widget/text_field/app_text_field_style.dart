// Per-call appearance overrides for AppTextFormField.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/theme/app_color.dart';

/// Appearance of an [AppTextFormField], separate from its behavior.
///
/// Every property is nullable, and **null means "inherit"**: a caller sets
/// only what it wants to change and everything else keeps the default from
/// [AppTextFieldStyle.defaultsOf].
///
/// Resolution order (highest first):
/// 1. Non-null values of the per-call style (`AppTextFormField.style`).
/// 2. [AppTextFieldStyle.defaultsOf], derived from the app `ThemeData`
///    (whose color scheme maps the central `AppColor` tokens).
/// 3. For text styles left null by both, Flutter's own Material
///    `InputDecoration` text defaults.
///
/// Border colors and widths are independent per state: setting
/// [borderWidth] changes only the resting border, never the focused, error
/// or disabled border. Set those explicitly when they should match.
///
/// Icons are not styled here: they are the field's `startIcon` / `endIcon`
/// widget slots.
@immutable
class AppTextFieldStyle {
  /// Creates a style; leave a property null to inherit its default.
  const AppTextFieldStyle({
    this.textStyle,
    this.labelStyle,
    this.floatingLabelStyle,
    this.hintStyle,
    this.helperStyle,
    this.errorStyle,
    this.errorMaxLines,
    this.fillColor,
    this.cursorColor,
    this.borderRadius,
    this.contentPadding,
    this.borderColor,
    this.borderWidth,
    this.focusedBorderColor,
    this.focusedBorderWidth,
    this.errorBorderColor,
    this.errorBorderWidth,
    this.focusedErrorBorderColor,
    this.focusedErrorBorderWidth,
    this.disabledBorderColor,
    this.disabledBorderWidth,
  });

  /// Style of the typed text.
  final TextStyle? textStyle;

  /// Style of the label while it sits inside the empty, unfocused field.
  final TextStyle? labelStyle;

  /// Style of the label once it floats above the field.
  final TextStyle? floatingLabelStyle;

  /// Style of the hint text.
  final TextStyle? hintStyle;

  /// Style of the helper text under the field.
  final TextStyle? helperStyle;

  /// Style of the inline error text under the field.
  final TextStyle? errorStyle;

  /// Maximum lines of inline error text before it is ellipsized.
  final int? errorMaxLines;

  /// Background fill of the field.
  final Color? fillColor;

  /// Cursor color. While an error shows, Flutter instead colors the cursor
  /// with [errorStyle]'s color (or the theme error color).
  final Color? cursorColor;

  /// Corner radius shared by every border state.
  final double? borderRadius;

  /// Inner padding; prefer `EdgeInsetsDirectional` so RTL stays correct.
  final EdgeInsetsGeometry? contentPadding;

  /// Resting border (enabled, unfocused, no error).
  final Color? borderColor;
  final double? borderWidth;

  /// Border while focused without an error.
  final Color? focusedBorderColor;
  final double? focusedBorderWidth;

  /// Border while showing an error, unfocused. Flutter also uses it for a
  /// disabled field that has an error.
  final Color? errorBorderColor;
  final double? errorBorderWidth;

  /// Border while focused and showing an error.
  final Color? focusedErrorBorderColor;
  final double? focusedErrorBorderWidth;

  /// Border while disabled without an error.
  final Color? disabledBorderColor;
  final double? disabledBorderWidth;

  /// The complete default style for [theme].
  ///
  /// Colors come from the theme's color scheme (central `AppColor` tokens
  /// via `AppTheme`), except the resting border, which uses the
  /// input-specific [AppColor.inputBorder] (≥3:1 on white and cream). Two values are pre-existing Material fallbacks kept to
  /// preserve the current look until owner-approved tokens exist (open
  /// technical debt, not resolved branding):
  /// - `colorScheme.error`: `AppTheme` sets no error color, so this is
  ///   Material's default error red.
  /// - the disabled border, `onSurface` at 38% alpha: the exact border
  ///   Flutter's Material 3 filled-field fallback drew before this style
  ///   existed.
  static AppTextFieldStyle defaultsOf(ThemeData theme) {
    final colors = theme.colorScheme;
    return AppTextFieldStyle(
      errorMaxLines: 3,
      fillColor: colors.surface,
      borderRadius: 12,
      contentPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      // Input-specific token, not colorScheme.outline, so the navigation
      // bar and other outlined elements keep their current sand border.
      borderColor: AppColor.inputBorder,
      borderWidth: 1,
      focusedBorderColor: colors.primary,
      focusedBorderWidth: 1.5,
      errorBorderColor: colors.error,
      errorBorderWidth: 1,
      focusedErrorBorderColor: colors.error,
      focusedErrorBorderWidth: 1.5,
      // Same value Flutter computes (`withOpacity(0.38)` → alpha 97).
      disabledBorderColor: colors.onSurface.withAlpha(97),
      disabledBorderWidth: 1,
    );
  }

  /// Returns this style with every non-null property of [other] taking
  /// precedence. A null [other], or a null property in it, keeps this
  /// style's value (null never erases).
  AppTextFieldStyle merge(AppTextFieldStyle? other) {
    if (other == null) return this;
    return AppTextFieldStyle(
      textStyle: other.textStyle ?? textStyle,
      labelStyle: other.labelStyle ?? labelStyle,
      floatingLabelStyle: other.floatingLabelStyle ?? floatingLabelStyle,
      hintStyle: other.hintStyle ?? hintStyle,
      helperStyle: other.helperStyle ?? helperStyle,
      errorStyle: other.errorStyle ?? errorStyle,
      errorMaxLines: other.errorMaxLines ?? errorMaxLines,
      fillColor: other.fillColor ?? fillColor,
      cursorColor: other.cursorColor ?? cursorColor,
      borderRadius: other.borderRadius ?? borderRadius,
      contentPadding: other.contentPadding ?? contentPadding,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      focusedBorderColor: other.focusedBorderColor ?? focusedBorderColor,
      focusedBorderWidth: other.focusedBorderWidth ?? focusedBorderWidth,
      errorBorderColor: other.errorBorderColor ?? errorBorderColor,
      errorBorderWidth: other.errorBorderWidth ?? errorBorderWidth,
      focusedErrorBorderColor:
          other.focusedErrorBorderColor ?? focusedErrorBorderColor,
      focusedErrorBorderWidth:
          other.focusedErrorBorderWidth ?? focusedErrorBorderWidth,
      disabledBorderColor: other.disabledBorderColor ?? disabledBorderColor,
      disabledBorderWidth: other.disabledBorderWidth ?? disabledBorderWidth,
    );
  }
}
