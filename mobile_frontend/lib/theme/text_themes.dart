// Shared typography scale for SHAHM.
//
// Migrated from a GetX project that picked Tajawal or Inter per locale. The
// approved typography (D-A63) is IBM Plex Sans Arabic with Ink as the
// default text color. The styles are plain immutable constants: there is no
// dynamic typography state, so no Cubit/Bloc is involved.

import 'package:flutter/painting.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/util/fonts.dart';

/// The app's text styles, from largest ([headline0]) to smallest ([caption]).
///
/// Use them through the shared text widgets in `view/widget/text/`, or
/// directly with `copyWith` for one-off adjustments:
/// `TextThemeStyle.bodyText1.copyWith(color: AppColor.primary)`.
///
/// Font family: IBM Plex Sans Arabic ([AppFonts.ibmPlexSansArabic]), bundled
/// and registered in `pubspec.yaml`. Default color: Ink ([AppColor.ink]).
abstract final class TextThemeStyle {
  /// Font used by every style. Kept in one place so a future locale-based
  /// choice only needs to change here.
  static const String _fontFamily = AppFonts.ibmPlexSansArabic;

  static const TextStyle headline0 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 38.0,
    fontWeight: FontWeight.w600,
    color: AppColor.ink,
    height: 1.2,
  );
  static const TextStyle headline1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 36.0,
    fontWeight: FontWeight.w600,
    color: AppColor.ink,
    height: 1.2,
  );
  static const TextStyle headline2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 26.0,
    fontWeight: FontWeight.w600,
    color: AppColor.ink,
    height: 1.2,
  );
  static const TextStyle headline3 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24.0,
    fontWeight: FontWeight.w600,
    color: AppColor.ink,
    height: 1.2,
  );
  static const TextStyle headline4 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20.0,
    fontWeight: FontWeight.w400,
    color: AppColor.ink,
    height: 1.2,
  );
  static const TextStyle headline5 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    color: AppColor.ink,
    height: 1.2,
  );
  static const TextStyle headline6 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: AppColor.ink,
    height: 1.2,
  );
  static const TextStyle bodyText1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15.0,
    fontWeight: FontWeight.w400,
    color: AppColor.ink,
    height: 1.2,
  );
  static const TextStyle bodyText2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13.0,
    fontWeight: FontWeight.w400,
    color: AppColor.ink,
    height: 1.2,
  );
  static const TextStyle subtitle2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    color: AppColor.ink,
    height: 1.2,
  );
  static const TextStyle subtitle1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10.0,
    fontWeight: FontWeight.w400,
    color: AppColor.ink,
    height: 1.2,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 9.0,
    fontWeight: FontWeight.w300,
    color: AppColor.ink,
    height: 1.2,
  );
}
