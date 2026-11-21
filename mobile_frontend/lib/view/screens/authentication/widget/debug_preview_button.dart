// TEMPORARY development aid: the Login "preview the app" button.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/view/widget/buttons/app_button.dart';

// TODO(debug-preview): delete this file together with DebugShellPreview
// once a real backend sign-in exists.

/// Opens the main navigation shell without signing in, so Home and the
/// other tabs can be developed before the backend exists.
///
/// `LoginScreen` builds it only in debug builds. It is styled as a tool
/// (outlined, bug icon, "development only" caption), not as a login option.
/// It signs nobody in: [onPressed] only switches on the debug route preview.
class DebugPreviewButton extends StatelessWidget {
  const DebugPreviewButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          label: l10n.debugPreviewButton,
          expand: true,
          icon: const Icon(Icons.bug_report_outlined, size: 20),
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: AppColor.secondary,
          border: const BorderSide(color: AppColor.inputOutline),
          onPressed: onPressed,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.debugPreviewNote,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColor.textSecondary),
        ),
      ],
    );
  }
}
