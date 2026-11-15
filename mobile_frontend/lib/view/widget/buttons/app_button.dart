// Shared primary (high-emphasis) button.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/view/widget/buttons/app_icon_position.dart';

/// The app's primary action button (a themed [FilledButton]).
///
/// Contract (see SHARED_UI_COMPONENTS_REFERENCE §3.8):
/// - Content: exactly one of [label] (non-blank; the accessible name) or
///   [child] (asserts). [icon] sits beside [label] or [child].
/// - [onPressed] is required but nullable: null disables the button
///   (Material disabled colors, no tap, disabled semantics).
/// - While [isLoading], taps are ignored (no duplicate submissions) and a
///   spinner replaces the content at the same size, so the layout never
///   jumps. Loading keeps the enabled colors and is announced as loading.
/// - Label/spinner/icon color: [foregroundColor] > [textStyle]'s color >
///   `colorScheme.onPrimary`. Disabled always uses Material's disabled
///   colors (no approved SHAHM disabled token yet).
/// - [textStyle] is merged over the default (bold 16, theme font family):
///   only the properties it sets change.
/// - Long labels wrap (never truncated); [height] is a minimum.
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
  }) : assert(label != null || child != null, 'Provide a label or a child.'),
       assert(
         label == null || child == null,
         'Provide either a label or a child, not both.',
       ),
       assert(
         !(expand && width != null),
         'width has no effect when expand is true; pass only one.',
       ),
       assert(width == null || width > 0, 'width must be positive.'),
       assert(height >= 0, 'height (a minimum) must not be negative.'),
       assert(borderRadius >= 0, 'borderRadius must not be negative.');

  /// Button text and accessible name. Localized (ARB) and not blank.
  /// Exclusive with [child].
  final String? label;

  /// Custom content instead of [label]. Exclusive with [label]. The caller
  /// must make it accessible (e.g. a [Text], or a [Semantics] label around
  /// an icon-only child): the button takes its name from the child.
  final Widget? child;

  /// Null disables the button.
  final VoidCallback? onPressed;

  /// Optional icon beside the content; decorative (no own semantics). An
  /// [Icon] without its own color takes the foreground color.
  final Widget? icon;

  /// Logical side of [icon] (start = right in Arabic).
  final AppIconPosition iconPosition;

  /// Shows a spinner and ignores taps while true.
  final bool isLoading;

  /// Stretches to the full available width. Exclusive with [width].
  final bool expand;

  /// Fixed width. Exclusive with [expand]; null sizes to the content.
  final double? width;

  /// Minimum height and touch target. Defaults to 48; the button grows
  /// taller only when its content needs it (e.g. large text scale).
  final double height;

  /// Inner padding. Null: 24 px start/end. The minimum size still applies.
  final EdgeInsetsGeometry? padding;

  /// Corner radius, also used by [border]. Defaults to 12.
  final double borderRadius;

  /// Outline. Null: no border.
  final BorderSide? border;

  /// Enabled (and loading) background. Null: `colorScheme.primary`.
  final Color? backgroundColor;

  /// Label, icon and spinner color. Wins over [textStyle]'s color; null
  /// falls back to it, then to `colorScheme.onPrimary`.
  final Color? foregroundColor;

  /// Label style merged over the default (bold 16, theme font family).
  /// Null keeps the default.
  final TextStyle? textStyle;

  /// Screen-reader text while loading. Defaults to the localized "loading".
  final String? loadingSemanticLabel;

  @override
  Widget build(BuildContext context) {
    // Not a const-constructor assert because String.trim isn't constant.
    assert(
      label == null || label!.trim().isNotEmpty,
      'AppButton.label is the accessible name and must not be blank.',
    );

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final background = backgroundColor ?? colors.primary;
    // The button paints its label with the foreground color, so a color
    // given only in textStyle is honored here instead of being dropped.
    final foreground = foregroundColor ?? textStyle?.color ?? colors.onPrimary;
    // A button's text style replaces the inherited one, so the theme font
    // family is part of the default; a per-call style is merged over it.
    final defaultTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
      fontFamily: theme.textTheme.labelLarge?.fontFamily,
    );

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
        textStyle: defaultTextStyle.merge(textStyle),
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

    // [height] is a minimum (FilledButton.minimumSize), not a fixed size, so
    // the label can grow with large accessibility text instead of clipping.
    return SizedBox(
      width: expand ? double.infinity : width,
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
    // Labels wrap instead of being truncated: an action's text must stay
    // fully readable at any width and text size.
    final text = child ?? Text(label!, textAlign: TextAlign.center);
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
