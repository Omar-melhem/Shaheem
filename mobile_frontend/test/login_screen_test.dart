// Widget tests for the Login screen through the real app (MainApp, router,
// localization, breakpoints) with injected fakes: form behavior, errors,
// session hand-off, forgot-password and no-account popups, the temporary
// debug preview button and responsive layouts.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_frontend/domain/errors/auth_exceptions.dart';
import 'package:mobile_frontend/domain/use_cases/get_current_user.dart';
import 'package:mobile_frontend/domain/use_cases/sign_in.dart';
import 'package:mobile_frontend/domain/use_cases/sign_out.dart';
import 'package:mobile_frontend/helper/legal/legal_page_launcher.dart';
import 'package:mobile_frontend/main.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/theme/app_theme.dart';
import 'package:mobile_frontend/util/routes/debug_shell_preview.dart';
import 'package:mobile_frontend/util/routes/route_guard.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';
import 'package:mobile_frontend/view/navigation/app_nav_bar.dart';
import 'package:mobile_frontend/view/screens/authentication/cubit/login_cubit.dart';
import 'package:mobile_frontend/view/screens/authentication/widget/login_failure_message.dart';
import 'package:mobile_frontend/view/screens/authentication/view/login_screen.dart';
import 'package:mobile_frontend/view/screens/home_screen/view/home_screen.dart';
import 'package:mobile_frontend/view/widget/navigation/main_navigation_bar.dart';
import 'package:mobile_frontend/view/widget/buttons/app_text_button.dart';
import 'package:mobile_frontend/view/widget/pop_up_screen/app_popup.dart';
import 'package:mobile_frontend/view/widget/text_field/app_text_form_field.dart';
import 'package:go_router/go_router.dart';

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
  /// [preview] replaces the debug preview switch (to simulate a release).
  Future<void> launch(WidgetTester tester, {DebugShellPreview? preview}) async {
    await tester.pumpWidget(
      MainApp(
        connectivityService: internet,
        authRepository: repo,
        debugShellPreview: preview,
      ),
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

    await tester.enterText(field(l10n.passwordLabel), 'secret123');
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
    await tester.enterText(field(l10n.passwordLabel), 'wrongpass');
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
    await tester.enterText(field(l10n.passwordLabel), 'secret123');
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
    await tester.enterText(field(l10n.usernameLabel), 'captain01');
    await tester.enterText(field(l10n.passwordLabel), 'secret123');

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
    await tester.enterText(field(l10n.passwordLabel), 'secret123');
    await submit(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  // D-A65 field rules shown inline with the exact owner-approved wording.
  group('D-A65 inline validation', () {
    testWidgets('short username and password → approved length messages', (
      tester,
    ) async {
      await launch(tester);
      await tester.enterText(field(l10n.usernameLabel), 'abc');
      await tester.enterText(field(l10n.passwordLabel), '1234567');
      await submit(tester);
      expect(
        find.text('اسم المستخدم يجب أن يكون بين 4 و30 حرفاً.'),
        findsOneWidget,
      );
      expect(
        find.text('كلمة المرور يجب أن تكون بين 8 و128 حرفاً.'),
        findsOneWidget,
      );
      expect(find.text(l10n.usernameRequired), findsNothing);
      expect(repo.signInCalls, 0);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('disallowed username character → approved format message', (
      tester,
    ) async {
      await launch(tester);
      await tester.enterText(field(l10n.usernameLabel), 'captain-one');
      await tester.enterText(field(l10n.passwordLabel), 'secret123');
      await submit(tester);
      expect(
        find.text(
          'اسم المستخدم يقبل الأحرف الإنجليزية والأرقام والشرطة السفلية (_) والنقطة فقط.',
        ),
        findsOneWidget,
      );
      expect(repo.signInCalls, 0);

      // Editing the field clears its error.
      await tester.enterText(field(l10n.usernameLabel), 'captain_one');
      await tester.pump();
      expect(find.text(l10n.usernameFormatInvalid), findsNothing);
    });

    testWidgets('Arabic-Indic phone username submitted as Latin digits', (
      tester,
    ) async {
      await launch(tester);
      repo.expectedPassword = ' pass word ';
      // Stay on Login afterwards so the field can be inspected.
      repo.signInError = const InvalidCredentialsException();
      await tester.enterText(field(l10n.usernameLabel), ' ٠٧٩١٢٣٤٥٦٧ ');
      await tester.enterText(field(l10n.passwordLabel), ' pass word ');
      await submit(tester);
      expect(repo.signInCalls, 1);
      expect(repo.lastUsername, '0791234567');
      expect(repo.lastPasswordMatched, isTrue);
      // The field still shows what the captain typed.
      expect(find.text(' ٠٧٩١٢٣٤٥٦٧ '), findsOneWidget);
    });
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

  testWidgets('forgot password sits directly below the password field', (
    tester,
  ) async {
    await launch(tester);
    final password = tester.getRect(field(l10n.passwordLabel));
    final forgot = tester.getRect(
      find.widgetWithText(TextButton, l10n.forgotPassword),
    );
    final button = tester.getRect(
      find.widgetWithText(FilledButton, l10n.loginButton),
    );
    // Between the password field and the Login button, touching the field.
    expect(forgot.top, greaterThanOrEqualTo(password.bottom));
    expect(forgot.top - password.bottom, lessThan(8));
    expect(forgot.bottom, lessThanOrEqualTo(button.top));
    // Start side: in Arabic (RTL) that is the field's right edge.
    expect(forgot.right, moreOrLessEquals(password.right, epsilon: 1));
  });

  testWidgets('no-account action is below the form and opens its popup', (
    tester,
  ) async {
    await launch(tester);
    final button = tester.getRect(
      find.widgetWithText(FilledButton, l10n.loginButton),
    );
    expect(
      tester.getRect(find.text(l10n.noAccountPrompt)).top,
      greaterThanOrEqualTo(button.bottom),
    );
    // A text action, not an input: still exactly two fields.
    expect(find.byType(TextFormField), findsNWidgets(2));
    final action = find.widgetWithText(TextButton, l10n.contactAdministration);
    expect(action, findsOneWidget);

    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.byType(AppPopup), findsOneWidget);
    expect(find.text(l10n.createAccountTitle), findsOneWidget);
    expect(find.text(l10n.createAccountMessage), findsOneWidget);

    await tester.tap(find.text(l10n.close));
    await tester.pumpAndSettle();
    expect(find.byType(AppPopup), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  group('debug preview (temporary)', () {
    final previewButton = find.text(l10n.debugPreviewButton);

    testWidgets('debug build: button opens the real shell, session untouched', (
      tester,
    ) async {
      // Widget tests run in debug mode, so the button is available.
      await launch(tester);
      expect(previewButton, findsOneWidget);
      expect(find.text(l10n.debugPreviewNote), findsOneWidget);
      final session = tester
          .element(find.byType(LoginScreen))
          .read<AppSessionCubit>();

      await tester.ensureVisible(previewButton);
      await tester.tap(previewButton);
      await tester.pumpAndSettle();

      // The real shell and its real Home branch, with the bar.
      expect(find.byType(AppNavBar), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(MainNavigationBar), findsOneWidget);
      // Nobody was signed in and nothing was fabricated.
      expect(session.state, isA<SessionUnauthenticated>());
      expect(repo.signInCalls, 0);
      expect(repo.userCalls, 0);
      expect(repo.hasSession, isFalse);
    });

    testWidgets('simulated release: no button, shell routes stay protected', (
      tester,
    ) async {
      await launch(tester, preview: DebugShellPreview(allowed: false));
      expect(previewButton, findsNothing);
      expect(find.text(l10n.debugPreviewNote), findsNothing);

      final router = GoRouter.of(tester.element(find.byType(LoginScreen)));
      for (final path in mainShellRoutes) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget, reason: path);
        expect(find.byType(AppNavBar), findsNothing, reason: path);
      }
    });

    testWidgets('without pressing the button, shell routes stay protected', (
      tester,
    ) async {
      await launch(tester);
      final router = GoRouter.of(tester.element(find.byType(LoginScreen)));
      router.go(mainShellRoutes.first);
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(AppNavBar), findsNothing);
    });
  });

  // Task 11: both fields share one style; the username is typed LTR with
  // keyboard assistance off; the password keeps its privacy behavior.
  group('field consistency and username input', () {
    /// The decoration the field actually renders with.
    InputDecoration decorationOf(WidgetTester tester, String label) => tester
        .widget<InputDecorator>(
          find.descendant(
            of: field(label),
            matching: find.byType(InputDecorator),
          ),
        )
        .decoration;

    EditableText editableOf(WidgetTester tester, String label) =>
        tester.widget<EditableText>(
          find.descendant(
            of: field(label),
            matching: find.byType(EditableText),
          ),
        );

    testWidgets('username and password borders match in every state', (
      tester,
    ) async {
      await launch(tester);
      // Show errors too, so the rendered error borders are exercised.
      await submit(tester);
      final user = decorationOf(tester, l10n.usernameLabel);
      final pass = decorationOf(tester, l10n.passwordLabel);
      final defaults = AppTextFieldStyle.defaultsOf(AppTheme.light);

      final states = <String, InputBorder? Function(InputDecoration)>{
        'border': (d) => d.border,
        'enabled': (d) => d.enabledBorder,
        'focused': (d) => d.focusedBorder,
        'error': (d) => d.errorBorder,
        'focusedError': (d) => d.focusedErrorBorder,
        'disabled': (d) => d.disabledBorder,
      };
      for (final e in states.entries) {
        expect(e.value(user), e.value(pass), reason: e.key);
      }
      expect(user.fillColor, pass.fillColor);

      // The shared defaults, not a per-call override.
      OutlineInputBorder outline(InputBorder? b) => b! as OutlineInputBorder;
      expect(
        outline(user.enabledBorder).borderSide.color,
        AppColor.inputBorder,
      );
      expect(
        outline(user.enabledBorder).borderSide.width,
        defaults.borderWidth,
      );
      expect(outline(user.focusedBorder).borderSide.color, AppColor.primary);
      expect(
        outline(user.focusedBorder).borderSide.width,
        defaults.focusedBorderWidth,
      );
      expect(
        outline(user.errorBorder).borderSide.color,
        defaults.errorBorderColor,
      );
      expect(
        outline(user.disabledBorder).borderSide.color,
        defaults.disabledBorderColor,
      );
      // Same typed-text style for both.
      expect(
        editableOf(tester, l10n.usernameLabel).style,
        editableOf(tester, l10n.passwordLabel).style,
      );
    });

    testWidgets('username text is LTR; label, error and icon stay RTL', (
      tester,
    ) async {
      await launch(tester);
      final editable = editableOf(tester, l10n.usernameLabel);
      expect(editable.textDirection, TextDirection.ltr);
      expect(editable.textAlign, TextAlign.start);
      expect(editable.autocorrect, isFalse);
      expect(editable.enableSuggestions, isFalse);
      // No caller formatter that could transform or strip characters
      // (Flutter's own single-line newline filter is not the caller's).
      final appField = tester.widget<AppTextFormField>(
        find.widgetWithText(AppTextFormField, l10n.usernameLabel),
      );
      expect(appField.inputFormatters, isNull);

      // Surroundings follow the Arabic screen.
      final label = find.descendant(
        of: field(l10n.usernameLabel),
        matching: find.text(l10n.usernameLabel),
      );
      expect(Directionality.of(tester.element(label)), TextDirection.rtl);
      final box = tester.getRect(field(l10n.usernameLabel));
      final icon = tester.getCenter(find.byIcon(Icons.person_outline));
      expect(icon.dx, greaterThan(box.center.dx), reason: 'icon on the right');

      await submit(tester);
      final error = find.text(l10n.usernameRequired);
      expect(Directionality.of(tester.element(error)), TextDirection.rtl);
      expect(
        tester.getRect(error).right,
        greaterThan(box.center.dx),
        reason: 'error starts on the right',
      );
    });

    // Expected submitted value for each typed username (D-A65 unchanged).
    const usernames = {
      '_ali': '_ali',
      'captain.': 'captain.',
      'captain_01': 'captain_01',
      '0791234567': '0791234567',
      '٠٧٩١٢٣٤٥٦٧': '0791234567',
    };
    for (final entry in usernames.entries) {
      testWidgets('username "${entry.key}" renders LTR and submits as typed', (
        tester,
      ) async {
        await launch(tester);
        // Stay on Login afterwards so the field can be inspected.
        repo.signInError = const InvalidCredentialsException();
        await tester.enterText(field(l10n.usernameLabel), entry.key);
        await tester.pump();

        // First character at the left, last at the right: real LTR order,
        // so a leading `_` or trailing `.` is not moved by the RTL screen.
        final state = tester.state<EditableTextState>(
          find.descendant(
            of: field(l10n.usernameLabel),
            matching: find.byType(EditableText),
          ),
        );
        final render = state.renderEditable;
        final first = render.getLocalRectForCaret(
          const TextPosition(offset: 0),
        );
        final last = render.getLocalRectForCaret(
          TextPosition(offset: entry.key.length),
        );
        expect(first.left, lessThan(last.left));
        expect(first.left, lessThan(render.size.width / 2));

        await tester.enterText(field(l10n.passwordLabel), 'secret123');
        await submit(tester);
        expect(repo.signInCalls, 1);
        expect(repo.lastUsername, entry.value);
        // The field still shows exactly what was typed.
        expect(state.widget.controller.text, entry.key);
      });
    }

    testWidgets('password keeps its privacy and toggle behavior', (
      tester,
    ) async {
      await launch(tester);
      await tester.enterText(field(l10n.passwordLabel), 'secret123');
      await tester.pump();
      var editable = editableOf(tester, l10n.passwordLabel);
      expect(editable.obscureText, isTrue);
      expect(editable.autocorrect, isFalse);
      expect(editable.enableSuggestions, isFalse);
      // Not forced LTR: it inherits the screen direction as before.
      expect(editable.textDirection, isNull);
      final password = tester.state<EditableTextState>(
        find.descendant(
          of: field(l10n.passwordLabel),
          matching: find.byType(EditableText),
        ),
      );
      expect(password.renderEditable.textDirection, TextDirection.rtl);

      await tester.tap(find.byTooltip(l10n.showPassword));
      await tester.pump();
      editable = editableOf(tester, l10n.passwordLabel);
      expect(editable.obscureText, isFalse);
      expect(editable.controller.text, 'secret123');
      await tester.tap(find.byTooltip(l10n.hidePassword));
      await tester.pump();
      expect(editableOf(tester, l10n.passwordLabel).obscureText, isTrue);
    });
  });

  // Task 17: Login popups opened while the keyboard is open (they do not
  // dismiss it) fit at large text sizes.
  group('popups with the keyboard open', () {
    for (final scale in [2.0, 3.0]) {
      for (final entry in {
        'forgot password': () => l10n.forgotPassword,
        'create account': () => l10n.contactAdministration,
      }.entries) {
        testWidgets('${entry.key}, 320 px, scale $scale: fits and closes', (
          tester,
        ) async {
          setScreenSize(tester, 320, 568);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await launch(tester);
          await tester.ensureVisible(field(l10n.usernameLabel));
          await tester.pumpAndSettle();
          await tester.tap(field(l10n.usernameLabel));
          tester.view.viewInsets = const FakeViewPadding(bottom: 260);
          addTearDown(tester.view.resetViewInsets);
          await tester.pumpAndSettle();

          final action = find.text(entry.value());
          await tester.ensureVisible(action);
          await tester.pumpAndSettle();
          await tester.tap(action);
          await tester.pumpAndSettle();
          expect(find.byType(AppPopup), findsOneWidget);
          expect(tester.takeException(), isNull);
          // Keyboard still open: the popup did not rely on dismissing it.
          expect(tester.view.viewInsets.bottom, 260);

          final close = find.widgetWithText(FilledButton, l10n.close);
          await tester.ensureVisible(close);
          await tester.pumpAndSettle();
          await tester.tap(close);
          await tester.pumpAndSettle();
          expect(find.byType(AppPopup), findsNothing);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  // Task 13: the Terms & Conditions action (in-app only; no URL yet).
  group('Terms & Conditions', () {
    Finder terms() =>
        find.widgetWithText(AppTextButton, l10n.termsAndConditions);

    /// Login with an injected [legal] launcher (the router always uses the
    /// central configuration, which has no URL yet).
    Future<void> pumpLogin(WidgetTester tester, LegalPageLauncher legal) async {
      final session = AppSessionCubit(SignOut(repo));
      addTearDown(session.close);
      await tester.pumpWidget(
        testApp(
          BlocProvider(
            create: (_) =>
                LoginCubit(SignIn(repo, GetCurrentUser(repo)), session),
            child: LoginScreen(legalPageLauncher: legal),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    LegalPageLauncher configured(FakeInAppWebPageLauncher fake) =>
        LegalPageLauncher(
          launcher: fake,
          termsUrl: 'https://legal.test.invalid/terms-test',
          platform: TargetPlatform.android,
        );

    testWidgets('shared AppTextButton with the ARB label, enabled', (
      tester,
    ) async {
      await launch(tester);
      expect(terms(), findsOneWidget);
      expect(l10n.termsAndConditions, 'الشروط والأحكام');
      final button = tester.widget<AppTextButton>(terms());
      expect(button.onPressed, isNotNull);
      expect(button.color, isNull, reason: 'theme default, no custom color');
      // Not a consent control: no checkbox anywhere on Login.
      expect(find.byType(Checkbox), findsNothing);
      expect(find.byType(CheckboxListTile), findsNothing);
    });

    testWidgets('below the no-account action, above the debug preview', (
      tester,
    ) async {
      await launch(tester);
      final contact = tester.getRect(find.text(l10n.contactAdministration));
      final legal = tester.getRect(terms());
      final preview = tester.getRect(find.text(l10n.debugPreviewButton));
      expect(legal.top, greaterThanOrEqualTo(contact.bottom));
      expect(preview.top, greaterThan(legal.bottom));
      // Horizontally centered like the no-account row.
      final screen = tester.getRect(find.byType(LoginScreen));
      expect((legal.center.dx - screen.center.dx).abs(), lessThan(1));
    });

    testWidgets('no URL yet → truthful popup; closes back to Login', (
      tester,
    ) async {
      await launch(tester);
      await tester.ensureVisible(terms());
      await tester.tap(terms());
      await tester.pumpAndSettle();
      expect(find.byType(AppPopup), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppPopup),
          matching: find.text(l10n.termsAndConditions),
        ),
        findsOneWidget,
      );
      expect(find.text(l10n.termsUnavailableMessage), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, l10n.close));
      await tester.pumpAndSettle();
      expect(find.byType(AppPopup), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(repo.signInCalls, 0);
    });

    testWidgets('configured: opens in-app once, no popup', (tester) async {
      final fake = FakeInAppWebPageLauncher();
      await pumpLogin(tester, configured(fake));
      await tester.ensureVisible(terms());
      await tester.tap(terms());
      await tester.pumpAndSettle();
      expect(fake.opened, [Uri.parse('https://legal.test.invalid/terms-test')]);
      expect(find.byType(AppPopup), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('a second tap while opening does not open twice', (
      tester,
    ) async {
      final fake = FakeInAppWebPageLauncher()..pending = Completer<bool>();
      await pumpLogin(tester, configured(fake));
      await tester.ensureVisible(terms());
      await tester.tap(terms());
      await tester.pump();
      await tester.tap(terms());
      await tester.pump();
      expect(fake.opened, hasLength(1));
      fake.pending!.complete(true);
      await tester.pumpAndSettle();
      expect(find.byType(AppPopup), findsNothing);
    });

    final failures = <String, FakeInAppWebPageLauncher Function()>{
      'in-app mode unsupported': () =>
          FakeInAppWebPageLauncher(supports: false),
      'presentation refused': () => FakeInAppWebPageLauncher(opens: false),
      'platform error': () =>
          FakeInAppWebPageLauncher()..error = PlatformException(code: 'x'),
    };
    for (final entry in failures.entries) {
      testWidgets('${entry.key} → failure popup, no other attempt', (
        tester,
      ) async {
        final fake = entry.value();
        await pumpLogin(tester, configured(fake));
        await tester.ensureVisible(terms());
        await tester.tap(terms());
        await tester.pumpAndSettle();
        expect(fake.opened.length, lessThanOrEqualTo(1));
        expect(find.text(l10n.termsOpenFailedMessage), findsOneWidget);
        expect(find.byType(LoginScreen), findsOneWidget);
      });
    }

    testWidgets('invalid configured URL → failure popup, nothing opened', (
      tester,
    ) async {
      final fake = FakeInAppWebPageLauncher();
      await pumpLogin(
        tester,
        LegalPageLauncher(
          launcher: fake,
          termsUrl: 'http://legal.test.invalid/terms',
          platform: TargetPlatform.android,
        ),
      );
      await tester.ensureVisible(terms());
      await tester.tap(terms());
      await tester.pumpAndSettle();
      expect(fake.opened, isEmpty);
      expect(find.text(l10n.termsOpenFailedMessage), findsOneWidget);
    });

    testWidgets('screen reader: an enabled button named by the label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await launch(tester);
      expect(
        tester.getSemantics(
          find.descendant(of: terms(), matching: find.byType(TextButton)),
        ),
        isSemantics(
          label: l10n.termsAndConditions,
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    for (final scale in [1.0, 2.0, 3.0]) {
      testWidgets('320 px, text scale $scale, keyboard open: reachable', (
        tester,
      ) async {
        setScreenSize(tester, 320, 568);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await launch(tester);
        // A focused field with the keyboard open.
        await tester.ensureVisible(field(l10n.usernameLabel));
        await tester.pumpAndSettle();
        await tester.tap(field(l10n.usernameLabel));
        final usernameFocus = tester
            .widget<EditableText>(
              find.descendant(
                of: field(l10n.usernameLabel),
                matching: find.byType(EditableText),
              ),
            )
            .focusNode;
        expect(usernameFocus.hasFocus, isTrue);
        tester.view.viewInsets = const FakeViewPadding(bottom: 260);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.ensureVisible(terms());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(tester.getSize(terms()).height, greaterThanOrEqualTo(48));
        expect(tester.getRect(terms()).right, lessThanOrEqualTo(320));

        await tester.tap(terms());
        // The action unfocuses the field, so the system keyboard closes.
        expect(usernameFocus.hasFocus, isFalse);
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        expect(find.text(l10n.termsUnavailableMessage), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('responsive', () {
    for (final width in [
      320.0,
      375.0,
      450.5,
      600.0,
      800.5,
      840.0,
      1024.0,
      1440.0,
      1920.5,
    ]) {
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
        // The added actions fit too.
        expect(find.text(l10n.contactAdministration), findsOneWidget);
        expect(find.text(l10n.debugPreviewButton), findsOneWidget);
      });
    }

    testWidgets('landscape phone: scrolls, no overflow', (tester) async {
      setScreenSize(tester, 740, 360);
      await launch(tester);
      await tester.ensureVisible(find.text(l10n.debugPreviewButton));
      expect(tester.takeException(), isNull);
    });

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
