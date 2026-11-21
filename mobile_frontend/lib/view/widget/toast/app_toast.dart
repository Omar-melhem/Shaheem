// Shared toast (snackbar) component and its show helper.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';

/// Kind of toast. Each has its own icon and screen-reader prefix, so the
/// status is never conveyed by color alone.
enum AppToastType { success, error, warning, info }

/// Visual content of a toast: status icon, message, optional action and an
/// optional close button.
///
/// Shown through [showAppToast], which uses Flutter's [ScaffoldMessenger]
/// (no toast package). Colors come from the existing theme and brand
/// tokens (decision C-13); no new colors are introduced.
///
/// Layout: the icon sits at the start and the close button at the end
/// (logical, so Arabic RTL mirrors it). The action stays beside the message
/// when both fit on one line; otherwise it moves under the message, aligned
/// to the end, so neither is squeezed or overflows. The whole toast stays
/// between the status bar and the keyboard: when its content is taller
/// (very large text on a short screen), the message area scrolls and the
/// close button stays on screen.
class AppToast extends StatelessWidget {
  /// Creates the toast content.
  ///
  /// [actionLabel] and [onAction] come as a pair: either both or neither
  /// (asserted), so there is never a dead or an unlabelled action.
  const AppToast({
    super.key,
    required this.message,
    required this.type,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.onClose,
  }) : assert(
         actionLabel == null || onAction != null,
         'AppToast: actionLabel needs onAction; a label without a callback '
         'would be a dead button. Pass onAction or remove actionLabel.',
       ),
       assert(
         onAction == null || actionLabel != null,
         'AppToast: onAction needs actionLabel; an action without a label is '
         'inaccessible. Pass a localized actionLabel or remove onAction.',
       );

  /// The text shown and announced. Required: a toast without a message has
  /// nothing to say. Displayed exactly as given (never trimmed); a blank
  /// message asserts.
  final String message;

  /// The status: selects the icon, the background color and the localized
  /// screen-reader prefix.
  final AppToastType type;

  /// Overrides the type's default icon (null keeps the type's icon). The
  /// status prefix is still announced, so meaning never rests on the icon.
  final IconData? icon;

  /// Visible label of the optional action (e.g. «إعادة المحاولة»), supplied
  /// by the caller from ARB. Paired with [onAction].
  final String? actionLabel;

  /// Runs when the action is tapped. Paired with [actionLabel].
  final VoidCallback? onAction;

  /// When set, shows a close button with the localized «إغلاق» tooltip;
  /// null shows no close button.
  final VoidCallback? onClose;

  /// Vertical space the [SnackBar] adds around its content: the default
  /// floating inset (5 above, 10 below) plus its content padding (14 above
  /// and below). Used to keep the whole toast inside the visible height.
  static const double _snackBarChrome = 5 + 10 + 14 + 14;

  /// Background color per type, from existing theme/brand tokens (C-13).
  static Color backgroundFor(BuildContext context, AppToastType type) =>
      switch (type) {
        AppToastType.success => AppColor.success,
        AppToastType.error => Theme.of(context).colorScheme.error,
        AppToastType.warning => AppColor.warning,
        AppToastType.info => AppColor.textPrimary,
      };

  static IconData _iconFor(AppToastType type) => switch (type) {
    AppToastType.success => Icons.check_circle_outline,
    AppToastType.error => Icons.error_outline,
    AppToastType.warning => Icons.warning_amber_rounded,
    AppToastType.info => Icons.info_outline,
  };

  /// Gap kept between the toast and the status bar when it is at its
  /// tallest.
  static const double _topGap = 8;

  /// Tallest the message area may be: the height between the status bar
  /// and the keyboard, minus the SnackBar's own padding and [_topGap], but
  /// never below one 48 px control row. Ordinary messages are far shorter,
  /// so this only matters for very large text on short screens.
  static double _maxBodyHeight(BuildContext context) {
    // The Scaffold removes the top padding from the SnackBar's MediaQuery,
    // so the status bar height is read from the view itself.
    final view = View.of(context);
    final statusBar = view.viewPadding.top / view.devicePixelRatio;
    final visible =
        MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom -
        statusBar;
    return math.max(
      kMinInteractiveDimension,
      visible - _snackBarChrome - _topGap,
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(
      message.trim().isNotEmpty,
      'AppToast: message must not be blank; a toast without text has nothing '
      'to announce. Pass the localized message to show.',
    );
    assert(
      actionLabel == null || actionLabel!.trim().isNotEmpty,
      'AppToast: actionLabel must not be blank; it is the action\'s '
      'accessible name. Pass a localized label or remove the action.',
    );
    final l10n = context.l10n;
    final statusLabel = switch (type) {
      AppToastType.success => l10n.toastSuccess,
      AppToastType.error => l10n.toastError,
      AppToastType.warning => l10n.toastWarning,
      AppToastType.info => l10n.toastInfo,
    };
    const foreground = AppColor.white;

    // The message is announced through the status label above, so the
    // visible text is excluded to avoid reading it twice.
    final Widget text = ExcludeSemantics(
      child: Text(
        message,
        style: const TextStyle(color: foreground, fontWeight: FontWeight.w600),
      ),
    );

    final Widget body = actionLabel == null
        ? text
        // Inline when message and action fit on one line, otherwise the
        // action wraps under the message at the end (no squeezing).
        : OverflowBar(
            alignment: MainAxisAlignment.spaceBetween,
            spacing: 8,
            overflowAlignment: OverflowBarAlignment.end,
            children: [
              text,
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: foreground,
                  minimumSize: const Size(48, 40),
                ),
                child: Text(actionLabel!, textAlign: TextAlign.center),
              ),
            ],
          );

    return Semantics(
      liveRegion: true,
      label: l10n.toastAnnouncement(statusLabel, message),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Icon(icon ?? _iconFor(type), color: foreground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: _maxBodyHeight(context)),
              child: SingleChildScrollView(child: body),
            ),
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

/// Open/closed state of one toast shown by [showAppToast]: once closed
/// (action, close button, replacement or dismissal) its controls are inert.
class _ToastSession {
  bool isOpen = true;
}

/// The latest toast shown on each [ScaffoldMessengerState]. A weak,
/// file-private association (not a global service), so a replaced toast
/// can be marked closed even while it is still animating out.
final Expando<_ToastSession> _latestToast = Expando<_ToastSession>('AppToast');

/// Shows a toast at the bottom of the current screen.
///
/// - **Replacement:** replaces the visible toast and drops any queued one,
///   so only the latest message appears (repeated errors never stack or
///   replay late).
/// - **Action:** [actionLabel] and [onAction] come as a pair (asserted).
///   Tapping it closes the toast and runs [onAction] once; a toast that is
///   closing or was replaced never runs it.
/// - **Close:** [showCloseButton] (default true) shows a close button with a
///   localized tooltip.
/// - **Duration:** [duration] (default 4 s, must be positive) applies also
///   when an action is present; a screen reader does not extend it.
///
/// Requires a mounted [context] under a [ScaffoldMessenger] (provided by
/// `MaterialApp`); call it synchronously or after a `context.mounted`
/// check. Without a messenger, Flutter throws its own explanatory error.
void showAppToast(
  BuildContext context, {
  required String message,
  AppToastType type = AppToastType.info,
  Duration duration = const Duration(seconds: 4),
  String? actionLabel,
  VoidCallback? onAction,
  bool showCloseButton = true,
}) {
  assert(
    context.mounted,
    'showAppToast: context is no longer mounted. After an await, check '
    'context.mounted before showing a toast.',
  );
  assert(
    message.trim().isNotEmpty,
    'showAppToast: message must not be blank; a toast without text has '
    'nothing to announce. Pass the localized message to show.',
  );
  assert(
    actionLabel == null || onAction != null,
    'showAppToast: actionLabel needs onAction; a label without a callback '
    'would be a dead button. Pass onAction or remove actionLabel.',
  );
  assert(
    onAction == null || actionLabel != null,
    'showAppToast: onAction needs actionLabel; an action without a label is '
    'inaccessible. Pass a localized actionLabel or remove onAction.',
  );
  assert(
    actionLabel == null || actionLabel.trim().isNotEmpty,
    'showAppToast: actionLabel must not be blank; it is the action\'s '
    'accessible name. Pass a localized label or remove the action.',
  );
  assert(
    duration > Duration.zero,
    'showAppToast: duration must be positive; a zero or negative duration '
    'hides the toast before it can be read.',
  );

  final messenger = ScaffoldMessenger.of(context);

  // The previous toast becomes inert at once, even while animating out.
  _latestToast[messenger]?.isOpen = false;
  final session = _ToastSession();
  _latestToast[messenger] = session;

  /// Closes this toast once; later calls (double tap, stale toast) do nothing.
  bool close() {
    if (!session.isOpen) return false;
    session.isOpen = false;
    messenger.hideCurrentSnackBar();
    return true;
  }

  messenger
    // Hides the current toast and drops queued ones (true replacement).
    ..clearSnackBars()
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
                  if (close()) onAction();
                },
          onClose: showCloseButton ? close : null,
        ),
      ),
    ).closed.then((_) => session.isOpen = false);
}
