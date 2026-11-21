import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/util/fonts.dart';

/// The app's central theme (D-A69): white surfaces, red primary actions,
/// neutral text, semantic success/error/warning, and the bundled IBM Plex
/// Sans Arabic family for every Material text style.
///
/// Material 3 tints elevated surfaces with `surfaceTint` and AppBars when
/// content scrolls under them; both are disabled on purpose so white stays
/// white (no beige or pink cast returns).
class AppTheme {
  AppTheme._();

  /// The color roles shared by every component theme below.
  static const ColorScheme colorScheme = ColorScheme.light(
    primary: AppColor.primary,
    onPrimary: AppColor.onPrimary,
    primaryContainer: AppColor.primaryContainer,
    onPrimaryContainer: AppColor.onPrimaryContainer,
    // Neutral emphasis, not success (see AppColor.secondary).
    secondary: AppColor.secondary,
    onSecondary: AppColor.white,
    surface: AppColor.surface,
    onSurface: AppColor.textPrimary,
    onSurfaceVariant: AppColor.textSecondary,
    surfaceContainerLowest: AppColor.white,
    surfaceContainerLow: AppColor.white,
    surfaceContainer: AppColor.surfaceContainer,
    surfaceContainerHigh: AppColor.surfaceContainer,
    surfaceContainerHighest: AppColor.surfaceContainer,
    outline: AppColor.inputOutline,
    outlineVariant: AppColor.divider,
    error: AppColor.error,
    onError: AppColor.white,
    surfaceTint: Colors.transparent,
  );

  static ThemeData get light => ThemeData(
    fontFamily: AppFonts.ibmPlexSansArabic,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColor.background,
    dividerColor: AppColor.divider,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColor.background,
      foregroundColor: AppColor.textPrimary,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: true,
      elevation: 0,
      // Dark status-bar icons on the white AppBar.
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(160, 48)),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontFamily: AppFonts.ibmPlexSansArabic,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColor.disabledBackground;
          }
          if (states.contains(WidgetState.pressed)) {
            return AppColor.primaryPressed;
          }
          return AppColor.primary;
        }),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? AppColor.disabledForeground
              : AppColor.onPrimary,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? AppColor.disabledForeground
              : AppColor.textPrimary,
        ),
        side: WidgetStateProperty.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.disabled)
                ? AppColor.divider
                : AppColor.inputOutline,
          ),
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      // Green is the semantic "available" state, as in the client reference.
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return AppColor.disabledBackground;
        }
        return states.contains(WidgetState.selected)
            ? AppColor.success
            : AppColor.surfaceContainer;
      }),
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return AppColor.disabledForeground;
        }
        return states.contains(WidgetState.selected)
            ? AppColor.white
            : AppColor.textSecondary;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColor.success
            : AppColor.inputOutline,
      ),
    ),
    cardTheme: const CardThemeData(
      color: AppColor.surface,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColor.surface,
      modalBackgroundColor: AppColor.surface,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColor.surface,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
