// Shared text widget: BodyText2.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/theme/text_themes.dart';
import 'package:mobile_frontend/view/widget/text/app_text_widget.dart';

/// Secondary body text (13, bold by default).
///
/// Based on `TextThemeStyle.bodyText2`. See [AppTextWidget] for the shared
/// parameters and defaults.
class BodyText2 extends AppTextWidget {
  const BodyText2({
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
  TextStyle buildDefaultStyle() => TextThemeStyle.bodyText2.copyWith(
    fontWeight: fontWeight ?? FontWeight.bold,
    color: color ?? AppColor.black,
    fontSize: fontSize ?? 13,
  );
}
