// Shared low-emphasis text button.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/view/widget/buttons/app_icon_position.dart';

/// A low-emphasis action (Forgot password, Cancel, Retry, Show more).
///
/// Adds to Flutter's [TextButton]: SHAHM defaults (theme primary color,
/// semi-bold IBM Plex Sans Arabic label, 48 px minimum touch target),
/// a logical icon slot and one documented color precedence. Deliberately
/// smaller than [AppButton]'s API: no background, border or loading
/// spinner. It owns no state and runs no logic beyond [onPressed].
///
/// Contract (see SHARED_UI_COMPONENTS_REFERENCE §3.9):
/// - [label] is required and must not be blank: it is the visible text and
///   the button's accessible name.
/// - [onPressed] is required but nullable on purpose: passing null is how a
///   caller shows the disabled state, so the decision is always explicit.
/// - Label and icon color: [color], else [textStyle]'s color, else the
///   theme primary. Disabled always uses Flutter's Material disabled color
///   (no approved SHAHM disabled token yet).
/// - [textStyle] is merged over the default (semi-bold, theme font
///   family): only the properties it sets change.
class AppTextButton extends StatelessWidget {
  const AppTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconPosition = AppIconPosition.start,
    this.color,
    this.textStyle,
    this.padding,
  });

  /// Visible text and accessible name. Localized (ARB) and not blank.
  final String label;

  /// Tap action. Null disables the button (no tap, disabled semantics and
  /// the Material disabled color).
  final VoidCallback? onPressed;

  /// Optional decorative icon beside the label; it takes the label color
  /// and the button's icon size (18 px). Null shows the label only.
  final Widget? icon;

  /// Logical side of [icon] (start = right in Arabic, left in LTR).
  final AppIconPosition iconPosition;

  /// Label and icon color while enabled. Wins over [textStyle]'s color;
  /// null falls back to it, then to the theme primary.
  final Color? color;

  /// Label style merged over the default (semi-bold, theme font family).
  /// Null keeps the default.
  final TextStyle? textStyle;

  /// Inner padding. Null uses 12 px on each horizontal side. The 48×48
  /// minimum size still applies.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    // Not a const-constructor assert because String.trim isn't constant.
    assert(
      label.trim().isNotEmpty,
      'AppTextButton.label is the accessible name and must not be blank.',
    );

    final theme = Theme.of(context);
    // A button's text style replaces the inherited one, so the theme font
    // family is part of the default; a per-call style is merged over it.
    final defaultTextStyle = TextStyle(
      fontWeight: FontWeight.w600,
      fontFamily: theme.textTheme.labelLarge?.fontFamily,
    );
    final style = TextButton.styleFrom(
      // The button paints the label with its foreground color, so a color
      // given only in textStyle is honored here instead of being dropped.
      foregroundColor: color ?? textStyle?.color ?? theme.colorScheme.primary,
      minimumSize: const Size(48, 48),
      padding: padding ?? const EdgeInsetsDirectional.symmetric(horizontal: 12),
      textStyle: defaultTextStyle.merge(textStyle),
    );
    final text = Text(label);

    if (icon == null) {
      return TextButton(onPressed: onPressed, style: style, child: text);
    }
    // Row follows Directionality, so "start" is right in RTL.
    return TextButton(
      onPressed: onPressed,
      style: style,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: iconPosition == AppIconPosition.start
            ? [icon!, const SizedBox(width: 6), Flexible(child: text)]
            : [Flexible(child: text), const SizedBox(width: 6), icon!],
      ),
    );
  }
}
