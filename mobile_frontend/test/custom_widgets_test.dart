// Widget tests for the shared custom components: AppTextFormField,
// AppButton, AppTextButton, AppPopup and AppToast — in Arabic RTL.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_frontend/util/tools/tools.dart';
import 'package:mobile_frontend/view/widget/buttons/app_button.dart';
import 'package:mobile_frontend/view/widget/buttons/app_icon_position.dart';
import 'package:mobile_frontend/view/widget/buttons/app_text_button.dart';
import 'package:mobile_frontend/view/widget/pop_up_screen/app_popup.dart';
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

    testWidgets('start icon is on the right in RTL, end icon on the left', (
      tester,
    ) async {
      await pump(
        tester,
        const SizedBox(
          width: 300,
          child: AppTextFormField(
            startIcon: Icon(Icons.person),
            endIcon: Icon(Icons.search),
          ),
        ),
      );
      final start = tester.getCenter(find.byIcon(Icons.person));
      final end = tester.getCenter(find.byIcon(Icons.search));
      expect(start.dx, greaterThan(end.dx));
    });

    testWidgets('password toggle shows/hides without changing the value', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'secret');
      await pump(
        tester,
        SizedBox(
          width: 300,
          child: AppTextFormField(controller: controller, obscureText: true),
        ),
      );
      EditableText editable() =>
          tester.widget<EditableText>(find.byType(EditableText));
      expect(editable().obscureText, isTrue);

      await tester.tap(find.byTooltip(l10n.showPassword));
      await tester.pump();
      expect(editable().obscureText, isFalse);
      expect(controller.text, 'secret');

      await tester.tap(find.byTooltip(l10n.hidePassword));
      await tester.pump();
      expect(editable().obscureText, isTrue);
      expect(controller.text, 'secret');
    });

    testWidgets('callbacks, disabled and read-only', (tester) async {
      String? changed;
      await pump(
        tester,
        SizedBox(
          width: 300,
          child: AppTextFormField(onChanged: (v) => changed = v),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'abc');
      expect(changed, 'abc');

      await pump(
        tester,
        const SizedBox(
          width: 300,
          child: AppTextFormField(enabled: false, readOnly: true),
        ),
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enabled, isFalse);
      expect(field.readOnly, isTrue);
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
  });

  group('AppTextButton', () {
    testWidgets('callback, disabled and end icon placement', (tester) async {
      var taps = 0;
      await pump(
        tester,
        AppTextButton(
          label: 'More',
          icon: const Icon(Icons.chevron_left),
          iconPosition: AppIconPosition.end,
          onPressed: () => taps++,
        ),
      );
      await tester.tap(find.text('More'));
      expect(taps, 1);
      // End = left in RTL.
      expect(
        tester.getCenter(find.byIcon(Icons.chevron_left)).dx,
        lessThan(tester.getCenter(find.text('More')).dx),
      );

      await pump(tester, const AppTextButton(label: 'More', onPressed: null));
      expect(
        tester.widget<TextButton>(find.byType(TextButton)).onPressed,
        isNull,
      );
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

    testWidgets('barrier dismiss can be disabled', (tester) async {
      late BuildContext ctx;
      await pump(tester, contextProbe((c) => ctx = c));
      showAppPopup<void>(ctx, title: 'T', barrierDismissible: false);
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byType(AppPopup), findsOneWidget);
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

    testWidgets('tools.dart helpers delegate to AppToast', (tester) async {
      late BuildContext ctx;
      await pump(tester, contextProbe((c) => ctx = c));
      appTools.showErrorMessage('خطأ ما', ctx);
      await tester.pump();
      expect(
        tester.widget<AppToast>(find.byType(AppToast)).type,
        AppToastType.error,
      );
    });
  });
}
