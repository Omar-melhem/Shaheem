// Shared base for the typography widgets in this folder.

import 'package:flutter/material.dart';

/// Common behaviour for the shared text widgets (Headline1, BodyText1, …).
///
/// Every subclass only decides its default style via [buildDefaultStyle];
/// the constructor parameters and rendering rules live here once instead of
/// being repeated in eleven files.
///
/// Style precedence, per property (Task 23):
/// 1. a dedicated parameter ([color], [fontSize], [textDecoration], and
///    `fontWeight` on the wrappers that have it), when not null;
/// 2. otherwise the same property in [style], when not null;
/// 3. otherwise the wrapper's default (IBM Plex Sans Arabic, its size and
///    weight, Ink, the `TextThemeStyle` line height).
///
/// A partial [style] therefore changes only what it sets. A [style] with
/// `inherit: false` follows Flutter's `TextStyle.merge` rule and replaces
/// the default entirely; dedicated parameters still apply on top.
///
/// Layout defaults: one line, ellipsis overflow, `TextAlign.start` (which
/// follows the RTL direction, i.e. right-aligned in Arabic).
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

  /// Caller style, merged over the default: only its non-null properties
  /// apply, and dedicated parameters win over it (see the class docs).
  final TextStyle? style;

  /// Defaults to 1.
  final int? maxLines;

  /// Defaults to [TextOverflow.ellipsis].
  final TextOverflow? overflow;

  /// Defaults to [TextAlign.start].
  final TextAlign? textAlign;

  /// Underline/strike-through etc. Wins over `style.decoration`; null keeps
  /// the style's own decoration (none by default).
  final TextDecoration? textDecoration;

  /// Text color. Wins over `style.color`; null keeps the style's color or
  /// the default Ink.
  final Color? color;

  /// Font size. Wins over `style.fontSize`; null keeps the style's size or
  /// the wrapper's default.
  final double? fontSize;

  /// The style used when [style] is null, built from `TextThemeStyle` plus
  /// this widget's defaults and overrides.
  @protected
  TextStyle buildDefaultStyle();

  /// The wrapper's dedicated `fontWeight` parameter, for the wrappers that
  /// expose one (null elsewhere). It wins over `style.fontWeight`.
  @protected
  FontWeight? get fontWeightOverride => null;

  @override
  Widget build(BuildContext context) => Text(
    title,
    // Default, then the caller's style, then the dedicated parameters:
    // merge only replaces properties that are non-null in its argument.
    style: buildDefaultStyle()
        .merge(style)
        .merge(
          TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeightOverride,
            decoration: textDecoration,
          ),
        ),
    maxLines: maxLines ?? 1,
    overflow: overflow ?? TextOverflow.ellipsis,
    textAlign: textAlign ?? TextAlign.start,
  );
}
