// Shared text widget: Caption.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/theme/text_themes.dart';
import 'package:mobile_frontend/view/widget/text/app_text_widget.dart';

/// Smallest text, e.g. tiny labels or footnotes (9, bold).
///
/// Based on `TextThemeStyle.caption`. See [AppTextWidget] for the shared
/// parameters and defaults.
class Caption extends AppTextWidget {
  const Caption({
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
  TextStyle buildDefaultStyle() => TextThemeStyle.caption.copyWith(
    fontWeight: FontWeight.bold,
    color: color ?? AppColor.black,
    fontSize: fontSize ?? 9,
  );
}
