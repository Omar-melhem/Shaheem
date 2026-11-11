// Shared text widget: Headline5.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/theme/text_themes.dart';
import 'package:mobile_frontend/view/widget/text/app_text_widget.dart';

/// Sub-title text (16, regular weight by default).
///
/// Based on `TextThemeStyle.headline5`. See [AppTextWidget] for the shared
/// parameters and defaults.
///
/// Without [fontWeight], the weight from `TextThemeStyle.headline5` (w400)
/// is kept.
class Headline5 extends AppTextWidget {
  const Headline5({
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
  TextStyle buildDefaultStyle() => TextThemeStyle.headline5.copyWith(
    fontWeight: fontWeight,
    color: color ?? AppColor.black,
    fontSize: fontSize ?? 16,
  );
}
