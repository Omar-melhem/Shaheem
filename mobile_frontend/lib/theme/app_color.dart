import 'package:flutter/painting.dart';

/// SHAHM brand palette, supplied by the Product Owner and shared with the
/// web prototype (`web_frontend/tailwind.config.js`).
class AppColor {
  AppColor._();

  // Primary — maroon
  static const Color primary50 = Color(0xFFFBF2F4);
  static const Color primary100 = Color(0xFFF5E0E4);
  static const Color primary200 = Color(0xFFE9BCC5);
  static const Color primary300 = Color(0xFFD58E9C);
  static const Color primary400 = Color(0xFFB85468);
  static const Color primary500 = Color(0xFF8C2335);
  static const Color primary600 = Color(0xFF7A1E2E);
  static const Color primary700 = Color(0xFF641826);
  static const Color primary800 = Color(0xFF4E131E);
  static const Color primary900 = Color(0xFF3A0E16);
  static const Color primary = primary500;

  // Secondary — forest green
  static const Color secondary50 = Color(0xFFEEF3F1);
  static const Color secondary100 = Color(0xFFD6E2DD);
  static const Color secondary200 = Color(0xFFADC5BB);
  static const Color secondary300 = Color(0xFF7FA294);
  static const Color secondary400 = Color(0xFF4F7466);
  static const Color secondary500 = Color(0xFF263D34);
  static const Color secondary600 = Color(0xFF20342C);
  static const Color secondary700 = Color(0xFF1A2A24);
  static const Color secondary800 = Color(0xFF14201B);
  static const Color secondary900 = Color(0xFF0E1613);
  static const Color secondary = secondary500;

  // Text — ink
  static const Color ink = Color(0xFF242424);
  static const Color inkSoft = Color(0xFF4A4A4A);
  static const Color inkMuted = Color(0xFF6E6A64);

  // Background — cream (beige)
  static const Color cream = Color(0xFFF5F0E8);
  static const Color creamDark = Color(0xFFEDE5D8);
  static const Color creamDeep = Color(0xFFE3D8C6);

  // Accent / border — sand
  static const Color sand = Color(0xFFC8A98A);
  static const Color sandLight = Color(0xFFE6D6C5);
  static const Color sandDark = Color(0xFFA88866);

  static const Color white = Color(0xFFFFFFFF);

  // Semantic
  static const Color background = cream;
  static const Color surface = white;
  static const Color textPrimary = ink;
  static const Color textSecondary = inkMuted;
  static const Color border = sandLight;
  static const Color splashBackground = cream;

  static const Color blackIcons = Color.fromRGBO(5, 5, 5, 1.0);
  static const Color greyIcons = Color.fromARGB(255, 237, 237, 242);
  static const Color red = Color(0xffff0000);
  static const Color googleLogo = Color(0xffDB4437);
  static const Color flatred = Color.fromRGBO(239, 90, 86, 1.0);
  static const Color thirdWhite = Color(0xffF5F5F7);
  static const Color backgroundColor = Color.fromARGB(255, 242, 241, 241);
  static const Color lightGreyColor = Color.fromRGBO(245, 245, 245, 1.0);
  static const Color success = Color.fromRGBO(0, 168, 98, 1.0);
  static const Color failed = Color.fromRGBO(239, 90, 86, 1.0);
  static const Color shadow = Color.fromRGBO(183, 183, 183, 0.5);
  static const Color notification = Color(0xffC5B100);
  static const Color green = Color(0xff1CD345);
  static const Color orange = Color(0xffE57C00);
  static const Color purple = Color(0xff6F51FE);
  static const Color lightGreen = Color.fromARGB(255, 163, 201, 180);
  static const Color focusColor = Color.fromRGBO(55, 145, 93, 1.0);
  static const Color yellow = Color.fromRGBO(252, 182, 20, 1.0);
  static const Color babyPink = Color(0xfffdcfec);
  static const Color babyBlue = Color(0xffcfdcfd);
  static const Color foshi = Color(0xffebcffd);
  static const Color lemon = Color(0xfffdedcf);
  static const Color darkMood = Color(0xff949494);
  static const Color blue = Color(0xff007AFF);
  static const Color black = Color(0xff000000);
  static const Color darkBlue = Color.fromARGB(255, 0, 46, 96);
  static const Color lightBlack = Color(0xff303437);
  static const Color lightOrange = Color(0xffFDDACF);
  static const Color textPink = Color(0xffFD17A9);
  static const Color primaryBlueColor = Color(0xff00BEC5);
  static const Color opacityLine = Color(0xff828282);
  static const Color lightFont = Color(0xffBDBDBD);
  static const Color boldTextColor = Color(0xff192126);
}
