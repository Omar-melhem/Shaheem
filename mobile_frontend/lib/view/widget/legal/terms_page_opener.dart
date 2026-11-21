// Opens the Terms & Conditions page in-app, or explains why it did not.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/helper/legal/legal_page_launcher.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/view/widget/pop_up_screen/app_popup.dart';

/// The one Terms flow shared by Login and the «حسابي» tab (D-A77): asks
/// [launcher] (the same `LegalLinks` URL, in-app only) to show the page;
/// when that does not happen (no URL published yet, unsupported device,
/// invalid configuration or a load failure) a SHAHM popup says so.
/// Nothing is ever opened outside the app.
Future<void> openTermsPage(
  BuildContext context,
  LegalPageLauncher launcher,
) async {
  final result = await launcher.openTermsAndConditions();
  if (!context.mounted || result == LegalPageOpenResult.opened) return;
  final l10n = context.l10n;
  await showAppPopup<void>(
    context,
    icon: const Icon(
      Icons.description_outlined,
      size: 40,
      color: AppColor.primary,
    ),
    title: l10n.termsAndConditions,
    message: result == LegalPageOpenResult.notConfigured
        ? l10n.termsUnavailableMessage
        : l10n.termsOpenFailedMessage,
    actions: [AppPopupAction(label: l10n.close, isPrimary: true)],
  );
}
