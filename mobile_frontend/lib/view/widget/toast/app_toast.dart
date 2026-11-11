// Shared toast (snackbar) component and its show helper.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';

/// Kind of toast. Each has its own icon and screen-reader prefix, so the
/// status is never conveyed by color alone.
enum AppToastType { success, error, warning, info }

/// Visual content of a toast: icon, message, optional action and close.
///
/// Shown through [showAppToast], which uses Flutter's [ScaffoldMessenger]
/// (no toast package). Colors come from the existing theme and brand
/// tokens; no new colors are introduced.
class AppToast extends StatelessWidget {
  const AppToast({
    super.key,
    required this.message,
    required this.type,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.onClose,
  });

  final String message;
  final AppToastType type;

  /// Overrides the type's default icon.
  final IconData? icon;

  /// Optional action (e.g. Retry). Both label and callback are required
  /// for it to appear.
  final String? actionLabel;
  final VoidCallback? onAction;

  /// When set, shows a labelled close button.
  final VoidCallback? onClose;

  /// Background color per type, from existing theme/brand tokens.
  static Color backgroundFor(BuildContext context, AppToastType type) =>
      switch (type) {
        AppToastType.success => AppColor.secondary,
        AppToastType.error => Theme.of(context).colorScheme.error,
        AppToastType.warning => AppColor.sandDark,
        AppToastType.info => AppColor.ink,
      };

  static IconData _iconFor(AppToastType type) => switch (type) {
    AppToastType.success => Icons.check_circle_outline,
    AppToastType.error => Icons.error_outline,
    AppToastType.warning => Icons.warning_amber_rounded,
    AppToastType.info => Icons.info_outline,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final statusLabel = switch (type) {
      AppToastType.success => l10n.toastSuccess,
      AppToastType.error => l10n.toastError,
      AppToastType.warning => l10n.toastWarning,
      AppToastType.info => l10n.toastInfo,
    };
    const foreground = AppColor.white;

    return Semantics(
      liveRegion: true,
      label: l10n.toastAnnouncement(statusLabel, message),
      // The visible parts below repeat the same information.
      excludeSemantics: false,
      child: Row(
        children: [
          ExcludeSemantics(
            child: Icon(icon ?? _iconFor(type), color: foreground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ExcludeSemantics(
              child: Text(
                message,
                style: const TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: foreground,
                minimumSize: const Size(48, 40),
              ),
              child: Text(actionLabel!),
            ),
          if (onClose != null)
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, color: foreground),
              tooltip: l10n.close,
            ),
        ],
      ),
    );
  }
}

/// Shows a toast at the bottom of the current screen.
///
/// Replaces any toast already visible, so repeated errors don't stack.
/// Requires a [ScaffoldMessenger] ancestor (provided by `MaterialApp`).
void showAppToast(
  BuildContext context, {
  required String message,
  AppToastType type = AppToastType.info,
  Duration duration = const Duration(seconds: 4),
  String? actionLabel,
  VoidCallback? onAction,
  bool showCloseButton = true,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: duration,
        backgroundColor: AppToast.backgroundFor(context, type),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: AppToast(
          message: message,
          type: type,
          actionLabel: actionLabel,
          onAction: onAction == null
              ? null
              : () {
                  messenger.hideCurrentSnackBar();
                  onAction();
                },
          onClose: showCloseButton ? messenger.hideCurrentSnackBar : null,
        ),
      ),
    );
}
