// "Forgot password" information popup.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/view/widget/pop_up_screen/app_popup.dart';

/// Explains that passwords are changed by contacting SHAHM administration.
///
/// There is no automated reset (no endpoint, nothing sent); this only
/// informs the user. Uses the shared [AppPopup].
Future<void> showForgotPasswordPopup(BuildContext context) {
  final l10n = context.l10n;
  return showAppPopup<void>(
    context,
    icon: const Icon(Icons.lock_reset, size: 40, color: AppColor.primary),
    title: l10n.forgotPasswordTitle,
    message: l10n.forgotPasswordMessage,
    actions: [AppPopupAction(label: l10n.close, isPrimary: true)],
  );
}
