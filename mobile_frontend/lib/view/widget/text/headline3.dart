// Shared text widget: Headline3.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/theme/text_themes.dart';
import 'package:mobile_frontend/view/widget/text/app_text_widget.dart';

/// Section headline (24, bold).
///
/// Based on `TextThemeStyle.headline3`. See [AppTextWidget] for the shared
/// parameters and defaults.
class Headline3 extends AppTextWidget {
  const Headline3({
    super.key,
    required super.title,
    super.style,
    super.maxLines,
    super.overflow,
    super.textAlign,
    super.textDecoration,
    super.color,
    super.fontSize,
  });

  @override
  TextStyle buildDefaultStyle() => TextThemeStyle.headline3.copyWith(
    fontWeight: FontWeight.bold,
    color: color ?? AppColor.black,
    fontSize: fontSize ?? 24,
  );
}
