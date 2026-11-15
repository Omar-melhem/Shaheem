// Shared centered status block: empty, error and "not available" states.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/util/responsive/app_breakpoints.dart';
import 'package:mobile_frontend/view/widget/buttons/app_button.dart';

/// An icon, a title, an optional message and an optional action, centered
/// in whatever area the parent gives it.
///
/// Meant for a screen body (below the app bar, above the navigation bar):
/// it centers within that area, not within the physical screen, and adds no
/// `SafeArea` of its own because the surrounding `Scaffold`s already
/// consumed the insets. It scrolls when the area is too short.
///
/// Screen readers get one live region whose label is the title and the
/// message, announced again when they change; the icon and the spinner are
/// silent, and the action is a separate, named [AppButton].
class AppStatusMessage extends StatelessWidget {
  /// Creates a status block.
  ///
  /// [actionLabel] and [onAction] come as a pair: either both or neither
  /// (asserted), so there is never a dead or an unlabelled action.
  const AppStatusMessage({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.isLoading = false,
  }) : assert(
         actionLabel == null || onAction != null,
         'AppStatusMessage: actionLabel needs onAction; a label without a '
         'callback would be a dead button. Pass onAction or remove '
         'actionLabel.',
       ),
       assert(
         onAction == null || actionLabel != null,
         'AppStatusMessage: onAction needs actionLabel; an action without a '
         'label is inaccessible. Pass a localized actionLabel or remove '
         'onAction.',
       );

  /// Decorative icon (64 px, brand primary), excluded from semantics.
  /// Not shown while [isLoading]: the spinner takes its place.
  final IconData icon;

  /// The status heading, and the start of the announcement. Required and
  /// not blank (asserted): it is what the status says. Shown as given.
  final String title;

  /// Optional explanation under the title; null shows nothing and leaves no
  /// gap. An empty or blank string asserts: pass null instead.
  final String? message;

  /// Label of the optional [AppButton] action, paired with [onAction].
  final String? actionLabel;

  /// Runs on every tap of the action (a status Retry is repeatable).
  final VoidCallback? onAction;

  /// Shows a 40 px spinner instead of the icon. The spinner is silent: the
  /// loading meaning comes from [title] (e.g. «جارٍ ...»). A provided action
  /// stays interactive while loading.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    assert(
      title.trim().isNotEmpty,
      'AppStatusMessage: title must not be blank; it is what the status says '
      'and what screen readers announce. Pass the localized title.',
    );
    assert(
      message == null || message!.trim().isNotEmpty,
      'AppStatusMessage: message must not be empty or blank; pass null to '
      'show no message.',
    );
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: AppBreakpoints.screenPadding(context),
          vertical: 24,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppBreakpoints.formMaxWidth(context),
          ),
          // Announced as one unit, and again whenever the state changes.
          child: Semantics(
            container: true,
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  const SizedBox.square(
                    dimension: 40,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                else
                  ExcludeSemantics(
                    child: Icon(icon, size: 64, color: AppColor.primary),
                  ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColor.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColor.textSecondary,
                    ),
                  ),
                ],
                if (actionLabel != null) ...[
                  const SizedBox(height: 24),
                  AppButton(label: actionLabel, onPressed: onAction),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
