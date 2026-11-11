// Shared text widget: BodyText1.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/theme/text_themes.dart';
import 'package:mobile_frontend/view/widget/text/app_text_widget.dart';

/// Primary body text (15, bold by default).
///
/// Based on `TextThemeStyle.bodyText1`. See [AppTextWidget] for the shared
/// parameters and defaults.
class BodyText1 extends AppTextWidget {
  const BodyText1({
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
  TextStyle buildDefaultStyle() => TextThemeStyle.bodyText1.copyWith(
    fontWeight: fontWeight ?? FontWeight.bold,
    color: color ?? AppColor.black,
    fontSize: fontSize ?? 15,
  );
}
