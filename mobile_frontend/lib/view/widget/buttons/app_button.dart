// Shared primary (high-emphasis) button.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/view/widget/buttons/app_icon_position.dart';

/// The app's primary action button (a themed [FilledButton]).
///
/// - Genuinely disabled when [onPressed] is null.
/// - While [isLoading], taps are ignored (no duplicate submissions) and a
///   spinner replaces the label at the same size, so the layout never jumps.
/// - Colors, radius and text style default to `AppTheme`; pass overrides
///   only when a screen genuinely needs them.
/// - Presentational only: the caller decides loading/enabled state (usually
///   from its feature Cubit).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    this.label,
    this.child,
    required this.onPressed,
    this.icon,
    this.iconPosition = AppIconPosition.start,
    this.isLoading = false,
    this.expand = false,
    this.width,
    this.height = 48,
    this.padding,
    this.borderRadius = 12,
    this.border,
    this.backgroundColor,
    this.foregroundColor,
    this.textStyle,
    this.loadingSemanticLabel,
  }) : assert(label != null || child != null, 'Provide a label or a child.');

  /// Button text. Ignored when [child] is given.
  final String? label;

  /// Custom content instead of [label].
  final Widget? child;

  /// Null disables the button.
  final VoidCallback? onPressed;

  /// Optional icon beside the label.
  final Widget? icon;

  /// Logical side of [icon] (start = right in Arabic).
  final AppIconPosition iconPosition;

  /// Shows a spinner and ignores taps while true.
  final bool isLoading;

  /// Stretches to the full available width.
  final bool expand;

  /// Fixed width (ignored when [expand] is true).
  final double? width;

  /// Height; also the minimum touch target. Defaults to 48.
  final double height;

  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final BorderSide? border;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final TextStyle? textStyle;

  /// Screen-reader text while loading. Defaults to the localized "loading".
  final String? loadingSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = backgroundColor ?? colors.primary;
    final foreground = foregroundColor ?? colors.onPrimary;

    final content = _ButtonContent(
      label: label,
      icon: icon,
      iconPosition: iconPosition,
      child: child,
    );

    final button = FilledButton(
      // Loading keeps the enabled colors but drops taps.
      onPressed: isLoading ? () {} : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        minimumSize: Size(48, height),
        padding:
            padding ?? const EdgeInsetsDirectional.symmetric(horizontal: 24),
        textStyle:
            textStyle ??
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: border ?? BorderSide.none,
        ),
      ),
      child: isLoading
          ? Semantics(
              label: loadingSemanticLabel ?? context.l10n.loading,
              liveRegion: true,
              // Keep the label's size so the button doesn't resize.
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(opacity: 0, child: ExcludeSemantics(child: content)),
                  SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: foreground,
                    ),
                  ),
                ],
              ),
            )
          : content,
    );

    return SizedBox(
      width: expand ? double.infinity : width,
      height: height,
      // Absorb taps while loading so callbacks can't fire twice.
      child: AbsorbPointer(absorbing: isLoading, child: button),
    );
  }
}

/// Label with an optional icon on the logical start or end side.
class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.iconPosition,
    required this.child,
  });

  final String? label;
  final Widget? icon;
  final AppIconPosition iconPosition;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final text = child ?? Text(label!, overflow: TextOverflow.ellipsis);
    if (icon == null) return text;
    // Row follows Directionality, so "start" is right in RTL, left in LTR.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: iconPosition == AppIconPosition.start
          ? [icon!, const SizedBox(width: 8), Flexible(child: text)]
          : [Flexible(child: text), const SizedBox(width: 8), icon!],
    );
  }
}
