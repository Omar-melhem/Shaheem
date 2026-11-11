// Shared text widget: Headline4.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/theme/text_themes.dart';
import 'package:mobile_frontend/view/widget/text/app_text_widget.dart';

/// Title text, e.g. dialog titles (20, bold, ink color).
///
/// Based on `TextThemeStyle.headline4`. See [AppTextWidget] for the shared
/// parameters and defaults.
///
/// Its default color was `AppColors.almostBlack` in the old project; that
/// color does not exist in SHAHM, so the brand ink color is used instead.
class Headline4 extends AppTextWidget {
  const Headline4({
    super.key,
    required super.title,
    super.style,
    super.maxLines,
    super.overflow,
    super.textAlign,
    super.textDecoration,
    super.color,
    super.fontSize,
    this.fontWeight,
  });

  /// Overrides the default font weight.
  final FontWeight? fontWeight;

  @override
  TextStyle buildDefaultStyle() => TextThemeStyle.headline4.copyWith(
    fontWeight: fontWeight ?? FontWeight.bold,
    color: color ?? AppColor.ink,
    fontSize: fontSize ?? 20,
  );
}
