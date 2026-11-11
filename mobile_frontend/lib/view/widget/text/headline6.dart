// Shared text widget: Headline6.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/theme/text_themes.dart';
import 'package:mobile_frontend/view/widget/text/app_text_widget.dart';

/// Small title / dialog content text (14, regular).
///
/// Based on `TextThemeStyle.headline6`. See [AppTextWidget] for the shared
/// parameters and defaults.
class Headline6 extends AppTextWidget {
  const Headline6({
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
  TextStyle buildDefaultStyle() => TextThemeStyle.headline6.copyWith(
    fontWeight: FontWeight.normal,
    color: color ?? AppColor.black,
    fontSize: fontSize ?? 14,
  );
}
