import 'package:flutter/material.dart';
import 'package:mobile_frontend/theme/app_color.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    colorScheme: const ColorScheme.light(
      primary: AppColor.primary,
      onPrimary: AppColor.white,
      secondary: AppColor.secondary,
      onSecondary: AppColor.white,
      surface: AppColor.surface,
      onSurface: AppColor.textPrimary,
      outline: AppColor.border,
    ),
    scaffoldBackgroundColor: AppColor.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColor.background,
      foregroundColor: AppColor.textPrimary,
      centerTitle: true,
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(160, 48),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  );
}
