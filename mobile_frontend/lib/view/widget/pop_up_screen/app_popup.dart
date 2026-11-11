// Shared popup/dialog component and its show helper.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/text_themes.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/view/widget/buttons/app_button.dart';
import 'package:mobile_frontend/view/widget/buttons/app_text_button.dart';

/// One action button in an [AppPopup].
class AppPopupAction {
  const AppPopupAction({
    required this.label,
    this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
    this.closesPopup = true,
  });

  final String label;

  /// Runs after the popup closes (when [closesPopup] is true).
  final VoidCallback? onPressed;

  /// Primary actions render as [AppButton]; others as [AppTextButton].
  final bool isPrimary;

  /// Uses the error color, for irreversible actions.
  final bool isDestructive;

  /// Closes the popup before running [onPressed]. Set false when the
  /// callback manages the popup itself.
  final bool closesPopup;
}

/// The app's standard dialog: optional icon, title, scrollable content and
/// a row of actions. Width is capped so it never stretches on tablets or
/// desktops; long content scrolls instead of overflowing.
///
/// Show it with [showAppPopup]; it is a modal, not a GoRouter page.
class AppPopup extends StatelessWidget {
  const AppPopup({
    super.key,
    this.title,
    this.message,
    this.content,
    this.icon,
    this.actions = const [],
    this.showCloseButton = false,
    this.maxWidth = 480,
  }) : assert(
         message == null || content == null,
         'Use either message or content.',
       );

  final String? title;

  /// Plain text body. Use [content] for custom widgets instead.
  final String? message;
  final Widget? content;
  final Widget? icon;
  final List<AppPopupAction> actions;

  /// Shows a labelled close (X) button at the top end corner.
  final bool showCloseButton;

  /// Upper width bound on larger screens.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final navigator = Navigator.of(context);

    void runAction(AppPopupAction action) {
      if (action.closesPopup) navigator.pop();
      action.onPressed?.call();
    }

    final body =
        content ??
        (message == null
            ? null
            : Text(
                message!,
                textAlign: TextAlign.center,
                style: TextThemeStyle.bodyText1.copyWith(
                  color: AppColor.textSecondary,
                  height: 1.5,
                ),
              ));

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(24, 28, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[icon!, const SizedBox(height: 12)],
                  if (title != null)
                    Semantics(
                      header: true,
                      child: Text(
                        title!,
                        textAlign: TextAlign.center,
                        style: TextThemeStyle.headline5.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColor.textPrimary,
                        ),
                      ),
                    ),
                  if (body != null) ...[
                    const SizedBox(height: 12),
                    // Long content scrolls inside the dialog.
                    Flexible(child: SingleChildScrollView(child: body)),
                  ],
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final action in actions)
                          action.isPrimary
                              ? AppButton(
                                  label: action.label,
                                  onPressed: () => runAction(action),
                                  backgroundColor: action.isDestructive
                                      ? Theme.of(context).colorScheme.error
                                      : null,
                                )
                              : AppTextButton(
                                  label: action.label,
                                  onPressed: () => runAction(action),
                                  color: action.isDestructive
                                      ? Theme.of(context).colorScheme.error
                                      : null,
                                ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (showCloseButton)
              PositionedDirectional(
                top: 4,
                end: 4,
                child: IconButton(
                  onPressed: navigator.pop,
                  icon: const Icon(Icons.close),
                  tooltip: l10n.close,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shows an [AppPopup] as a modal dialog and completes when it closes.
///
/// [barrierDismissible] controls whether tapping outside closes it.
Future<T?> showAppPopup<T>(
  BuildContext context, {
  String? title,
  String? message,
  Widget? content,
  Widget? icon,
  List<AppPopupAction> actions = const [],
  bool showCloseButton = false,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (_) => AppPopup(
      title: title,
      message: message,
      content: content,
      icon: icon,
      actions: actions,
      showCloseButton: showCloseButton,
    ),
  );
}
