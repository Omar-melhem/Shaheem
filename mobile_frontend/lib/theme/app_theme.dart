import 'package:flutter/material.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/util/fonts.dart';

/// The app's central theme: brand color scheme (D-A63), the bundled
/// IBM Plex Sans Arabic family for every Material text style, and shared
/// component defaults. Material 3 derives default text color from
/// `onSurface`, which is Ink.
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    fontFamily: AppFonts.ibmPlexSansArabic,
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
        textStyle: const TextStyle(
          fontFamily: AppFonts.ibmPlexSansArabic,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
