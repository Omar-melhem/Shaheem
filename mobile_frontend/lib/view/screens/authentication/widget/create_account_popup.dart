// "Create account" information popup.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/view/widget/pop_up_screen/app_popup.dart';

/// Explains that accounts are created by contacting SHAHM administration.
///
/// There is no public registration (no form, no endpoint); this only
/// informs the user. Uses the shared [AppPopup].
Future<void> showCreateAccountPopup(BuildContext context) {
  final l10n = context.l10n;
  return showAppPopup<void>(
    context,
    icon: const Icon(
      Icons.person_add_alt_1_outlined,
      size: 40,
      color: AppColor.primary,
    ),
    title: l10n.createAccountTitle,
    message: l10n.createAccountMessage,
    actions: [AppPopupAction(label: l10n.close, isPrimary: true)],
  );
}
