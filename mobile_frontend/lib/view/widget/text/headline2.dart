// Shared text widget: Headline2.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/theme/text_themes.dart';
import 'package:mobile_frontend/view/widget/text/app_text_widget.dart';

/// Large headline (26, bold).
///
/// Based on `TextThemeStyle.headline2`. See [AppTextWidget] for the shared
/// parameters and defaults.
class Headline2 extends AppTextWidget {
  const Headline2({
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
  TextStyle buildDefaultStyle() => TextThemeStyle.headline2.copyWith(
    fontWeight: FontWeight.bold,
    color: color ?? AppColor.black,
    fontSize: fontSize ?? 26,
  );
}
