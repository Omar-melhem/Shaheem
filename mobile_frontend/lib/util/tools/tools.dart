// Reusable UI helpers: loading overlay, dialogs, toasts, bottom sheet,
// keyboard dismissal, plus two small formatting helpers.
//
// Migrated from a GetX project: GetX navigation was replaced by an explicit
// BuildContext and translation keys by the gen_l10n `AppLocalizations`.
// Dialogs and toasts keep their public methods but now delegate to the
// shared AppPopup and AppToast components, so there is only one dialog and
// one notification system. Form validators live in `util/validators/`; do
// not add validation or business rules back here.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/util/tools/android_loading.dart';
import 'package:mobile_frontend/util/tools/ios_loading.dart';
import 'package:mobile_frontend/view/widget/pop_up_screen/app_popup.dart';
import 'package:mobile_frontend/view/widget/toast/app_toast.dart';

/// App-wide instance, kept from the old project's `appTools.method()` style.
final AppTools appTools = AppTools();

/// Stateless UI helper methods. Every method that shows or closes UI takes a
/// [BuildContext] from the calling widget.
class AppTools {
  /// Route name of the loading dialog, so it can be identified if needed.
  static const String loadingRouteName = 'loading';

  /// Hides the keyboard by removing focus from the current text field.
  void unFocusKeyboard(BuildContext context) {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
  }

  /// Returns a random integer (roughly 2,000,000–2,001,100,000).
  ///
  /// Not unique and not secure: never use it for record IDs, tokens or
  /// anything the backend should generate.
  int createRandom() {
    final random = math.Random();
    final randomFirst = random.nextInt(1000000000) + 1000000;
    final randomSecond = random.nextInt(100000) + randomFirst;
    return randomFirst + randomSecond;
  }

  /// Shows [child] in a scrollable, non-draggable bottom sheet with a
  /// transparent background (the child draws its own surface).
  Future<void> showCustomBottomSheet(
    BuildContext context,
    Widget child,
    bool isDismissible,
  ) async {
    await showModalBottomSheet<void>(
      enableDrag: false,
      elevation: 5,
      isScrollControlled: true,
      backgroundColor: AppColor.white.withValues(alpha: 0),
      context: context,
      isDismissible: isDismissible,
      builder: (BuildContext newContext) => SingleChildScrollView(child: child),
    );
  }

  /// Shows a blocking, non-dismissible loading dialog. Close it with
  /// [hideLoading] — call that exactly once per [showLoading].
  ///
  /// iOS/macOS get [IosLoading] (dark HUD, transparent barrier); Android and
  /// every other platform get [AndroidLoading] in a white dialog. The old
  /// version used `dart:io` Platform and showed nothing (and crashed on web)
  /// outside Android/iOS; the theme platform works everywhere.
  void showLoading(BuildContext context) {
    final platform = Theme.of(context).platform;
    final isApple =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

    if (isApple) {
      showDialog<void>(
        barrierDismissible: false,
        context: context,
        builder: (_) => const Center(child: IosLoading()),
        barrierColor: Colors.transparent,
        routeSettings: const RouteSettings(name: loadingRouteName),
      );
    } else {
      showDialog<void>(
        barrierDismissible: false,
        context: context,
        builder: (_) => const Dialog(
          backgroundColor: Colors.white,
          child: AndroidLoading(),
        ),
        routeSettings: const RouteSettings(name: loadingRouteName),
      );
    }
  }

  /// Closes the dialog opened by [showLoading]. The loading dialog is shown
  /// on the root navigator (the `showDialog` default), so it is popped there.
  void hideLoading(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// Formats a number of seconds as `mm:ss` (minutes wrap at 60).
  String timeFormatter(double time) {
    final duration = Duration(seconds: time.round());
    return <int>[
      duration.inMinutes,
      duration.inSeconds,
    ].map((int seg) => seg.remainder(60).toString().padLeft(2, '0')).join(':');
  }

  /// Confirm dialog with Cancel (destructive) and Confirm actions.
  ///
  /// Delegates to [showAppPopup]. Not dismissible by tapping outside. If
  /// [yes] or [no] is omitted, that button just closes the dialog. When you
  /// pass a callback, it is responsible for closing the dialog (as before).
  void showAlertDialogTwoFun(
    BuildContext context, {
    VoidCallback? yes,
    VoidCallback? no,
    String? title,
    String? content,
  }) {
    final l10n = context.l10n;
    showAppPopup<void>(
      context,
      title: title ?? l10n.alert,
      message: content ?? l10n.proceedQuestion,
      barrierDismissible: false,
      actions: [
        AppPopupAction(
          label: l10n.cancel,
          isDestructive: true,
          onPressed: no,
          closesPopup: no == null,
        ),
        AppPopupAction(
          label: l10n.confirm,
          isPrimary: true,
          onPressed: yes,
          closesPopup: yes == null,
        ),
      ],
    );
  }

  /// Alert with a warning icon and a single Confirm action.
  ///
  /// Delegates to [showAppPopup]. If [onTap] is omitted, Confirm just closes
  /// the dialog. When you pass a callback, it is responsible for closing it.
  void showAlertDialogOneFun(
    BuildContext context, {
    VoidCallback? onTap,
    String? title,
    String? content,
  }) {
    final l10n = context.l10n;
    showAppPopup<void>(
      context,
      title: title ?? l10n.alert,
      message: content ?? l10n.proceedQuestion,
      icon: const Icon(Icons.warning_amber_rounded, color: AppColor.red),
      barrierDismissible: false,
      actions: [
        AppPopupAction(
          label: l10n.confirm,
          isPrimary: true,
          onPressed: onTap,
          closesPopup: onTap == null,
        ),
      ],
    );
  }

  // Toast helpers: same public methods as before, now delegating to the
  // shared [showAppToast] (Flutter ScaffoldMessenger) instead of toasty_box.

  /// Success toast.
  void showSuccessMessage(String message, BuildContext context) =>
      showAppToast(context, message: message, type: AppToastType.success);

  /// Warning toast.
  void showWarningMessage(String message, BuildContext context) =>
      showAppToast(context, message: message, type: AppToastType.warning);

  /// Error toast.
  void showErrorMessage(String message, BuildContext context) =>
      showAppToast(context, message: message, type: AppToastType.error);

  /// Info toast. New, completing the four toast types.
  void showInfoMessage(String message, BuildContext context) =>
      showAppToast(context, message: message, type: AppToastType.info);
}
