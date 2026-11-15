// Login "Terms & Conditions" action: opens the legal page in-app only.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/helper/legal/legal_page_launcher.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/view/widget/buttons/app_text_button.dart';
import 'package:mobile_frontend/view/widget/pop_up_screen/app_popup.dart';

/// The «الشروط والأحكام» text action under the Login form.
///
/// Information only: it is **not** a consent control (no checkbox, nothing
/// to accept). A tap asks [legalPageLauncher] to show the page inside the
/// app; when that does not happen (no URL published yet, unsupported
/// device, invalid configuration or a load failure) a SHAHM popup says so.
/// Nothing is ever opened outside the app.
///
/// Owns only a short-lived "opening" flag so a double tap opens one page.
class LoginTermsAction extends StatefulWidget {
  const LoginTermsAction({super.key, required this.legalPageLauncher});

  /// Decides whether and how the page opens (in-app only).
  final LegalPageLauncher legalPageLauncher;

  @override
  State<LoginTermsAction> createState() => _LoginTermsActionState();
}

class _LoginTermsActionState extends State<LoginTermsAction> {
  /// True while an open request is in flight (ignores repeated taps).
  bool _opening = false;

  Future<void> _open() async {
    if (_opening) return;
    _opening = true;
    // Hide the keyboard first (like Login submit): the page or popup then
    // gets the full screen height.
    FocusScope.of(context).unfocus();
    try {
      final result = await widget.legalPageLauncher.openTermsAndConditions();
      if (!mounted || result == LegalPageOpenResult.opened) return;
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
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always actionable: every tap leads to the page or a truthful popup.
    return AppTextButton(
      label: context.l10n.termsAndConditions,
      onPressed: _open,
    );
  }
}
