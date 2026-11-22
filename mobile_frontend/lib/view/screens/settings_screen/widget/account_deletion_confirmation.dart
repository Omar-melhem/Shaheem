// Settings: the dedicated account-deletion confirmation (D-A78).

import 'package:flutter/material.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/view/widget/pop_up_screen/app_popup.dart';

/// Explains the effect in plain Arabic and asks for an explicit choice.
/// Completes with true only for «تأكيد الحذف»; Cancel, the barrier or
/// system back complete with false, and nothing is sent.
///
/// The text states only what is known: the request concerns the account
/// and its associated personal data, completion may take time, records the
/// law requires may be kept, and the details are stated once the deletion
/// service is in place (D-P39). It invents no retention period.
Future<bool> showAccountDeletionConfirmation(BuildContext context) async {
  final l10n = context.l10n;
  // The typed popup result (R06): only the confirm action completes with
  // true; every other way out completes with null.
  final confirmed = await showAppPopup<bool>(
    context,
    icon: const Icon(Icons.delete_outline, size: 40, color: AppColor.error),
    title: l10n.accountDeletionConfirmTitle,
    message: l10n.accountDeletionConfirmMessage,
    actions: [
      AppPopupAction(label: l10n.cancel),
      AppPopupAction<bool>(
        label: l10n.accountDeletionConfirmAction,
        isPrimary: true,
        isDestructive: true,
        result: true,
      ),
    ],
  );
  return confirmed ?? false;
}
