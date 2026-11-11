// Shared base for the typography widgets in this folder.

import 'package:flutter/material.dart';

/// Common behaviour for the shared text widgets (Headline1, BodyText1, …).
///
/// Every subclass only decides its default style via [buildDefaultStyle];
/// the constructor parameters and rendering rules live here once instead of
/// being repeated in eleven files:
/// - [style], when given, replaces the default style entirely (as before).
/// - [textDecoration] is applied on top of whichever style is used.
/// - Defaults: one line, ellipsis overflow, `TextAlign.start` (which follows
///   the RTL direction, i.e. right-aligned in Arabic).
///
/// These widgets are presentational only: no data fetching or logic.
abstract class AppTextWidget extends StatelessWidget {
  const AppTextWidget({
    super.key,
    required this.title,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.textDecoration,
    this.color,
    this.fontSize,
  });

  /// The text to display.
  final String title;

  /// Full style override. When set, [color], [fontSize] and font weight
  /// parameters are ignored.
  final TextStyle? style;

  /// Defaults to 1.
  final int? maxLines;

  /// Defaults to [TextOverflow.ellipsis].
  final TextOverflow? overflow;

  /// Defaults to [TextAlign.start].
  final TextAlign? textAlign;

  /// Underline/strike-through etc. Applied to the default or custom style.
  final TextDecoration? textDecoration;

  /// Overrides the widget's default color.
  final Color? color;

  /// Overrides the widget's default font size.
  final double? fontSize;

  /// The style used when [style] is null, built from `TextThemeStyle` plus
  /// this widget's defaults and overrides.
  @protected
  TextStyle buildDefaultStyle();

  @override
  Widget build(BuildContext context) => Text(
    title,
    // copyWith(decoration: null) keeps the style's own decoration.
    style: (style ?? buildDefaultStyle()).copyWith(decoration: textDecoration),
    maxLines: maxLines ?? 1,
    overflow: overflow ?? TextOverflow.ellipsis,
    textAlign: textAlign ?? TextAlign.start,
  );
}
