// Shared text widget: Subtitle1.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/theme/text_themes.dart';
import 'package:mobile_frontend/view/widget/text/app_text_widget.dart';

/// Very small label text (10, bold).
///
/// Based on `TextThemeStyle.subtitle1`. See [AppTextWidget] for the shared
/// parameters and defaults.
class Subtitle1 extends AppTextWidget {
  const Subtitle1({
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
  TextStyle buildDefaultStyle() => TextThemeStyle.subtitle1.copyWith(
    fontWeight: FontWeight.bold,
    color: color ?? AppColor.black,
    fontSize: fontSize ?? 10,
  );
}
