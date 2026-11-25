// Shared test host: the same localization and breakpoint setup as MainApp,
// so widgets can be tested in isolation with Arabic text and RTL.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_frontend/helper/translation/generated/app_localizations.dart';
import 'package:mobile_frontend/theme/app_theme.dart';
import 'package:mobile_frontend/util/responsive/app_breakpoints.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// Arabic strings for assertions (the same resources the app uses).
final AppLocalizations l10n = lookupAppLocalizations(const Locale('ar'));

/// Wraps [child] in a MaterialApp configured like the real app: Arabic
/// locale (RTL), generated localizations, the app theme and the central
/// breakpoints. [platform] overrides the theme platform (loading styles).
Widget testApp(Widget child, {TargetPlatform? platform}) => MaterialApp(
  theme: AppTheme.light.copyWith(platform: platform),
  locale: const Locale('ar'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  builder: (context, appChild) => ResponsiveBreakpoints.builder(
    breakpoints: AppBreakpoints.all,
    child: appChild!,
  ),
  home: Scaffold(body: child),
);

/// Sets the test window to [width]×[height] logical pixels (DPR 1) and
/// restores it after the test.
void setScreenSize(WidgetTester tester, double width, double height) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Taps the Login submit button the way a captain can: an error toast from
/// the previous attempt is a floating SnackBar at the bottom of the screen
/// and may cover the button (the logo's decoded height decides where the
/// button lands), so it is first closed through its own close button. The
/// button is then scrolled into view and must be hit-testable, so a
/// covered or unreachable button fails here instead of the tap silently
/// landing on another widget.
Future<void> tapLoginSubmit(WidgetTester tester) async {
  final toast = find.byType(SnackBar);
  if (toast.evaluate().isNotEmpty) {
    await tester.tap(
      find.descendant(of: toast, matching: find.byTooltip(l10n.close)),
    );
    await tester.pumpAndSettle();
    expect(toast, findsNothing);
  }
  final button = find.widgetWithText(FilledButton, l10n.loginButton);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  expect(button.hitTestable(), findsOneWidget);
  await tester.tap(button);
}
