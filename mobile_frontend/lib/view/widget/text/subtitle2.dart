// Shared text widget: Subtitle2.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/theme/text_themes.dart';
import 'package:mobile_frontend/view/widget/text/app_text_widget.dart';

/// Small label text (12, bold).
///
/// Based on `TextThemeStyle.subtitle2`. See [AppTextWidget] for the shared
/// parameters and defaults.
class Subtitle2 extends AppTextWidget {
  const Subtitle2({
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
  TextStyle buildDefaultStyle() => TextThemeStyle.subtitle2.copyWith(
    fontWeight: FontWeight.bold,
    color: color ?? AppColor.black,
    fontSize: fontSize ?? 12,
  );
}
