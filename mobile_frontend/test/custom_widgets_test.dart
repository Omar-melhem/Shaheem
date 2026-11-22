// Widget tests for the shared custom components: AppTextFormField,
// AppButton, AppTextButton, AppPopup, AppToast and AppStatusMessage, in
// Arabic RTL.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_frontend/helper/translation/generated/app_localizations.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/theme/app_theme.dart';
import 'package:mobile_frontend/util/fonts.dart';
import 'package:mobile_frontend/view/widget/buttons/app_button.dart';
import 'package:mobile_frontend/view/widget/buttons/app_icon_position.dart';
import 'package:mobile_frontend/view/widget/buttons/app_text_button.dart';
import 'package:mobile_frontend/view/widget/pop_up_screen/app_popup.dart';
import 'package:mobile_frontend/view/widget/status/app_status_message.dart';
import 'package:mobile_frontend/view/widget/text_field/app_text_form_field.dart';
import 'package:mobile_frontend/view/widget/toast/app_toast.dart';

import 'test_app.dart';

/// Pumps [child] centered in the shared Arabic test host.
Future<void> pump(WidgetTester tester, Widget child) =>
    tester.pumpWidget(testApp(Center(child: child)));

/// Builder that exposes a context inside the host (for show* helpers).
Widget contextProbe(void Function(BuildContext) onBuild) => Builder(
  builder: (context) {
    onBuild(context);
    return const SizedBox();
  },
);

void main() {
  group('AppTextFormField', () {
    /// The effective decoration Flutter renders (after errorText merging).
    InputDecoration decoration(WidgetTester tester) =>
        tester.widget<InputDecorator>(find.byType(InputDecorator)).decoration;

    EditableText editable(WidgetTester tester) =>
        tester.widget<EditableText>(find.byType(EditableText));

    BorderSide side(InputBorder? border) =>
        (border! as OutlineInputBorder).borderSide;

    group('contract', () {
      testWidgets('blank or whitespace-only label is rejected', (tester) async {
        for (final blank in ['', '   ']) {
          await pump(
            tester,
            SizedBox(width: 300, child: AppTextFormField(label: blank)),
          );
          expect(tester.takeException(), isAssertionError, reason: '"$blank"');
        }
      });

      test('controller and initialValue cannot both be supplied', () {
        expect(
          () => AppTextFormField(
            label: 'L',
            controller: TextEditingController(),
            initialValue: 'x',
          ),
          throwsAssertionError,
        );
      });

      test('obscured fields must be single-line', () {
        expect(
          () => AppTextFormField(label: 'L', obscureText: true, maxLines: 2),
          throwsAssertionError,
        );
        expect(
          () => AppTextFormField(label: 'L', obscureText: true, minLines: 2),
          throwsAssertionError,
        );
      });

      test('minLines must not exceed maxLines', () {
        expect(
          () => AppTextFormField(label: 'L', minLines: 3, maxLines: 2),
          throwsAssertionError,
        );
      });

      test('endIcon conflicts with the visibility toggle', () {
        expect(
          () => AppTextFormField(
            label: 'L',
            obscureText: true,
            endIcon: const Icon(Icons.info),
          ),
          throwsAssertionError,
        );
      });

      test('obscured fields cannot enable autocorrect or suggestions', () {
        expect(
          () => AppTextFormField(
            label: 'L',
            obscureText: true,
            autocorrect: true,
          ),
          throwsAssertionError,
        );
        expect(
          () => AppTextFormField(
            label: 'L',
            obscureText: true,
            enableSuggestions: true,
          ),
          throwsAssertionError,
        );
      });
    });

    testWidgets('shows label, hint, helper and external error', (tester) async {
      await pump(
        tester,
        const SizedBox(
          width: 300,
          child: AppTextFormField(
            label: 'L',
            hint: 'H',
            helperText: 'Help',
            errorText: 'Err',
          ),
        ),
      );
      expect(find.text('L'), findsOneWidget);
      expect(find.text('Err'), findsOneWidget);
      // Flutter replaces helper text with the error while an error shows.
      expect(find.text('Help'), findsNothing);
    });

    testWidgets('label is the accessible name of the text field', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        const SizedBox(width: 300, child: AppTextFormField(label: 'Name')),
      );
      expect(
        tester.getSemantics(find.byType(EditableText)),
        isSemantics(label: 'Name', isTextField: true),
      );
      handle.dispose();
    });

    testWidgets('start icon is on the right in RTL, end icon on the left', (
      tester,
    ) async {
      await pump(
        tester,
        const SizedBox(
          width: 300,
          child: AppTextFormField(
            label: 'L',
            startIcon: Icon(Icons.person),
            endIcon: Icon(Icons.search),
          ),
        ),
      );
      final start = tester.getCenter(find.byIcon(Icons.person));
      final end = tester.getCenter(find.byIcon(Icons.search));
      expect(start.dx, greaterThan(end.dx));
    });

    testWidgets('textDirection changes only the typed text, not the slots', (
      tester,
    ) async {
      await pump(
        tester,
        const SizedBox(
          width: 300,
          child: AppTextFormField(
            label: 'L',
            textDirection: TextDirection.ltr,
            startIcon: Icon(Icons.person),
            endIcon: Icon(Icons.search),
          ),
        ),
      );
      expect(editable(tester).textDirection, TextDirection.ltr);
      final start = tester.getCenter(find.byIcon(Icons.person));
      final end = tester.getCenter(find.byIcon(Icons.search));
      expect(start.dx, greaterThan(end.dx), reason: 'slots stay RTL');

      // Default: the typed text inherits the app direction.
      await pump(
        tester,
        const SizedBox(width: 300, child: AppTextFormField(label: 'L')),
      );
      expect(editable(tester).textDirection, isNull);
      expect(
        Directionality.of(tester.element(find.byType(EditableText))),
        TextDirection.rtl,
      );
    });

    testWidgets('caller IconButton in endIcon keeps its tooltip and action', (
      tester,
    ) async {
      var taps = 0;
      await pump(
        tester,
        SizedBox(
          width: 300,
          child: AppTextFormField(
            label: 'L',
            endIcon: IconButton(
              onPressed: () => taps++,
              tooltip: 'Clear',
              icon: const Icon(Icons.close),
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Clear'));
      expect(taps, 1);
    });

    testWidgets('obscured field without toggle may use endIcon', (
      tester,
    ) async {
      await pump(
        tester,
        const SizedBox(
          width: 300,
          child: AppTextFormField(
            label: 'L',
            obscureText: true,
            showVisibilityToggle: false,
            endIcon: Icon(Icons.info),
          ),
        ),
      );
      expect(find.byIcon(Icons.info), findsOneWidget);
      expect(find.byTooltip(l10n.showPassword), findsNothing);
      expect(editable(tester).obscureText, isTrue);
    });

    group('password visibility', () {
      testWidgets('toggle shows/hides without changing the value', (
        tester,
      ) async {
        final controller = TextEditingController(text: 'secret');
        addTearDown(controller.dispose);
        await pump(
          tester,
          SizedBox(
            width: 300,
            child: AppTextFormField(
              label: 'L',
              controller: controller,
              obscureText: true,
            ),
          ),
        );
        expect(editable(tester).obscureText, isTrue);

        await tester.tap(find.byTooltip(l10n.showPassword));
        await tester.pump();
        expect(editable(tester).obscureText, isFalse);
        expect(controller.text, 'secret');

        await tester.tap(find.byTooltip(l10n.hidePassword));
        await tester.pump();
        expect(editable(tester).obscureText, isTrue);
        expect(controller.text, 'secret');
      });

      testWidgets('toggle is disabled on a disabled field', (tester) async {
        await pump(
          tester,
          const SizedBox(
            width: 300,
            child: AppTextFormField(
              label: 'L',
              obscureText: true,
              enabled: false,
            ),
          ),
        );
        final toggle = tester.widget<IconButton>(find.byType(IconButton));
        expect(toggle.onPressed, isNull);
        await tester.tap(find.byType(IconButton), warnIfMissed: false);
        await tester.pump();
        expect(editable(tester).obscureText, isTrue);
      });

      testWidgets('toggle stays usable on a read-only field', (tester) async {
        await pump(
          tester,
          const SizedBox(
            width: 300,
            child: AppTextFormField(
              label: 'L',
              obscureText: true,
              readOnly: true,
            ),
          ),
        );
        await tester.tap(find.byTooltip(l10n.showPassword));
        await tester.pump();
        expect(editable(tester).obscureText, isFalse);
      });

      testWidgets('visibility resets when the parent changes obscureText', (
        tester,
      ) async {
        Widget field(bool obscure) => SizedBox(
          width: 300,
          child: AppTextFormField(label: 'L', obscureText: obscure),
        );
        await pump(tester, field(true));
        await tester.tap(find.byTooltip(l10n.showPassword));
        await tester.pump();
        expect(editable(tester).obscureText, isFalse);

        await pump(tester, field(false));
        expect(editable(tester).obscureText, isFalse);
        await pump(tester, field(true));
        expect(editable(tester).obscureText, isTrue);
      });
    });

    group('keyboard assistance', () {
      testWidgets('defaults: on for plain fields, off for obscured ones', (
        tester,
      ) async {
        await pump(
          tester,
          const SizedBox(width: 300, child: AppTextFormField(label: 'L')),
        );
        expect(editable(tester).autocorrect, isTrue);
        expect(editable(tester).enableSuggestions, isTrue);

        await pump(
          tester,
          const SizedBox(
            width: 300,
            child: AppTextFormField(label: 'L', obscureText: true),
          ),
        );
        expect(editable(tester).autocorrect, isFalse);
        expect(editable(tester).enableSuggestions, isFalse);
      });

      testWidgets('autocorrect and suggestions are independent', (
        tester,
      ) async {
        await pump(
          tester,
          const SizedBox(
            width: 300,
            child: AppTextFormField(label: 'L', autocorrect: false),
          ),
        );
        expect(editable(tester).autocorrect, isFalse);
        expect(editable(tester).enableSuggestions, isTrue);

        await pump(
          tester,
          const SizedBox(
            width: 300,
            child: AppTextFormField(label: 'L', enableSuggestions: false),
          ),
        );
        expect(editable(tester).autocorrect, isTrue);
        expect(editable(tester).enableSuggestions, isFalse);
      });
    });

    testWidgets('read-only is focusable but not editable; disabled is not', (
      tester,
    ) async {
      String? changed;
      await pump(
        tester,
        SizedBox(
          width: 300,
          child: AppTextFormField(label: 'L', onChanged: (v) => changed = v),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'abc');
      expect(changed, 'abc');

      await pump(
        tester,
        const SizedBox(
          width: 300,
          child: AppTextFormField(label: 'L', readOnly: true),
        ),
      );
      var field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enabled, isTrue);
      expect(field.readOnly, isTrue);
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(editable(tester).focusNode.hasFocus, isTrue);

      await pump(
        tester,
        const SizedBox(
          width: 300,
          child: AppTextFormField(label: 'L', enabled: false),
        ),
      );
      field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enabled, isFalse);
      await tester.tap(find.byType(TextField), warnIfMissed: false);
      await tester.pump();
      expect(editable(tester).focusNode.hasFocus, isFalse);
    });

    testWidgets('a validator error takes priority over errorText', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      await pump(
        tester,
        SizedBox(
          width: 300,
          child: Form(
            key: formKey,
            child: AppTextFormField(
              label: 'L',
              errorText: 'Cubit error',
              validator: (_) => 'Local error',
            ),
          ),
        ),
      );
      expect(find.text('Cubit error'), findsOneWidget);

      formKey.currentState!.validate();
      await tester.pump();
      expect(find.text('Local error'), findsOneWidget);
      expect(find.text('Cubit error'), findsNothing);
    });

    group('appearance', () {
      testWidgets(
        'defaults: input border token, brand focus, legacy error/disabled',
        (tester) async {
          await pump(
            tester,
            const SizedBox(width: 300, child: AppTextFormField(label: 'L')),
          );
          final colors = AppTheme.light.colorScheme;
          final d = decoration(tester);

          expect(
            side(d.border),
            const BorderSide(color: AppColor.inputOutline),
          );
          expect(
            side(d.enabledBorder),
            const BorderSide(color: AppColor.inputOutline),
          );
          // D-A69: dark focus outline with a wider stroke (not color alone).
          expect(
            side(d.focusedBorder),
            const BorderSide(color: AppColor.focus, width: 2),
          );
          expect(side(d.errorBorder), BorderSide(color: colors.error));
          expect(
            side(d.focusedErrorBorder),
            BorderSide(color: colors.error, width: 2),
          );
          expect(colors.error, AppColor.error);
          // D-A69 disabled field boundary.
          expect(
            side(d.disabledBorder),
            const BorderSide(color: AppColor.divider),
          );
          expect(
            (d.enabledBorder! as OutlineInputBorder).borderRadius,
            BorderRadius.circular(12),
          );
          expect(d.filled, isTrue);
          expect(d.fillColor, colors.surface);
          expect(
            d.contentPadding,
            const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 14),
          );
          expect(d.errorMaxLines, 3);
        },
      );

      testWidgets('every border color and width override is rendered', (
        tester,
      ) async {
        await pump(
          tester,
          const SizedBox(
            width: 300,
            child: AppTextFormField(
              label: 'L',
              style: AppTextFieldStyle(
                borderColor: AppColor.warning,
                borderWidth: 3,
                focusedBorderColor: AppColor.success,
                focusedBorderWidth: 4,
                errorBorderColor: AppColor.onPrimaryContainer,
                errorBorderWidth: 5,
                focusedErrorBorderColor: AppColor.primaryPressed,
                focusedErrorBorderWidth: 6,
                disabledBorderColor: AppColor.divider,
                disabledBorderWidth: 7,
                borderRadius: 4,
              ),
            ),
          ),
        );
        final d = decoration(tester);
        expect(
          side(d.enabledBorder),
          const BorderSide(color: AppColor.warning, width: 3),
        );
        expect(side(d.border), side(d.enabledBorder));
        expect(
          side(d.focusedBorder),
          const BorderSide(color: AppColor.success, width: 4),
        );
        expect(
          side(d.errorBorder),
          const BorderSide(color: AppColor.onPrimaryContainer, width: 5),
        );
        expect(
          side(d.focusedErrorBorder),
          const BorderSide(color: AppColor.primaryPressed, width: 6),
        );
        expect(
          side(d.disabledBorder),
          const BorderSide(color: AppColor.divider, width: 7),
        );
        expect(
          (d.focusedBorder! as OutlineInputBorder).borderRadius,
          BorderRadius.circular(4),
        );
      });

      testWidgets('borderWidth changes only the resting border', (
        tester,
      ) async {
        await pump(
          tester,
          const SizedBox(
            width: 300,
            child: AppTextFormField(
              label: 'L',
              style: AppTextFieldStyle(borderWidth: 2),
            ),
          ),
        );
        final d = decoration(tester);
        expect(
          side(d.enabledBorder),
          const BorderSide(color: AppColor.inputOutline, width: 2),
        );
        expect(side(d.focusedBorder).width, 2);
        expect(side(d.errorBorder).width, 1);
        expect(side(d.disabledBorder).width, 1);
      });

      testWidgets('text styles, fill, cursor, padding and error lines apply', (
        tester,
      ) async {
        const text = TextStyle(color: AppColor.success, fontSize: 18);
        const label = TextStyle(color: AppColor.primary);
        const floating = TextStyle(color: AppColor.onPrimaryContainer);
        const hint = TextStyle(color: AppColor.textSecondary);
        const helper = TextStyle(color: AppColor.warning);
        const error = TextStyle(color: AppColor.onPrimaryContainer);
        const padding = EdgeInsetsDirectional.only(start: 4, end: 8);
        await pump(
          tester,
          const SizedBox(
            width: 300,
            child: AppTextFormField(
              label: 'L',
              errorText: 'Err',
              style: AppTextFieldStyle(
                textStyle: text,
                labelStyle: label,
                floatingLabelStyle: floating,
                hintStyle: hint,
                helperStyle: helper,
                errorStyle: error,
                errorMaxLines: 5,
                fillColor: AppColor.background,
                cursorColor: AppColor.success,
                contentPadding: padding,
              ),
            ),
          ),
        );
        final d = decoration(tester);
        expect(d.labelStyle, label);
        expect(d.floatingLabelStyle, floating);
        expect(d.hintStyle, hint);
        expect(d.helperStyle, helper);
        expect(d.errorStyle, error);
        expect(d.errorMaxLines, 5);
        expect(d.fillColor, AppColor.background);
        expect(d.contentPadding, padding);
        expect(editable(tester).style.color, AppColor.success);
        expect(editable(tester).style.fontSize, 18);
        // While an error shows, Flutter colors the cursor with errorStyle.
        expect(editable(tester).cursorColor, AppColor.onPrimaryContainer);

        await pump(
          tester,
          const SizedBox(
            width: 300,
            child: AppTextFormField(
              label: 'L',
              style: AppTextFieldStyle(cursorColor: AppColor.success),
            ),
          ),
        );
        expect(editable(tester).cursorColor, AppColor.success);
      });
    });

    group('AppTextFieldStyle.merge', () {
      test('non-null values win; null never erases', () {
        const base = AppTextFieldStyle(
          borderColor: AppColor.warning,
          borderWidth: 1,
          fillColor: AppColor.surface,
        );
        final merged = base.merge(
          const AppTextFieldStyle(
            borderWidth: 2,
            cursorColor: AppColor.primary,
          ),
        );
        expect(merged.borderWidth, 2);
        expect(merged.cursorColor, AppColor.primary);
        expect(merged.borderColor, AppColor.warning);
        expect(merged.fillColor, AppColor.surface);
        expect(identical(base.merge(null), base), isTrue);
      });

      test('defaultsOf fills every border property', () {
        final d = AppTextFieldStyle.defaultsOf(AppTheme.light);
        for (final value in [
          d.borderColor,
          d.borderWidth,
          d.focusedBorderColor,
          d.focusedBorderWidth,
          d.errorBorderColor,
          d.errorBorderWidth,
          d.focusedErrorBorderColor,
          d.focusedErrorBorderWidth,
          d.disabledBorderColor,
          d.disabledBorderWidth,
          d.borderRadius,
        ]) {
          expect(value, isNotNull);
        }
      });
    });

    group('layout', () {
      for (final scale in [2.0, 3.0]) {
        testWidgets('320 px wide at text scale $scale renders without errors', (
          tester,
        ) async {
          setScreenSize(tester, 320, 640);
          await tester.pumpWidget(
            testApp(
              Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: const [
                      AppTextFormField(
                        label: 'Label',
                        errorText:
                            'A long error message that has to wrap over '
                            'several lines on a narrow screen',
                        obscureText: true,
                        startIcon: Icon(Icons.lock_outline),
                      ),
                      AppTextFormField(
                        label: 'Label',
                        helperText: 'Helper',
                        startIcon: Icon(Icons.person_outline),
                        endIcon: Icon(Icons.search),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull);
          expect(find.byType(AppTextFormField), findsNWidgets(2));
        });
      }
    });
  });

  group('AppButton', () {
    testWidgets('calls onPressed; null callback is disabled', (tester) async {
      var taps = 0;
      await pump(tester, AppButton(label: 'Go', onPressed: () => taps++));
      await tester.tap(find.text('Go'));
      expect(taps, 1);

      await pump(tester, const AppButton(label: 'Go', onPressed: null));
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('loading shows a spinner and ignores repeated taps', (
      tester,
    ) async {
      var taps = 0;
      await pump(
        tester,
        AppButton(label: 'Go', isLoading: true, onPressed: () => taps++),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      expect(taps, 0);
    });

    testWidgets('loading keeps the button size (no layout jump)', (
      tester,
    ) async {
      await pump(tester, AppButton(label: 'Login now', onPressed: () {}));
      final idle = tester.getSize(find.byType(FilledButton));
      await pump(
        tester,
        AppButton(label: 'Login now', isLoading: true, onPressed: () {}),
      );
      expect(tester.getSize(find.byType(FilledButton)), idle);
    });

    testWidgets('icon at logical start is right of the label in RTL', (
      tester,
    ) async {
      await pump(
        tester,
        AppButton(label: 'Go', icon: const Icon(Icons.login), onPressed: () {}),
      );
      expect(
        tester.getCenter(find.byIcon(Icons.login)).dx,
        greaterThan(tester.getCenter(find.text('Go')).dx),
      );
    });

    testWidgets('minimum height is a 48 px touch target', (tester) async {
      await pump(tester, AppButton(label: 'Go', onPressed: () {}));
      expect(tester.getSize(find.byType(FilledButton)).height, 48);
    });

    // Task 18: rendered contract (colors, text, layout, semantics).
    group('rendered contract', () {
      /// Pumps [child] and lets the button's color animations finish
      /// (a spinner never settles, so fixed pumps are used).
      Future<void> show(WidgetTester tester, Widget child) async {
        await pump(tester, child);
        await tester.pump(const Duration(milliseconds: 400));
      }

      TextStyle labelStyle(WidgetTester tester, String text) => tester
          .widget<RichText>(
            find.descendant(
              of: find.text(text),
              matching: find.byType(RichText),
            ),
          )
          .text
          .style!;

      Color? iconColor(WidgetTester tester, IconData icon) => tester
          .widget<RichText>(
            find.descendant(
              of: find.byIcon(icon),
              matching: find.byType(RichText),
            ),
          )
          .text
          .style!
          .color;

      Material surface(WidgetTester tester) => tester.widget<Material>(
        find
            .descendant(
              of: find.byType(FilledButton),
              matching: find.byType(Material),
            )
            .first,
      );

      testWidgets('defaults: primary, white bold 16 Plex label, 48 px', (
        tester,
      ) async {
        await show(tester, AppButton(label: 'Go', onPressed: () {}));
        final style = labelStyle(tester, 'Go');
        expect(style.color, AppTheme.light.colorScheme.onPrimary);
        expect(style.fontWeight, FontWeight.bold);
        expect(style.fontSize, 16);
        expect(style.fontFamily, AppFonts.ibmPlexSansArabic);
        expect(surface(tester).color, AppColor.primary);
        final shape = surface(tester).shape! as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(12));
        expect(shape.side, BorderSide.none);
        expect(tester.getSize(find.byType(FilledButton)).height, 48);
      });

      testWidgets('child-only content renders; both or neither assert', (
        tester,
      ) async {
        await show(
          tester,
          AppButton(onPressed: () {}, child: const Text('Child')),
        );
        expect(find.text('Child'), findsOneWidget);
        expect(() => AppButton(onPressed: () {}), throwsAssertionError);
        expect(
          () => AppButton(
            label: 'Go',
            onPressed: () {},
            child: const Text('Child'),
          ),
          throwsAssertionError,
        );
      });

      testWidgets('a blank label asserts (it is the accessible name)', (
        tester,
      ) async {
        await pump(tester, AppButton(label: '  ', onPressed: () {}));
        expect(tester.takeException(), isA<AssertionError>());
      });

      test('invalid sizes and conflicting width/expand assert', () {
        void noop() {}
        expect(
          () => AppButton(label: 'Go', onPressed: noop, expand: true, width: 9),
          throwsAssertionError,
        );
        expect(
          () => AppButton(label: 'Go', onPressed: noop, width: 0),
          throwsAssertionError,
        );
        expect(
          () => AppButton(label: 'Go', onPressed: noop, height: -1),
          throwsAssertionError,
        );
        expect(
          () => AppButton(label: 'Go', onPressed: noop, borderRadius: -1),
          throwsAssertionError,
        );
      });

      testWidgets('textStyle merges: size changes, bold and Plex stay', (
        tester,
      ) async {
        await show(
          tester,
          AppButton(
            label: 'Go',
            onPressed: () {},
            textStyle: const TextStyle(fontSize: 20),
          ),
        );
        var style = labelStyle(tester, 'Go');
        expect(style.fontSize, 20);
        expect(style.fontWeight, FontWeight.bold);
        expect(style.fontFamily, AppFonts.ibmPlexSansArabic);

        await show(
          tester,
          AppButton(
            label: 'Go',
            onPressed: () {},
            textStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
            ),
          ),
        );
        style = labelStyle(tester, 'Go');
        expect(style.fontWeight, FontWeight.w500);
        expect(style.decoration, TextDecoration.underline);
        expect(style.fontSize, 16);
        expect(style.fontFamily, AppFonts.ibmPlexSansArabic);
      });

      testWidgets('color precedence: foregroundColor > textStyle.color > '
          'onPrimary, for label, icon and spinner', (tester) async {
        await show(
          tester,
          AppButton(
            label: 'Go',
            icon: const Icon(Icons.add),
            textStyle: const TextStyle(color: AppColor.primaryContainer),
            onPressed: () {},
          ),
        );
        expect(labelStyle(tester, 'Go').color, AppColor.primaryContainer);
        expect(iconColor(tester, Icons.add), AppColor.primaryContainer);

        await show(
          tester,
          AppButton(
            label: 'Go',
            icon: const Icon(Icons.add),
            textStyle: const TextStyle(color: AppColor.primaryContainer),
            foregroundColor: AppColor.success,
            onPressed: () {},
          ),
        );
        expect(labelStyle(tester, 'Go').color, AppColor.success);
        expect(iconColor(tester, Icons.add), AppColor.success);

        await show(
          tester,
          AppButton(
            label: 'Go',
            isLoading: true,
            textStyle: const TextStyle(color: AppColor.primaryContainer),
            onPressed: () {},
          ),
        );
        expect(
          tester
              .widget<CircularProgressIndicator>(
                find.byType(CircularProgressIndicator),
              )
              .color,
          AppColor.primaryContainer,
        );
      });

      testWidgets('an icon with its own color keeps it', (tester) async {
        await show(
          tester,
          AppButton(
            label: 'Go',
            icon: const Icon(Icons.add, color: AppColor.selectedTabContainer),
            foregroundColor: AppColor.success,
            onPressed: () {},
          ),
        );
        expect(iconColor(tester, Icons.add), AppColor.selectedTabContainer);
      });

      testWidgets('background, radius, border and padding render', (
        tester,
      ) async {
        await show(
          tester,
          AppButton(
            label: 'Go',
            onPressed: () {},
            backgroundColor: AppColor.success,
            borderRadius: 4,
            border: const BorderSide(color: AppColor.warning, width: 2),
          ),
        );
        expect(surface(tester).color, AppColor.success);
        final shape = surface(tester).shape! as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(4));
        expect(shape.side, const BorderSide(color: AppColor.warning, width: 2));

        await show(tester, AppButton(label: 'Go', onPressed: () {}));
        final normal = tester.getSize(find.byType(FilledButton));
        await show(
          tester,
          AppButton(
            label: 'Go',
            onPressed: () {},
            padding: const EdgeInsets.all(30),
          ),
        );
        final padded = tester.getSize(find.byType(FilledButton));
        expect(padded.width, greaterThan(normal.width));
        expect(padded.height, greaterThan(normal.height));
      });

      testWidgets('width, height minimum and expand', (tester) async {
        await show(
          tester,
          AppButton(label: 'Go', onPressed: () {}, width: 200),
        );
        expect(tester.getSize(find.byType(FilledButton)).width, 200);
        await show(
          tester,
          AppButton(label: 'Go', onPressed: () {}, height: 64),
        );
        expect(tester.getSize(find.byType(FilledButton)).height, 64);
        await tester.pumpWidget(
          testApp(
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topCenter,
                child: AppButton(label: 'Go', onPressed: () {}, expand: true),
              ),
            ),
          ),
        );
        expect(tester.getSize(find.byType(FilledButton)).width, 800 - 32);
      });

      testWidgets('disabled: Material disabled colors even with custom ones', (
        tester,
      ) async {
        await show(
          tester,
          const AppButton(
            label: 'Go',
            icon: Icon(Icons.add),
            backgroundColor: AppColor.success,
            foregroundColor: AppColor.primaryContainer,
            onPressed: null,
          ),
        );
        // The theme's D-A69 disabled colors win over per-call colors.
        expect(surface(tester).color, AppColor.disabledBackground);
        expect(labelStyle(tester, 'Go').color, AppColor.disabledForeground);
        expect(iconColor(tester, Icons.add), AppColor.disabledForeground);
      });

      testWidgets('semantics: enabled, disabled and loading differ', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await show(tester, AppButton(label: 'Go', onPressed: () {}));
        expect(
          tester.getSemantics(find.byType(FilledButton)),
          isSemantics(
            label: 'Go',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
            isFocusable: true,
          ),
        );
        await show(tester, const AppButton(label: 'Go', onPressed: null));
        expect(
          tester.getSemantics(find.byType(FilledButton)),
          isSemantics(
            label: 'Go',
            isButton: true,
            hasEnabledState: true,
            isEnabled: false,
            hasTapAction: false,
          ),
        );
        for (final callback in <VoidCallback?>[() {}, null]) {
          await show(
            tester,
            AppButton(label: 'Go', isLoading: true, onPressed: callback),
          );
          // Only the loading text is announced (the hidden label is
          // excluded), and no tap action is exposed.
          expect(
            tester.getSemantics(find.byType(FilledButton)),
            isSemantics(
              label: l10n.loading,
              isButton: true,
              isLiveRegion: true,
              hasTapAction: false,
            ),
          );
        }
        handle.dispose();
      });

      for (final direction in TextDirection.values) {
        for (final position in AppIconPosition.values) {
          testWidgets('${direction.name}: icon at ${position.name}', (
            tester,
          ) async {
            await show(
              tester,
              Directionality(
                textDirection: direction,
                child: AppButton(
                  label: 'Go',
                  icon: const Icon(Icons.add),
                  iconPosition: position,
                  onPressed: () {},
                ),
              ),
            );
            final iconX = tester.getCenter(find.byIcon(Icons.add)).dx;
            final textX = tester.getCenter(find.text('Go')).dx;
            final iconOnRight =
                (direction == TextDirection.rtl) ==
                (position == AppIconPosition.start);
            expect(iconOnRight ? iconX > textX : iconX < textX, isTrue);
          });
        }
      }

      const longLabel = 'تسجيل الدخول إلى حساب الكابتن الخاص بك الآن';
      for (final width in [320.0, 375.0, 450.0]) {
        for (final scale in [1.0, 2.0, 3.0]) {
          testWidgets('$width px, scale $scale: long label wraps, never '
              'truncated; loading keeps the size', (tester) async {
            setScreenSize(tester, width, 800);
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            Widget host({required bool loading}) => testApp(
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: AppButton(
                    label: longLabel,
                    icon: const Icon(Icons.login),
                    expand: true,
                    isLoading: loading,
                    onPressed: () {},
                  ),
                ),
              ),
            );
            await tester.pumpWidget(host(loading: false));
            expect(tester.takeException(), isNull);
            final para = tester.renderObject<RenderParagraph>(
              find.descendant(
                of: find.text(longLabel),
                matching: find.byType(RichText),
              ),
            );
            expect(para.didExceedMaxLines, isFalse);
            expect(
              para.size.height,
              greaterThanOrEqualTo(para.getMaxIntrinsicHeight(para.size.width)),
            );
            final idle = tester.getSize(find.byType(FilledButton));
            expect(idle.height, greaterThanOrEqualTo(48));
            expect(idle.width, lessThanOrEqualTo(width - 32));

            await tester.pumpWidget(host(loading: true));
            await tester.pump(const Duration(milliseconds: 100));
            expect(tester.takeException(), isNull);
            expect(tester.getSize(find.byType(FilledButton)), idle);
          });
        }
      }
    });
  });

  group('AppTextButton', () {
    /// Settles Material's text-style animation, then pumps [child].
    Future<void> show(WidgetTester tester, Widget child) async {
      await pump(tester, child);
      await tester.pumpAndSettle();
    }

    /// The rendered label style (after the button applies its colors).
    TextStyle label(WidgetTester tester, String text) => tester
        .widget<RichText>(
          find.descendant(of: find.text(text), matching: find.byType(RichText)),
        )
        .text
        .style!;

    /// The rendered color of [icon].
    Color? iconColor(WidgetTester tester, IconData icon) => tester
        .widget<RichText>(
          find.descendant(
            of: find.byIcon(icon),
            matching: find.byType(RichText),
          ),
        )
        .text
        .style!
        .color;

    group('contract', () {
      testWidgets('label and onPressed only: theme defaults', (tester) async {
        await show(tester, AppTextButton(label: 'More', onPressed: () {}));
        final style = label(tester, 'More');
        expect(style.color, AppColor.primary);
        expect(style.fontWeight, FontWeight.w600);
        expect(style.fontFamily, AppFonts.ibmPlexSansArabic);
        expect(tester.getSize(find.byType(TextButton)).height, 48);
        expect(
          tester.getSize(find.byType(TextButton)).width,
          greaterThanOrEqualTo(48),
        );
        expect(find.byType(Icon), findsNothing);
      });

      testWidgets('a blank label asserts (it is the accessible name)', (
        tester,
      ) async {
        await pump(tester, AppTextButton(label: '  ', onPressed: () {}));
        expect(tester.takeException(), isA<AssertionError>());
      });

      testWidgets('tap runs onPressed; null disables it visibly', (
        tester,
      ) async {
        var taps = 0;
        await show(
          tester,
          AppTextButton(
            label: 'More',
            icon: const Icon(Icons.add),
            onPressed: () => taps++,
          ),
        );
        await tester.tap(find.text('More'));
        expect(taps, 1);

        await show(
          tester,
          const AppTextButton(
            label: 'More',
            icon: Icon(Icons.add),
            color: Colors.red,
            onPressed: null,
          ),
        );
        expect(
          tester.widget<TextButton>(find.byType(TextButton)).onPressed,
          isNull,
        );
        await tester.tap(find.text('More'), warnIfMissed: false);
        expect(taps, 1);
        // Material's disabled color, even with a custom color.
        final disabled = AppTheme.light.colorScheme.onSurface.withAlpha(97);
        expect(label(tester, 'More').color, disabled);
        expect(iconColor(tester, Icons.add), disabled);
      });
    });

    group('appearance overrides', () {
      testWidgets('color paints the label and the icon', (tester) async {
        await show(
          tester,
          AppTextButton(
            label: 'Delete',
            icon: const Icon(Icons.delete_outline),
            color: AppColor.success,
            onPressed: () {},
          ),
        );
        expect(label(tester, 'Delete').color, AppColor.success);
        expect(iconColor(tester, Icons.delete_outline), AppColor.success);
        expect(tester.getSize(find.byType(Icon)), const Size(18, 18));
      });

      testWidgets('textStyle color applies when color is null; color wins', (
        tester,
      ) async {
        await show(
          tester,
          AppTextButton(
            label: 'More',
            icon: const Icon(Icons.add),
            textStyle: const TextStyle(color: AppColor.success),
            onPressed: () {},
          ),
        );
        expect(label(tester, 'More').color, AppColor.success);
        expect(iconColor(tester, Icons.add), AppColor.success);

        await show(
          tester,
          AppTextButton(
            label: 'More',
            textStyle: const TextStyle(color: AppColor.success),
            color: AppColor.textPrimary,
            onPressed: () {},
          ),
        );
        expect(label(tester, 'More').color, AppColor.textPrimary);
      });

      testWidgets('textStyle merges over the default weight and family', (
        tester,
      ) async {
        await show(
          tester,
          AppTextButton(
            label: 'More',
            textStyle: const TextStyle(fontSize: 20),
            onPressed: () {},
          ),
        );
        var style = label(tester, 'More');
        expect(style.fontSize, 20);
        expect(style.fontWeight, FontWeight.w600);
        expect(style.fontFamily, AppFonts.ibmPlexSansArabic);

        await show(
          tester,
          AppTextButton(
            label: 'More',
            textStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              decoration: TextDecoration.underline,
            ),
            onPressed: () {},
          ),
        );
        style = label(tester, 'More');
        expect(style.fontWeight, FontWeight.w400);
        expect(style.decoration, TextDecoration.underline);
        expect(style.fontFamily, AppFonts.ibmPlexSansArabic);
      });

      testWidgets('padding changes the rendered size; 48 px stays minimum', (
        tester,
      ) async {
        await show(tester, AppTextButton(label: 'L', onPressed: () {}));
        expect(tester.getSize(find.byType(TextButton)), const Size(48, 48));

        await show(
          tester,
          AppTextButton(
            label: 'L',
            padding: const EdgeInsets.all(20),
            onPressed: () {},
          ),
        );
        final size = tester.getSize(find.byType(TextButton));
        expect(size.width, greaterThan(48));
        expect(size.height, greaterThan(48));

        await show(
          tester,
          AppTextButton(label: 'L', padding: EdgeInsets.zero, onPressed: () {}),
        );
        expect(tester.getSize(find.byType(TextButton)), const Size(48, 48));
      });
    });

    group('direction', () {
      for (final direction in TextDirection.values) {
        for (final position in AppIconPosition.values) {
          testWidgets('${direction.name}: icon at ${position.name}', (
            tester,
          ) async {
            await show(
              tester,
              Directionality(
                textDirection: direction,
                child: AppTextButton(
                  label: 'More',
                  icon: const Icon(Icons.add),
                  iconPosition: position,
                  onPressed: () {},
                ),
              ),
            );
            final iconX = tester.getCenter(find.byIcon(Icons.add)).dx;
            final textX = tester.getCenter(find.text('More')).dx;
            // Start = right in RTL, left in LTR.
            final iconOnRight =
                (direction == TextDirection.rtl) ==
                (position == AppIconPosition.start);
            expect(iconOnRight ? iconX > textX : iconX < textX, isTrue);
          });
        }
      }
    });

    group('accessibility', () {
      testWidgets('one button node named by the label; disabled state', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await show(
          tester,
          AppTextButton(
            label: 'More',
            icon: const Icon(Icons.add),
            onPressed: () {},
          ),
        );
        expect(
          tester.getSemantics(find.byType(TextButton)),
          isSemantics(
            label: 'More',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
            isFocusable: true,
          ),
        );

        await show(tester, const AppTextButton(label: 'More', onPressed: null));
        expect(
          tester.getSemantics(find.byType(TextButton)),
          isSemantics(
            label: 'More',
            isButton: true,
            hasEnabledState: true,
            isEnabled: false,
            hasTapAction: false,
          ),
        );
        handle.dispose();
      });

      for (final scale in [2.0, 3.0]) {
        testWidgets('320 px at text scale $scale: wraps, no clipping', (
          tester,
        ) async {
          setScreenSize(tester, 320, 640);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          const text = 'تواصل مع الإدارة للحصول على حساب جديد';
          await show(
            tester,
            AppTextButton(
              label: text,
              icon: const Icon(Icons.add),
              onPressed: () {},
            ),
          );
          expect(tester.takeException(), isNull);
          final button = tester.getRect(find.byType(TextButton));
          expect(button.width, lessThanOrEqualTo(320));
          expect(button.height, greaterThanOrEqualTo(48));
          final para = tester.renderObject<RenderParagraph>(
            find.descendant(
              of: find.text(text),
              matching: find.byType(RichText),
            ),
          );
          expect(para.didExceedMaxLines, isFalse);
          expect(
            para.size.height,
            greaterThanOrEqualTo(para.getMaxIntrinsicHeight(para.size.width)),
          );
        });
      }
    });
  });

  // R06 (SW-02): typed action results instead of manual root-navigator pops.
  group('AppPopup typed result', () {
    Future<Future<bool?>> open(WidgetTester tester, {Widget? wrap}) async {
      late BuildContext ctx;
      await pump(tester, wrap ?? contextProbe((c) => ctx = c));
      if (wrap != null) ctx = tester.element(find.byKey(const Key('probe')));
      final result = showAppPopup<bool>(
        ctx,
        title: 'T',
        actions: [
          AppPopupAction(label: 'إلغاء'),
          AppPopupAction<bool>(label: 'تأكيد', isPrimary: true, result: true),
        ],
      );
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('confirm completes with true', (tester) async {
      final result = await open(tester);
      await tester.tap(find.text('تأكيد'));
      await tester.pumpAndSettle();
      expect(await result, isTrue);
      expect(find.byType(AppPopup), findsNothing);
    });

    for (final (name, close) in <(String, Future<void> Function(WidgetTester))>[
      ('cancel', (t) => t.tap(find.text('إلغاء'))),
      ('barrier', (t) => t.tapAt(const Offset(4, 4))),
      ('system back', (t) => t.binding.handlePopRoute()),
    ]) {
      testWidgets('$name completes with null (never a confirmation)', (
        tester,
      ) async {
        final result = await open(tester);
        await close(tester);
        await tester.pumpAndSettle();
        expect(await result, isNull);
        expect(find.byType(AppPopup), findsNothing);
      });
    }

    testWidgets('a double tap confirms once and never pops the page below', (
      tester,
    ) async {
      late BuildContext ctx;
      var calls = 0;
      await pump(tester, contextProbe((c) => ctx = c));
      final result = showAppPopup<bool>(
        ctx,
        title: 'T',
        actions: [
          AppPopupAction<bool>(
            label: 'تأكيد',
            result: true,
            onPressed: () => calls++,
          ),
        ],
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأكيد'));
      await tester.pump();
      await tester.tap(find.text('تأكيد'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(await result, isTrue);
      expect(calls, 1);
      // The host page is still there.
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('inside a nested navigator: pops only the dialog', (
      tester,
    ) async {
      final result = await open(
        tester,
        wrap: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => const SizedBox(key: Key('probe')),
          ),
        ),
      );
      await tester.tap(find.text('تأكيد'));
      await tester.pumpAndSettle();
      expect(await result, isTrue);
      expect(find.byKey(const Key('probe')), findsOneWidget);
    });

    testWidgets('a callback that opens another dialog runs after the first '
        'one closed', (tester) async {
      late BuildContext ctx;
      await pump(tester, contextProbe((c) => ctx = c));
      final first = showAppPopup<bool>(
        ctx,
        title: 'أول',
        actions: [
          AppPopupAction<bool>(
            label: 'التالي',
            result: true,
            onPressed: () => showAppPopup<void>(ctx, title: 'ثانٍ'),
          ),
        ],
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();
      expect(await first, isTrue);
      expect(find.text('أول'), findsNothing);
      expect(find.text('ثانٍ'), findsOneWidget);
    });
  });

  group('AppPopup', () {
    testWidgets('title, message and action; action closes then runs', (
      tester,
    ) async {
      late BuildContext ctx;
      var ran = false;
      await pump(tester, contextProbe((c) => ctx = c));
      showAppPopup<void>(
        ctx,
        title: 'T',
        message: 'M',
        actions: [AppPopupAction(label: 'OK', onPressed: () => ran = true)],
      );
      await tester.pumpAndSettle();
      expect(find.text('T'), findsOneWidget);
      expect(find.text('M'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(AppPopup), findsNothing);
      expect(ran, isTrue);
    });

    testWidgets('secondary actions are AppTextButtons; destructive is error', (
      tester,
    ) async {
      late BuildContext ctx;
      await pump(tester, contextProbe((c) => ctx = c));
      showAppPopup<void>(
        ctx,
        message: 'M',
        actions: const [
          AppPopupAction(label: 'Later'),
          AppPopupAction(label: 'Remove', isDestructive: true),
        ],
      );
      await tester.pumpAndSettle();
      final buttons = tester
          .widgetList<AppTextButton>(find.byType(AppTextButton))
          .toList();
      expect(buttons.map((b) => b.label), ['Later', 'Remove']);
      expect(buttons.first.color, isNull);
      expect(buttons.last.color, AppTheme.light.colorScheme.error);
      final removeStyle = tester
          .widget<RichText>(
            find.descendant(
              of: find.text('Remove'),
              matching: find.byType(RichText),
            ),
          )
          .text
          .style!;
      expect(removeStyle.color, AppTheme.light.colorScheme.error);
    });

    testWidgets('barrier dismiss can be disabled', (tester) async {
      late BuildContext ctx;
      await pump(tester, contextProbe((c) => ctx = c));
      showAppPopup<void>(
        ctx,
        title: 'T',
        barrierDismissible: false,
        actions: const [AppPopupAction(label: 'OK')],
      );
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byType(AppPopup), findsOneWidget);
    });

    group('contract asserts', () {
      test('message and content are exclusive', () {
        expect(
          () => AppPopup(message: 'M', content: const SizedBox()),
          throwsAssertionError,
        );
      });

      test('a title, message or content is required', () {
        expect(
          () => AppPopup(icon: const Icon(Icons.info)),
          throwsAssertionError,
        );
        expect(() => const AppPopup(content: SizedBox()), returnsNormally);
      });

      test('a non-closing action needs onPressed', () {
        expect(
          () => AppPopupAction(label: 'X', closesPopup: false),
          throwsAssertionError,
        );
        expect(() => const AppPopupAction(label: 'X'), returnsNormally);
      });

      testWidgets('a non-dismissible popup needs a way to close', (
        tester,
      ) async {
        late BuildContext ctx;
        await pump(tester, contextProbe((c) => ctx = c));
        expect(
          () => showAppPopup<void>(ctx, title: 'T', barrierDismissible: false),
          throwsAssertionError,
        );
        expect(
          () => showAppPopup<void>(
            ctx,
            title: 'T',
            barrierDismissible: false,
            showCloseButton: true,
          ),
          returnsNormally,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(l10n.close));
        await tester.pumpAndSettle();
        expect(find.byType(AppPopup), findsNothing);
      });
    });

    testWidgets('close button closes; long content scrolls; width capped', (
      tester,
    ) async {
      setScreenSize(tester, 1440, 900);
      late BuildContext ctx;
      await pump(tester, contextProbe((c) => ctx = c));
      showAppPopup<void>(
        ctx,
        title: 'T',
        message: List.filled(400, 'سطر طويل').join(' '),
        showCloseButton: true,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull); // no overflow
      expect(find.byType(SingleChildScrollView), findsWidgets);
      // Measure the visible dialog surface (Dialog itself fills the screen).
      final surface = find
          .descendant(of: find.byType(Dialog), matching: find.byType(Material))
          .first;
      expect(tester.getSize(surface).width, lessThanOrEqualTo(480));

      await tester.tap(find.byTooltip(l10n.close));
      await tester.pumpAndSettle();
      expect(find.byType(AppPopup), findsNothing);
    });
  });

  // Task 17: the popup must fit the space left by the keyboard (and safe
  // areas) at any text scale, with every action reachable.
  group('AppPopup layout with the keyboard open', () {
    const keyboard = 260.0;
    final longTitle = List.filled(6, 'عنوان طويل جداً').join(' ');
    final longMessage = List.filled(60, 'نص المساعدة الطويل').join(' ');

    /// Opens a popup on a [width]×[height] screen at [scale] with a
    /// [keyboardHeight] bottom inset, the way a focused field would.
    Future<void> open(
      WidgetTester tester, {
      required double width,
      required double height,
      required double scale,
      double keyboardHeight = keyboard,
      required void Function(BuildContext) show,
      TextDirection direction = TextDirection.rtl,
    }) async {
      setScreenSize(tester, width, height);
      tester.view.viewInsets = FakeViewPadding(bottom: keyboardHeight);
      addTearDown(tester.view.resetViewInsets);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      late BuildContext ctx;
      await tester.pumpWidget(
        testApp(
          Directionality(
            textDirection: direction,
            child: contextProbe((c) => ctx = c),
          ),
        ),
      );
      show(ctx);
      await tester.pumpAndSettle();
    }

    /// The visible dialog surface.
    Rect surface(WidgetTester tester) => tester.getRect(
      find
          .descendant(of: find.byType(Dialog), matching: find.byType(Material))
          .first,
    );

    /// Taps [label] after scrolling it into view if needed.
    Future<void> tapAction(WidgetTester tester, String label) async {
      final target = find.text(label);
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    void forgotPasswordLike(BuildContext context) => showAppPopup<void>(
      context,
      icon: const Icon(Icons.lock_reset, size: 40),
      title: l10n.forgotPasswordTitle,
      message: l10n.forgotPasswordMessage,
      actions: [AppPopupAction(label: l10n.close, isPrimary: true)],
    );

    for (final scale in [1.0, 2.0, 3.0]) {
      testWidgets('320 px, scale $scale: single-action popup fits; action '
          'visible above the keyboard', (tester) async {
        await open(
          tester,
          width: 320,
          height: 568,
          scale: scale,
          show: forgotPasswordLike,
        );
        expect(tester.takeException(), isNull);
        final dialog = surface(tester);
        expect(dialog.bottom, lessThanOrEqualTo(568 - keyboard));
        // The action is pinned: on screen without scrolling.
        final action = tester.getRect(
          find.widgetWithText(FilledButton, l10n.close),
        );
        expect(action.bottom, lessThanOrEqualTo(dialog.bottom));
        expect(action.top, greaterThanOrEqualTo(dialog.top));
        expect(action.height, greaterThanOrEqualTo(48));
        await tapAction(tester, l10n.close);
        expect(find.byType(AppPopup), findsNothing);
      });

      testWidgets('320 px, scale $scale: confirm popup, both actions reach', (
        tester,
      ) async {
        var confirmed = 0;
        await open(
          tester,
          width: 320,
          height: 568,
          scale: scale,
          show: (c) => showAppPopup<void>(
            c,
            title: l10n.alert,
            message: l10n.proceedQuestion,
            barrierDismissible: false,
            actions: [
              AppPopupAction(label: l10n.cancel, isDestructive: true),
              AppPopupAction(
                label: l10n.confirm,
                isPrimary: true,
                onPressed: () => confirmed++,
              ),
            ],
          ),
        );
        expect(tester.takeException(), isNull);
        final dialog = surface(tester);
        expect(dialog.bottom, lessThanOrEqualTo(568 - keyboard));
        if (scale < 3) {
          // Pinned: both actions on screen without scrolling.
          for (final label in [l10n.cancel, l10n.confirm]) {
            final rect = tester.getRect(find.text(label));
            expect(
              rect.bottom,
              lessThanOrEqualTo(dialog.bottom),
              reason: label,
            );
          }
        }
        // At 3.0 the two stacked buttons exceed the space: they scroll, and
        // both stay reachable.
        await tester.ensureVisible(find.text(l10n.cancel));
        await tester.pumpAndSettle();
        expect(
          tester.getRect(find.text(l10n.cancel)).bottom,
          lessThanOrEqualTo(dialog.bottom),
        );
        await tapAction(tester, l10n.confirm);
        expect(confirmed, 1);
        expect(find.byType(AppPopup), findsNothing);
      });
    }

    for (final scale in [2.0, 3.0]) {
      testWidgets('scale $scale: long title and message scroll; action '
          'stays reachable', (tester) async {
        var ran = false;
        await open(
          tester,
          width: 320,
          height: 568,
          scale: scale,
          show: (c) => showAppPopup<void>(
            c,
            icon: const Icon(Icons.info_outline, size: 40),
            title: longTitle,
            message: longMessage,
            actions: [
              AppPopupAction(
                label: l10n.close,
                isPrimary: true,
                onPressed: () => ran = true,
              ),
            ],
          ),
        );
        expect(tester.takeException(), isNull);
        expect(surface(tester).bottom, lessThanOrEqualTo(568 - keyboard));
        // Title is still a heading and nothing was shortened.
        final title = tester.widget<Text>(find.text(longTitle));
        expect(title.maxLines, isNull);
        expect(title.overflow, isNull);
        expect(
          tester.getSemantics(find.text(longTitle)),
          isSemantics(isHeader: true, label: longTitle),
        );
        // The end of the message can be scrolled into view.
        await tester.dragUntilVisible(
          find.text(longMessage),
          find.byType(SingleChildScrollView).first,
          const Offset(0, -200),
        );
        await tapAction(tester, l10n.close);
        expect(ran, isTrue);
      });

      testWidgets('scale $scale: scrolling content widget, keyboard open', (
        tester,
      ) async {
        await open(
          tester,
          width: 320,
          height: 568,
          scale: scale,
          show: (c) => showAppPopup<void>(
            c,
            title: l10n.alert,
            content: Column(
              children: [for (var i = 0; i < 30; i++) Text('بند رقم $i')],
            ),
            actions: [AppPopupAction(label: l10n.close, isPrimary: true)],
          ),
        );
        expect(tester.takeException(), isNull);
        await tester.dragUntilVisible(
          find.text('بند رقم 29'),
          find.byType(SingleChildScrollView).first,
          const Offset(0, -200),
        );
        expect(tester.takeException(), isNull);
        await tapAction(tester, l10n.close);
        expect(find.byType(AppPopup), findsNothing);
      });

      testWidgets('landscape phone, scale $scale: even the actions scroll '
          'when nothing else fits', (tester) async {
        await open(
          tester,
          width: 640,
          height: 360,
          scale: scale,
          keyboardHeight: 200,
          show: (c) => showAppPopup<void>(
            c,
            icon: const Icon(Icons.info_outline, size: 40),
            title: l10n.alert,
            message: l10n.proceedQuestion,
            actions: [
              AppPopupAction(label: l10n.cancel),
              AppPopupAction(label: l10n.confirm, isPrimary: true),
            ],
          ),
        );
        expect(tester.takeException(), isNull);
        expect(surface(tester).bottom, lessThanOrEqualTo(360 - 200));
        expect(find.text(l10n.alert), findsOneWidget);
        await tapAction(tester, l10n.confirm);
        expect(find.byType(AppPopup), findsNothing);
      });
    }

    for (final width in [320.0, 1024.0]) {
      testWidgets('width $width, scale 1.0, long action labels wrap', (
        tester,
      ) async {
        final longLabel = List.filled(4, 'إجراء طويل').join(' ');
        await open(
          tester,
          width: width,
          height: 800,
          scale: 1,
          keyboardHeight: 0,
          show: (c) => showAppPopup<void>(
            c,
            title: l10n.alert,
            message: l10n.proceedQuestion,
            actions: [
              AppPopupAction(label: longLabel),
              AppPopupAction(label: l10n.confirm, isPrimary: true),
            ],
          ),
        );
        expect(tester.takeException(), isNull);
        expect(surface(tester).width, lessThanOrEqualTo(480));
        final dialog = surface(tester);
        for (final label in [longLabel, l10n.confirm]) {
          final rect = tester.getRect(find.text(label));
          expect(rect.left, greaterThanOrEqualTo(dialog.left), reason: label);
          expect(rect.right, lessThanOrEqualTo(dialog.right), reason: label);
          expect(rect.bottom, lessThanOrEqualTo(dialog.bottom), reason: label);
        }
      });
    }

    testWidgets('enough space: the dialog hugs its content as before', (
      tester,
    ) async {
      await open(
        tester,
        width: 375,
        height: 812,
        scale: 1,
        keyboardHeight: 0,
        show: forgotPasswordLike,
      );
      final dialog = surface(tester);
      expect(dialog.height, lessThan(400));
      // Vertically centered in the screen.
      expect((dialog.center.dy - 406).abs(), lessThan(1));
    });

    for (final direction in TextDirection.values) {
      testWidgets('${direction.name}: close button at the top end; heading', (
        tester,
      ) async {
        // A dialog route takes the app's direction, so the popup is pumped
        // inline under an explicit Directionality to cover LTR as well.
        final handle = tester.ensureSemantics();
        setScreenSize(tester, 375, 667);
        tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
        addTearDown(tester.view.resetViewInsets);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          testApp(
            Directionality(
              textDirection: direction,
              child: AppPopup(
                title: l10n.alert,
                message: l10n.proceedQuestion,
                showCloseButton: true,
                actions: [AppPopupAction(label: l10n.close, isPrimary: true)],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final dialog = surface(tester);
        final close = tester.getRect(
          find.widgetWithIcon(IconButton, Icons.close),
        );
        final nearLeft = close.left - dialog.left < dialog.right - close.right;
        // Top end: left in RTL, right in LTR.
        expect(nearLeft, direction == TextDirection.rtl);
        expect(close.width, greaterThanOrEqualTo(48));
        expect(close.height, greaterThanOrEqualTo(48));
        expect(
          tester.getSemantics(find.text(l10n.alert)),
          isSemantics(isHeader: true, label: l10n.alert),
        );
        expect(
          tester.getSemantics(find.widgetWithText(FilledButton, l10n.close)),
          isSemantics(
            label: l10n.close,
            isButton: true,
            isEnabled: true,
            hasEnabledState: true,
            hasTapAction: true,
            isFocusable: true,
          ),
        );
        handle.dispose();
      });
    }
  });

  group('AppToast', () {
    for (final type in AppToastType.values) {
      testWidgets('shows $type with message and status label', (tester) async {
        // Enabled before the toast appears so its semantics are built.
        final semantics = tester.ensureSemantics();
        late BuildContext ctx;
        await pump(tester, contextProbe((c) => ctx = c));
        showAppToast(ctx, message: 'رسالة', type: type);
        await tester.pump();
        expect(find.text('رسالة'), findsOneWidget);
        final toast = tester.widget<AppToast>(find.byType(AppToast));
        expect(toast.type, type);
        // Screen readers get the localized status + message pattern.
        final status = switch (type) {
          AppToastType.success => l10n.toastSuccess,
          AppToastType.error => l10n.toastError,
          AppToastType.warning => l10n.toastWarning,
          AppToastType.info => l10n.toastInfo,
        };
        // Screen readers announce the localized "status: message" pattern.
        await tester.pumpAndSettle();
        expect(
          tester.getSemantics(find.byType(AppToast)).label,
          l10n.toastAnnouncement(status, 'رسالة'),
        );
        semantics.dispose();
      });
    }

    testWidgets('close button dismisses; action runs', (tester) async {
      late BuildContext ctx;
      var acted = false;
      await pump(tester, contextProbe((c) => ctx = c));
      showAppToast(
        ctx,
        message: 'رسالة',
        actionLabel: 'A',
        onAction: () => acted = true,
      );
      await tester.pumpAndSettle(); // let the entrance animation finish
      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      expect(acted, isTrue);
      expect(find.text('رسالة'), findsNothing);

      showAppToast(ctx, message: 'ثانية');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(l10n.close));
      await tester.pumpAndSettle();
      expect(find.text('ثانية'), findsNothing);
    });

    group('rendered contract', () {
      /// A long Arabic message, wide enough to wrap on every tested width.
      const longMessage =
          'تعذر الاتصال بالخادم، يرجى التحقق من الاتصال والمحاولة مرة أخرى';

      /// A two-word action label (the widest realistic one, «Retry»).
      const retry = 'إعادة المحاولة';

      /// Pumps the shared Arabic host and returns a context under its
      /// ScaffoldMessenger.
      Future<BuildContext> host(WidgetTester tester) async {
        late BuildContext ctx;
        await tester.pumpWidget(testApp(contextProbe((c) => ctx = c)));
        return ctx;
      }

      /// The painted toast surface (the Material inside the SnackBar).
      Material surface(WidgetTester tester) => tester.widget<Material>(
        find
            .descendant(
              of: find.byType(SnackBar),
              matching: find.byType(Material),
            )
            .first,
      );

      testWidgets('an action label without onAction asserts', (tester) async {
        final ctx = await host(tester);
        expect(
          () => showAppToast(ctx, message: 'رسالة', actionLabel: 'A'),
          throwsA(
            isA<AssertionError>().having(
              (e) => e.message,
              'message',
              contains('onAction'),
            ),
          ),
        );
        expect(
          () => AppToast(
            message: 'رسالة',
            type: AppToastType.info,
            actionLabel: 'A',
          ),
          throwsAssertionError,
        );
      });

      testWidgets('onAction without an action label asserts', (tester) async {
        final ctx = await host(tester);
        expect(
          () => showAppToast(ctx, message: 'رسالة', onAction: () {}),
          throwsA(
            isA<AssertionError>().having(
              (e) => e.message,
              'message',
              contains('actionLabel'),
            ),
          ),
        );
        expect(
          () => AppToast(
            message: 'رسالة',
            type: AppToastType.info,
            onAction: () {},
          ),
          throwsAssertionError,
        );
      });

      testWidgets('a blank action label asserts', (tester) async {
        final ctx = await host(tester);
        expect(
          () => showAppToast(
            ctx,
            message: 'رسالة',
            actionLabel: '  ',
            onAction: () {},
          ),
          throwsAssertionError,
        );
      });

      testWidgets('a blank message asserts and shows nothing', (tester) async {
        final ctx = await host(tester);
        expect(
          () => showAppToast(ctx, message: ' \n '),
          throwsA(
            isA<AssertionError>().having(
              (e) => e.message,
              'message',
              contains('message'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(AppToast), findsNothing);
      });

      testWidgets('a zero or negative duration asserts', (tester) async {
        final ctx = await host(tester);
        for (final duration in [Duration.zero, const Duration(seconds: -1)]) {
          expect(
            () => showAppToast(ctx, message: 'رسالة', duration: duration),
            throwsAssertionError,
          );
        }
      });

      testWidgets('an unmounted context asserts with a clear message', (
        tester,
      ) async {
        final ctx = await host(tester);
        await tester.pumpWidget(const SizedBox());
        expect(
          () => showAppToast(ctx, message: 'رسالة'),
          throwsA(
            isA<AssertionError>().having(
              (e) => e.message,
              'message',
              contains('mounted'),
            ),
          ),
        );
      });

      testWidgets('without a ScaffoldMessenger Flutter reports it', (
        tester,
      ) async {
        late BuildContext ctx;
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.rtl,
            child: contextProbe((c) => ctx = c),
          ),
        );
        expect(
          () => showAppToast(ctx, message: 'رسالة'),
          throwsA(
            isA<FlutterError>().having(
              (e) => e.message,
              'message',
              contains('No ScaffoldMessenger widget found'),
            ),
          ),
        );
      });

      for (final type in AppToastType.values) {
        testWidgets('$type renders its own icon, color and white content', (
          tester,
        ) async {
          final ctx = await host(tester);
          showAppToast(ctx, message: 'رسالة', type: type);
          await tester.pumpAndSettle();
          final expectedIcon = switch (type) {
            AppToastType.success => Icons.check_circle_outline,
            AppToastType.error => Icons.error_outline,
            AppToastType.warning => Icons.warning_amber_rounded,
            AppToastType.info => Icons.info_outline,
          };
          final expectedColor = switch (type) {
            AppToastType.success => AppColor.success,
            AppToastType.error => AppTheme.light.colorScheme.error,
            AppToastType.warning => AppColor.warning,
            AppToastType.info => AppColor.textPrimary,
          };
          expect(find.byIcon(expectedIcon), findsOneWidget);
          expect(
            tester.widget<Icon>(find.byIcon(expectedIcon)).color,
            AppColor.white,
          );
          expect(surface(tester).color, expectedColor);
          expect(
            tester
                .renderObject<RenderParagraph>(find.text('رسالة'))
                .text
                .style
                ?.color,
            AppColor.white,
          );
          // Floating, rounded, with the default close control.
          final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
          expect(snackBar.behavior, SnackBarBehavior.floating);
          expect(
            snackBar.shape,
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          );
          expect(find.byTooltip(l10n.close), findsOneWidget);
        });
      }

      testWidgets('the four types use four different icons', (tester) async {
        final ctx = await host(tester);
        final icons = <IconData?>{};
        for (final type in AppToastType.values) {
          showAppToast(ctx, message: 'رسالة', type: type);
          await tester.pumpAndSettle();
          icons.add(
            tester
                .widget<Icon>(
                  find
                      .descendant(
                        of: find.byType(AppToast),
                        matching: find.byType(Icon),
                      )
                      .first,
                )
                .icon,
          );
        }
        expect(icons, hasLength(4));
      });

      testWidgets('the action runs exactly once, even on a double tap', (
        tester,
      ) async {
        final ctx = await host(tester);
        var calls = 0;
        showAppToast(
          ctx,
          message: 'رسالة',
          actionLabel: retry,
          onAction: () => calls++,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(retry));
        // Second tap while the toast is still animating out.
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.text(retry), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(calls, 1);
        expect(find.byType(AppToast), findsNothing);
      });

      testWidgets('close dismisses without running the action', (tester) async {
        final ctx = await host(tester);
        var calls = 0;
        showAppToast(
          ctx,
          message: 'رسالة',
          actionLabel: retry,
          onAction: () => calls++,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(l10n.close));
        await tester.pump(const Duration(milliseconds: 50));
        // The action is inert once the toast is closing.
        await tester.tap(find.text(retry), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(calls, 0);
        expect(find.byType(AppToast), findsNothing);
      });

      testWidgets('no action and no close: no buttons at all', (tester) async {
        final semantics = tester.ensureSemantics();
        final ctx = await host(tester);
        showAppToast(ctx, message: 'رسالة', showCloseButton: false);
        await tester.pumpAndSettle();
        final toast = find.byType(AppToast);
        expect(
          find.descendant(of: toast, matching: find.byType(TextButton)),
          findsNothing,
        );
        expect(
          find.descendant(of: toast, matching: find.byType(IconButton)),
          findsNothing,
        );
        expect(
          tester
              .getSemantics(toast)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isFalse,
        );
        semantics.dispose();
      });

      testWidgets('controls: 48 px targets, localized names, one each', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        final ctx = await host(tester);
        showAppToast(
          ctx,
          message: 'رسالة',
          type: AppToastType.error,
          actionLabel: retry,
          onAction: () {},
        );
        await tester.pumpAndSettle();
        final action = find.widgetWithText(TextButton, retry);
        final close = find.byType(IconButton);
        expect(action, findsOneWidget);
        expect(close, findsOneWidget);
        expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
        expect(tester.getSize(action).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(close), const Size(48, 48));
        expect(
          tester.getSemantics(action),
          isSemantics(
            label: retry,
            isButton: true,
            hasTapAction: true,
            isEnabled: true,
            hasEnabledState: true,
            isFocusable: true,
          ),
        );
        expect(
          tester.getSemantics(close),
          isSemantics(
            tooltip: l10n.close,
            isButton: true,
            hasTapAction: true,
            isEnabled: true,
            hasEnabledState: true,
            isFocusable: true,
          ),
        );
        // The message is announced once: by the toast's status label only.
        expect(
          tester.getSemantics(find.byType(AppToast)).label,
          l10n.toastAnnouncement(l10n.toastError, 'رسالة'),
        );
        expect(find.bySemanticsLabel(RegExp('رسالة')), findsOneWidget);
        semantics.dispose();
      });

      testWidgets('a replaced toast\'s action never runs', (tester) async {
        final ctx = await host(tester);
        var first = 0;
        showAppToast(
          ctx,
          message: 'الأولى',
          actionLabel: retry,
          onAction: () => first++,
        );
        await tester.pumpAndSettle();
        showAppToast(ctx, message: 'الثانية');
        // The first toast is still animating out and still on screen.
        await tester.pump(const Duration(milliseconds: 30));
        expect(find.text(retry), findsOneWidget);
        await tester.tap(find.text(retry), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(first, 0);
        expect(find.text('الثانية'), findsOneWidget);
      });

      testWidgets('a burst shows the latest toast, never a stale one', (
        tester,
      ) async {
        final ctx = await host(tester);
        showAppToast(ctx, message: 'أ');
        await tester.pumpAndSettle();
        showAppToast(ctx, message: 'ب');
        await tester.pump(const Duration(milliseconds: 20));
        showAppToast(ctx, message: 'ج');
        await tester.pumpAndSettle();
        expect(find.text('ب'), findsNothing);
        expect(find.text('ج'), findsOneWidget);
        // Nothing queued behind it either.
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        expect(find.byType(AppToast), findsNothing);
      });

      testWidgets('default duration is 4 s, also with an action', (
        tester,
      ) async {
        final ctx = await host(tester);
        showAppToast(
          ctx,
          message: 'رسالة',
          actionLabel: retry,
          onAction: () {},
        );
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 3900));
        expect(find.byType(AppToast), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();
        expect(find.byType(AppToast), findsNothing);
      });

      testWidgets('a custom duration is honored', (tester) async {
        final ctx = await host(tester);
        showAppToast(
          ctx,
          message: 'رسالة',
          duration: const Duration(seconds: 1),
        );
        await tester.pumpAndSettle();
        expect(find.byType(AppToast), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 1100));
        await tester.pumpAndSettle();
        expect(find.byType(AppToast), findsNothing);
      });

      for (final direction in TextDirection.values) {
        testWidgets('$direction: icon, message, action, close in order', (
          tester,
        ) async {
          late BuildContext ctx;
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              locale: const Locale('ar'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              builder: (context, child) =>
                  Directionality(textDirection: direction, child: child!),
              home: Scaffold(body: contextProbe((c) => ctx = c)),
            ),
          );
          showAppToast(
            ctx,
            message: 'رسالة',
            actionLabel: 'A',
            onAction: () {},
          );
          await tester.pumpAndSettle();
          final xs = [
            tester.getCenter(find.byIcon(Icons.info_outline)).dx,
            tester.getCenter(find.text('رسالة')).dx,
            tester.getCenter(find.text('A')).dx,
            tester.getCenter(find.byIcon(Icons.close)).dx,
          ];
          final ordered = [...xs]..sort();
          expect(
            xs,
            direction == TextDirection.ltr
                ? ordered
                : ordered.reversed.toList(),
          );
          expect(find.byTooltip(l10n.close), findsOneWidget);
        });
      }

      testWidgets('a short action stays inline beside a short message', (
        tester,
      ) async {
        setScreenSize(tester, 375, 667);
        final ctx = await host(tester);
        showAppToast(
          ctx,
          message: 'رسالة',
          actionLabel: 'إعادة',
          onAction: () {},
        );
        await tester.pumpAndSettle();
        expect(
          tester.getCenter(find.text('إعادة')).dy,
          moreOrLessEquals(tester.getCenter(find.text('رسالة')).dy, epsilon: 1),
        );
      });

      /// Shared checks for one layout case: nothing overflows, the toast is
      /// on screen above [visibleBottom], the message keeps a readable width,
      /// labels are not truncated and both controls are reachable.
      Future<void> expectUsableLayout(
        WidgetTester tester, {
        required double width,
        required double visibleBottom,
      }) async {
        expect(tester.takeException(), isNull);
        final toast = tester.getRect(find.byType(SnackBar));
        expect(toast.top, greaterThanOrEqualTo(0));
        expect(toast.bottom, lessThanOrEqualTo(visibleBottom + 0.5));
        final message = tester.renderObject<RenderParagraph>(
          find.text(longMessage),
        );
        expect(message.didExceedMaxLines, isFalse);
        // Not squeezed into a sliver beside the action.
        expect(message.size.width, greaterThanOrEqualTo(width * 0.4));
        expect(
          tester
              .renderObject<RenderParagraph>(find.text(retry))
              .didExceedMaxLines,
          isFalse,
        );
        final close = tester.getRect(find.byType(IconButton));
        expect(close.top, greaterThanOrEqualTo(toast.top));
        expect(close.bottom, lessThanOrEqualTo(visibleBottom + 0.5));
      }

      for (final width in [320.0, 375.0, 450.0]) {
        for (final scale in [1.0, 2.0, 3.0]) {
          testWidgets('$width px at text scale $scale: usable, no overflow', (
            tester,
          ) async {
            setScreenSize(tester, width, 640);
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            final ctx = await host(tester);
            var calls = 0;
            showAppToast(
              ctx,
              message: longMessage,
              type: AppToastType.error,
              actionLabel: retry,
              onAction: () => calls++,
            );
            await tester.pumpAndSettle();
            await expectUsableLayout(tester, width: width, visibleBottom: 640);
            await tester.ensureVisible(find.text(retry));
            await tester.pumpAndSettle();
            await tester.tap(find.text(retry));
            await tester.pumpAndSettle();
            expect(calls, 1);
          });
        }
      }

      for (final scale in [1.0, 2.0, 3.0]) {
        testWidgets('320×480, keyboard open, scale $scale: above keyboard', (
          tester,
        ) async {
          setScreenSize(tester, 320, 480);
          tester.view.viewInsets = const FakeViewPadding(bottom: 260);
          addTearDown(tester.view.resetViewInsets);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final ctx = await host(tester);
          var calls = 0;
          showAppToast(
            ctx,
            message: longMessage,
            type: AppToastType.error,
            actionLabel: retry,
            onAction: () => calls++,
          );
          await tester.pumpAndSettle();
          // The keyboard covers everything below 480 - 260 = 220.
          await expectUsableLayout(tester, width: 320, visibleBottom: 220);
          await tester.ensureVisible(find.text(retry));
          await tester.pumpAndSettle();
          // At scale 3 the wrapped action can be taller than the 220 px
          // above the keyboard; it scrolls into view and a visible part of
          // it, above the keyboard, is tappable.
          final action = tester.getRect(find.widgetWithText(TextButton, retry));
          expect(action.top, greaterThanOrEqualTo(0));
          expect(action.top, lessThan(220 - 24));
          await tester.tapAt(
            Offset(
              action.center.dx,
              (action.top + math.min(action.bottom, 220)) / 2,
            ),
          );
          await tester.pumpAndSettle();
          expect(calls, 1);
        });
      }

      testWidgets('a popup opened over a toast blocks its action', (
        tester,
      ) async {
        final ctx = await host(tester);
        var calls = 0;
        showAppToast(
          ctx,
          message: 'رسالة',
          actionLabel: retry,
          onAction: () => calls++,
        );
        await tester.pumpAndSettle();
        unawaited(
          showAppPopup<void>(
            ctx,
            title: 'عنوان',
            message: 'نص',
            actions: [AppPopupAction(label: l10n.close, isPrimary: true)],
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(retry), warnIfMissed: false);
        await tester.pump();
        expect(calls, 0);
      });
    });
  });

  group('AppStatusMessage', () {
    const title = 'تعذر تحميل الطلب الحالي';
    const message =
        'تعذر الاتصال بالخادم، يرجى التحقق من الاتصال والمحاولة مرة أخرى';
    const retry = 'إعادة المحاولة';

    /// Pumps [status] as a screen body in the shared Arabic host.
    Future<void> pumpStatus(WidgetTester tester, Widget status) =>
        tester.pumpWidget(testApp(status));

    testWidgets('an action label without onAction asserts', (tester) async {
      expect(
        () =>
            AppStatusMessage(icon: Icons.map, title: title, actionLabel: retry),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('onAction'),
          ),
        ),
      );
    });

    testWidgets('onAction without an action label asserts', (tester) async {
      expect(
        () => AppStatusMessage(icon: Icons.map, title: title, onAction: () {}),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('actionLabel'),
          ),
        ),
      );
    });

    testWidgets('a blank title asserts', (tester) async {
      await pumpStatus(
        tester,
        const AppStatusMessage(icon: Icons.map, title: ' \n '),
      );
      expect(
        tester.takeException(),
        isA<AssertionError>().having(
          (e) => e.message,
          'message',
          contains('title'),
        ),
      );
    });

    testWidgets('an empty or blank message asserts (use null instead)', (
      tester,
    ) async {
      for (final blank in ['', '   ']) {
        await pumpStatus(
          tester,
          AppStatusMessage(icon: Icons.map, title: title, message: blank),
        );
        expect(
          tester.takeException(),
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('null'),
          ),
        );
      }
    });

    testWidgets('a blank action label is rejected (by AppButton)', (
      tester,
    ) async {
      await pumpStatus(
        tester,
        AppStatusMessage(
          icon: Icons.map,
          title: title,
          actionLabel: '  ',
          onAction: () {},
        ),
      );
      expect(tester.takeException(), isAssertionError);
    });

    testWidgets('defaults: brand icon, themed title and message, no action', (
      tester,
    ) async {
      await pumpStatus(
        tester,
        const AppStatusMessage(icon: Icons.map, title: title, message: message),
      );
      final icon = tester.widget<Icon>(find.byIcon(Icons.map));
      expect(icon.size, 64);
      expect(icon.color, AppColor.primary);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      final titleStyle = tester
          .renderObject<RenderParagraph>(find.text(title))
          .text
          .style!;
      expect(titleStyle.fontFamily, AppFonts.ibmPlexSansArabic);
      expect(titleStyle.fontWeight, FontWeight.bold);
      expect(titleStyle.color, AppColor.textPrimary);
      expect(
        titleStyle.fontSize,
        Theme.of(
          tester.element(find.byType(AppStatusMessage)),
        ).textTheme.titleLarge!.fontSize,
      );
      final messageStyle = tester
          .renderObject<RenderParagraph>(find.text(message))
          .text
          .style!;
      expect(messageStyle.fontFamily, AppFonts.ibmPlexSansArabic);
      expect(messageStyle.color, AppColor.textSecondary);
      expect(
        messageStyle.fontSize,
        Theme.of(
          tester.element(find.byType(AppStatusMessage)),
        ).textTheme.bodyLarge!.fontSize,
      );
      // The title leads the hierarchy.
      expect(titleStyle.fontSize, greaterThan(messageStyle.fontSize!));
      expect(find.byType(AppButton), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('absent message and action leave no empty gaps', (
      tester,
    ) async {
      await pumpStatus(
        tester,
        const AppStatusMessage(icon: Icons.map, title: title),
      );
      final column = find.descendant(
        of: find.byType(AppStatusMessage),
        matching: find.byType(Column),
      );
      final titleHeight = tester.getSize(find.text(title)).height;
      // Icon (64) + 16 gap + title, and nothing else.
      expect(tester.getSize(column).height, 64 + 16 + titleHeight);
      expect(
        find.descendant(of: column, matching: find.byType(Text)),
        findsOneWidget,
      );
    });

    testWidgets('loading: spinner replaces the icon, same spacing', (
      tester,
    ) async {
      await pumpStatus(
        tester,
        const AppStatusMessage(icon: Icons.map, title: title, isLoading: true),
      );
      expect(find.byIcon(Icons.map), findsNothing);
      final spinner = find.byType(CircularProgressIndicator);
      expect(spinner, findsOneWidget);
      expect(tester.getSize(spinner), const Size.square(40));
      expect(
        tester.getTopLeft(find.text(title)).dy -
            tester.getBottomLeft(spinner).dy,
        16,
      );
    });

    testWidgets('the action is an AppButton: named, 48 px, repeatable', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var calls = 0;
      await pumpStatus(
        tester,
        AppStatusMessage(
          icon: Icons.map,
          title: title,
          actionLabel: retry,
          onAction: () => calls++,
        ),
      );
      final button = find.widgetWithText(AppButton, retry);
      expect(button, findsOneWidget);
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
      expect(
        tester.getSemantics(find.widgetWithText(FilledButton, retry)),
        isSemantics(
          label: retry,
          isButton: true,
          hasTapAction: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
        ),
      );
      // A status Retry is repeatable (unlike a toast's one-shot action).
      await tester.tap(button);
      await tester.tap(button);
      expect(calls, 2);
      semantics.dispose();
    });

    testWidgets('loading keeps a provided action interactive (as today)', (
      tester,
    ) async {
      var calls = 0;
      await pumpStatus(
        tester,
        AppStatusMessage(
          icon: Icons.map,
          title: title,
          actionLabel: retry,
          onAction: () => calls++,
          isLoading: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.widgetWithText(AppButton, retry));
      expect(calls, 1);
    });

    for (final loading in [false, true]) {
      testWidgets('semantics (loading: $loading): one live status, no dupes', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await pumpStatus(
          tester,
          AppStatusMessage(
            icon: Icons.map,
            title: title,
            message: message,
            actionLabel: retry,
            onAction: () {},
            isLoading: loading,
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        final status = find.bySemanticsLabel('$title\n$message');
        expect(status, findsOneWidget);
        final data = tester.getSemantics(status).getSemanticsData();
        expect(data.flagsCollection.isLiveRegion, isTrue);
        // Title and message are announced once; the spinner is silent.
        expect(find.bySemanticsLabel(RegExp(title)), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp(message)), findsOneWidget);
        expect(data.value, isEmpty);
        semantics.dispose();
      });
    }

    testWidgets('a state change updates the same live region', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpStatus(
        tester,
        const AppStatusMessage(icon: Icons.map, title: 'أ', isLoading: true),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final before = tester.getSemantics(find.bySemanticsLabel('أ')).id;
      await pumpStatus(
        tester,
        const AppStatusMessage(icon: Icons.map, title: 'ب', message: 'ج'),
      );
      final after = tester.getSemantics(find.bySemanticsLabel('ب\nج'));
      expect(after.id, before);
      expect(after.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
      semantics.dispose();
    });

    testWidgets('centered in the area the parent gives, not the screen', (
      tester,
    ) async {
      setScreenSize(tester, 375, 667);
      await tester.pumpWidget(
        testApp(
          Column(
            children: [
              const SizedBox(height: 200),
              Expanded(
                child: AppStatusMessage(
                  icon: Icons.map,
                  title: title,
                  actionLabel: retry,
                  onAction: () {},
                ),
              ),
            ],
          ),
        ),
      );
      final column = find.descendant(
        of: find.byType(AppStatusMessage),
        matching: find.byType(Column),
      );
      // Area: 200..667, so its center is at 433.5.
      expect(tester.getCenter(column).dy, moreOrLessEquals(433.5, epsilon: 1));
      expect(tester.getCenter(column).dx, moreOrLessEquals(187.5, epsilon: 1));
    });

    for (final direction in TextDirection.values) {
      testWidgets('$direction: content centered on the same axis', (
        tester,
      ) async {
        setScreenSize(tester, 375, 667);
        await tester.pumpWidget(
          testApp(
            Directionality(
              textDirection: direction,
              child: AppStatusMessage(
                icon: Icons.map,
                title: title,
                message: message,
                actionLabel: retry,
                onAction: () {},
              ),
            ),
          ),
        );
        for (final part in [
          find.byIcon(Icons.map),
          find.text(title),
          find.text(message),
          find.byType(AppButton),
        ]) {
          expect(
            tester.getCenter(part).dx,
            moreOrLessEquals(187.5, epsilon: 1),
          );
        }
        expect(
          tester.renderObject<RenderParagraph>(find.text(title)).textDirection,
          direction,
        );
      });
    }

    /// Shared layout checks: no overflow, nothing truncated, and the action
    /// can be scrolled into view and tapped.
    Future<void> expectUsable(WidgetTester tester) async {
      expect(tester.takeException(), isNull);
      for (final text in [title, message, retry]) {
        expect(
          tester
              .renderObject<RenderParagraph>(find.text(text))
              .didExceedMaxLines,
          isFalse,
        );
      }
      await tester.ensureVisible(find.byType(AppButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AppButton));
    }

    for (final width in [320.0, 375.0, 450.0]) {
      for (final scale in [1.0, 2.0, 3.0]) {
        for (final height in [640.0, 300.0]) {
          testWidgets('$width×$height at text scale $scale: usable', (
            tester,
          ) async {
            setScreenSize(tester, width, height);
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            var calls = 0;
            await pumpStatus(
              tester,
              AppStatusMessage(
                icon: Icons.map,
                title: title,
                message: message,
                actionLabel: retry,
                onAction: () => calls++,
              ),
            );
            await expectUsable(tester);
            expect(calls, 1);
          });
        }
      }
    }

    testWidgets('keyboard open on a short screen: scrolls, action reachable', (
      tester,
    ) async {
      setScreenSize(tester, 320, 480);
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      addTearDown(tester.view.resetViewInsets);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      var calls = 0;
      await pumpStatus(
        tester,
        AppStatusMessage(
          icon: Icons.map,
          title: title,
          message: message,
          actionLabel: retry,
          onAction: () => calls++,
        ),
      );
      await expectUsable(tester);
      expect(
        tester.getRect(find.byType(AppButton)).bottom,
        lessThanOrEqualTo(220.5),
      );
      expect(calls, 1);
    });
  });
}
