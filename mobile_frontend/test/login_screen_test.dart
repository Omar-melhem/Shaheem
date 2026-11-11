// Widget tests for the Login screen through the real app (MainApp, router,
// localization, breakpoints) with injected fakes: form behavior, errors,
// session hand-off, forgot-password popup and responsive layouts.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_frontend/domain/errors/auth_exceptions.dart';
import 'package:mobile_frontend/main.dart';
import 'package:mobile_frontend/view/screens/authentication/cubit/login_cubit.dart';
import 'package:mobile_frontend/view/screens/authentication/widget/login_failure_message.dart';
import 'package:mobile_frontend/view/screens/authentication/view/login_screen.dart';
import 'package:mobile_frontend/view/screens/home_screen/view/home_screen.dart';
import 'package:mobile_frontend/view/widget/pop_up_screen/app_popup.dart';

import 'fakes.dart';
import 'test_app.dart';

void main() {
  late FakeInternetConnectionService internet;
  late FakeAuthRepository repo;

  setUp(() {
    internet = FakeInternetConnectionService();
    repo = FakeAuthRepository(); // no stored session → Login
  });

  /// Launches the app; with no stored session it settles on Login.
  Future<void> launch(WidgetTester tester) async {
    await tester.pumpWidget(
      MainApp(connectivityService: internet, authRepository: repo),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, l10n.loginButton));
    await tester.pumpAndSettle();
  }

  testWidgets('shows exactly username and password, all text localized', (
    tester,
  ) async {
    await launch(tester);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(field(l10n.usernameLabel), findsOneWidget);
    expect(field(l10n.passwordLabel), findsOneWidget);
    // Heading and button share the same Arabic text.
    expect(find.text(l10n.loginTitle), findsNWidgets(2));
    expect(find.text(l10n.forgotPassword), findsOneWidget);
  });

  testWidgets('empty submit → inline required errors; typing clears one', (
    tester,
  ) async {
    await launch(tester);
    await submit(tester);
    expect(find.text(l10n.usernameRequired), findsOneWidget);
    expect(find.text(l10n.passwordRequired), findsOneWidget);
    expect(repo.signInCalls, 0);

    await tester.enterText(field(l10n.usernameLabel), 'captain01');
    await tester.pump();
    expect(find.text(l10n.usernameRequired), findsNothing);
    expect(find.text(l10n.passwordRequired), findsOneWidget);
  });

  testWidgets('username Next moves focus to password; Done submits', (
    tester,
  ) async {
    await launch(tester);
    await tester.enterText(field(l10n.usernameLabel), 'captain01');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    final passwordEditable = find.descendant(
      of: field(l10n.passwordLabel),
      matching: find.byType(EditableText),
    );
    expect(
      tester.widget<EditableText>(passwordEditable).focusNode.hasFocus,
      isTrue,
    );

    await tester.enterText(field(l10n.passwordLabel), 'secret');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(repo.signInCalls, 1);
  });

  testWidgets('invalid credentials → generic error toast, stays on Login', (
    tester,
  ) async {
    await launch(tester);
    repo.signInError = const InvalidCredentialsException();
    await tester.enterText(field(l10n.usernameLabel), 'captain01');
    await tester.enterText(field(l10n.passwordLabel), 'wrong');
    await submit(tester);
    expect(find.text(l10n.loginInvalidCredentials), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
    // Not shown as a field error.
    expect(find.text(l10n.usernameRequired), findsNothing);
  });

  testWidgets('blocked account at login → generic auth error (D-P16 pending)', (
    tester,
  ) async {
    await launch(tester);
    repo.signInError = const AccountBlockedException();
    await tester.enterText(field(l10n.usernameLabel), 'captain01');
    await tester.enterText(field(l10n.passwordLabel), 'secret');
    await submit(tester);
    expect(find.text(l10n.loginInvalidCredentials), findsOneWidget);
    expect(find.text(l10n.accountBlockedMessage), findsNothing);
  });

  testWidgets('invalid credentials and blocked show the identical text', (
    tester,
  ) async {
    // Privacy: the UI must not let a user tell these apart.
    expect(
      loginFailureMessage(l10n, LoginFailure.accountBlocked),
      loginFailureMessage(l10n, LoginFailure.invalidCredentials),
    );
  });

  testWidgets('offline and backend failures get their own messages', (
    tester,
  ) async {
    await launch(tester);
    await tester.enterText(field(l10n.usernameLabel), 'u');
    await tester.enterText(field(l10n.passwordLabel), 'p');

    repo.signInError = const NetworkUnavailableException();
    await submit(tester);
    expect(find.text(l10n.loginNoInternet), findsOneWidget);

    repo.signInError = const ServiceUnavailableException();
    await submit(tester);
    expect(find.text(l10n.serviceUnavailableMessage), findsOneWidget);
  });

  testWidgets('success → session set, then router opens Home', (tester) async {
    await launch(tester);
    await tester.enterText(field(l10n.usernameLabel), 'captain01');
    await tester.enterText(field(l10n.passwordLabel), 'secret');
    await submit(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('forgot password opens the localized popup and closes', (
    tester,
  ) async {
    await launch(tester);
    await tester.tap(find.text(l10n.forgotPassword));
    await tester.pumpAndSettle();
    expect(find.text(l10n.forgotPasswordTitle), findsOneWidget);
    expect(find.text(l10n.forgotPasswordMessage), findsOneWidget);

    await tester.tap(find.text(l10n.close));
    await tester.pumpAndSettle();
    expect(find.byType(AppPopup), findsNothing);
  });

  group('responsive', () {
    for (final width in [320.0, 375.0, 600.0, 840.0, 1024.0, 1440.0]) {
      testWidgets('width $width: no overflow, button visible, form capped', (
        tester,
      ) async {
        setScreenSize(tester, width, 800);
        await launch(tester);
        expect(tester.takeException(), isNull);
        final button = find.widgetWithText(FilledButton, l10n.loginButton);
        expect(button, findsOneWidget);
        final formWidth = tester.getSize(field(l10n.usernameLabel)).width;
        // Mobile uses the width; tablet/desktop are capped (480 / 520).
        expect(formWidth, lessThanOrEqualTo(width <= 450 ? width : 520));
      });
    }

    testWidgets('short screen with keyboard open: scrolls, no overflow', (
      tester,
    ) async {
      setScreenSize(tester, 375, 480);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await launch(tester);
      expect(tester.takeException(), isNull);
      // The submit button can still be reached by scrolling.
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, l10n.loginButton),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
