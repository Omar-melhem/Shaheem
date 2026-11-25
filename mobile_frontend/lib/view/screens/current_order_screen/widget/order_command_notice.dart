// Current Order: the message of a workflow command that did not
// (knowingly) succeed, and its reconciliation action.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/helper/translation/generated/app_localizations.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/cubit/current_order_cubit.dart';
import 'package:mobile_frontend/view/widget/buttons/app_text_button.dart';

/// The localized text for [feedback]'s error (null while sending).
///
/// Each outcome says what is known: "not sent" only when nothing was sent,
/// "unknown" after a timeout, and server rejections as such.
String? orderCommandMessage(
  AppLocalizations l10n,
  OrderCommandFeedback feedback,
) => switch (feedback.error) {
  null => null,
  OrderCommandError.stateConflict => l10n.orderCommandStateConflict,
  OrderCommandError.notConfigured => l10n.orderCommandNotConfigured,
  OrderCommandError.noInternet => l10n.orderCommandNoInternet,
  OrderCommandError.unconfirmed => l10n.orderCommandUnconfirmed,
  OrderCommandError.checkFailed => l10n.orderCommandCheckFailed,
  OrderCommandError.checkPending => l10n.orderCommandCheckPending,
};

/// Shows [feedback]'s message as a live region, plus «تحقّق من حالة الطلب»
/// when the outcome is unknown. Renders nothing while sending.
class OrderCommandNotice extends StatelessWidget {
  const OrderCommandNotice({
    super.key,
    required this.feedback,
    required this.onCheckStatus,
  });

  final OrderCommandFeedback feedback;

  /// Reconciles an unknown outcome (never resends with a new key).
  final VoidCallback onCheckStatus;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = orderCommandMessage(l10n, feedback);
    if (text == null) return const SizedBox.shrink();
    final isWarning = feedback.error != OrderCommandError.stateConflict;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Semantics(
        container: true,
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isWarning ? AppColor.error : AppColor.textSecondary,
              ),
            ),
            if (feedback.needsReconciliation)
              AppTextButton(
                label: l10n.orderCommandCheckStatus,
                onPressed: onCheckStatus,
              ),
          ],
        ),
      ),
    );
  }
}
