// Shared low-emphasis text button.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/view/widget/buttons/app_icon_position.dart';

/// A low-emphasis action (Forgot password, Cancel, Retry, Show more).
///
/// Deliberately smaller than [AppButton]'s API: no background, border or
/// loading spinner. Disabled when [onPressed] is null. Keeps a 48 px
/// minimum touch target even though it looks like plain text.
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

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;

  /// Optional icon beside the label.
  final Widget? icon;

  /// Logical side of [icon] (start = right in Arabic).
  final AppIconPosition iconPosition;

  /// Text and icon color. Defaults to the theme's primary color.
  final Color? color;

  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final style = TextButton.styleFrom(
      foregroundColor: color ?? Theme.of(context).colorScheme.primary,
      minimumSize: const Size(48, 48),
      padding: padding ?? const EdgeInsetsDirectional.symmetric(horizontal: 12),
      textStyle: textStyle ?? const TextStyle(fontWeight: FontWeight.w600),
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
