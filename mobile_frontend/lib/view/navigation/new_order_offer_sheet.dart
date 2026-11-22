// Bottom-sheet content for one newly arrived order offer (Task 36).

import 'package:flutter/material.dart';
import 'package:mobile_frontend/domain/entities/order_offer.dart';
import 'package:mobile_frontend/helper/date/date_time_format.dart';
import 'package:mobile_frontend/helper/money/jod_format.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/view/widget/buttons/app_button.dart';
import 'package:mobile_frontend/view/widget/buttons/app_text_button.dart';
import 'package:mobile_frontend/view/widget/order/app_order_offer_card.dart';

/// One new offer, presentation only: shown inside a modal bottom sheet by
/// `NewOfferSheetHost` (and by the design preview, with sample data).
///
/// Top to bottom: the title, an «حالي» / «مؤجل» badge (icon + text, not
/// color alone), the merchant, its pickup information, the customer
/// delivery **area** (never an address or a map point), the scheduled
/// pickup time for scheduled offers, a soft divider, then **one** money
/// row: the full delivery fee ([CaptainOrderOffer.deliveryFeeFils], as
/// sent). Missing values read "not available".
///
/// No commission rate, commission amount or computed net is shown (owner
/// change, Task 38, superseding Task 36's breakdown): the commission is
/// charged through the wallet (held on accept, debited on completion), so
/// it is not presented as a deduction from the fee. The commission
/// snapshot still decides whether accepting is allowed — that check lives
/// in the host (`offerAcceptBlock`), not in this widget.
///
/// The details scroll; the actions stay visible under them (on a screen too
/// short for both at the current text size, they scroll with the details,
/// so nothing is clipped): «قبول الطلب»
/// (the theme's filled red primary, check icon), «رفض الطلب» (neutral
/// outline, close icon) and «لاحقاً» (D-A69). Like [AppOrderOfferCard], it owns no state: null
/// callbacks disable an action, [busyAction] shows the running command
/// (both answers then ignore taps), and [notice] is an optional localized
/// explanation. Whether accepting is allowed is the caller's decision.
class NewOrderOfferSheet extends StatelessWidget {
  const NewOrderOfferSheet({
    super.key,
    required this.offer,
    required this.onAccept,
    required this.onDecline,
    required this.onLater,
    this.busyAction,
    this.notice,
  });

  /// The offer to show (server values only).
  final CaptainOrderOffer offer;

  /// Accept intent; null disables «قبول الطلب».
  final VoidCallback? onAccept;

  /// Decline intent (this captain only); null disables «رفض الطلب».
  final VoidCallback? onDecline;

  /// Closes the sheet without answering; null disables «لاحقاً» (e.g.
  /// while a command runs).
  final VoidCallback? onLater;

  /// The command that is running, if any.
  final AppOfferCardAction? busyAction;

  /// Optional localized explanation above the actions; null shows nothing.
  final String? notice;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final busy = busyAction != null;
    final declineActive = busy
        ? busyAction == AppOfferCardAction.decline
        : onDecline != null;
    final unavailable = l10n.offerValueUnavailable;
    final scheduled = offer.kind == OrderOfferKind.scheduled;
    final pickup = offer.pickupLabel?.trim().isNotEmpty ?? false
        ? offer.pickupLabel!
        : unavailable;
    final pickupAt = offer.scheduledPickupAt;
    // The full fee exactly as the server sent it (never net of commission).
    final fee =
        '${ltrIsolate(formatJodFils(offer.deliveryFeeFils))} '
        '${l10n.walletCurrencySymbol}';

    final details = Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 26,
                color: colors.secondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.newOfferSheetTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: _KindBadge(
              icon: scheduled ? Icons.schedule : Icons.bolt,
              label: scheduled
                  ? l10n.offerKindScheduled
                  : l10n.offerKindInstant,
            ),
          ),
          const SizedBox(height: 20),
          _InfoLine(
            icon: Icons.storefront_outlined,
            text: offer.merchantName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          _InfoLine(
            icon: Icons.location_on_outlined,
            text: l10n.offerPickupLine(pickup),
          ),
          const SizedBox(height: 14),
          _InfoLine(
            icon: Icons.flag_outlined,
            text: l10n.offerDeliveryAreaLine(offer.deliveryAreaName),
          ),
          if (scheduled) ...[
            const SizedBox(height: 14),
            _InfoLine(
              icon: Icons.calendar_month_outlined,
              text: l10n.offerScheduledPickupLine(
                pickupAt == null
                    ? unavailable
                    : ltrIsolate(formatLocalDateTime(pickupAt)),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Divider(
            height: 1,
            thickness: 0.7,
            color: AppColor.divider.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 16),
          _FeeLine(label: l10n.offerGrossFeeLabel, value: fee),
          if (notice != null) ...[
            const SizedBox(height: 12),
            Semantics(
              container: true,
              liveRegion: true,
              child: Text(
                notice!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColor.textPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
    final actions = Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppButton(
                  label: l10n.offerAcceptFull,
                  icon: const Icon(Icons.check_circle_outline),
                  expand: true,
                  // Affirmative primary action: the theme's filled red (D-A69),

                  // with its pressed and disabled states.
                  isLoading: busyAction == AppOfferCardAction.accept,
                  onPressed: busy
                      ? _ignore(busyAction, AppOfferCardAction.accept)
                      : onAccept,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: l10n.offerDeclineFull,
                  icon: const Icon(Icons.close),
                  expand: true,

                  // Neutral outline with an explicit «رفض» label and close

                  // icon, distinct from the red Accept (D-A69). Disabled falls

                  // back to the theme's disabled colors.
                  backgroundColor: colors.surface,
                  foregroundColor: AppColor.textPrimary,
                  border: declineActive
                      ? const BorderSide(color: AppColor.inputOutline)
                      : null,
                  isLoading: busyAction == AppOfferCardAction.decline,
                  onPressed: busy
                      ? _ignore(busyAction, AppOfferCardAction.decline)
                      : onDecline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AppTextButton(
            label: l10n.offerLater,
            onPressed: busy ? null : onLater,
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Pinned under the scrolling details when there is room for both at
        // this text size; on a very short screen (landscape, large text)
        // the actions scroll with the details instead of being clipped.
        final scale = MediaQuery.textScalerOf(context).scale(1);
        if (constraints.maxHeight < _pinnedActionsMinHeight * scale) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [details, actions],
            ),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(child: SingleChildScrollView(child: details)),
            actions,
          ],
        );
      },
    );
  }

  /// Height (at text scale 1, grown with the scale) under which the
  /// actions stop being pinned: about twice the pinned action area, so the
  /// details always keep a usable scrolling part.
  static const double _pinnedActionsMinHeight = 300;

  /// While busy: the running action keeps a no-op callback (AppButton
  /// shows its spinner and ignores taps); the other one is disabled.
  static VoidCallback? _ignore(
    AppOfferCardAction? running,
    AppOfferCardAction self,
  ) => running == self ? () {} : null;
}

/// «حالي» / «مؤجل»: an outlined dark-neutral badge with an icon and its
/// text.
class _KindBadge extends StatelessWidget {
  const _KindBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.secondary;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A decorative dark-neutral icon (no semantics of its own) at the logical start
/// of a line that wraps beside it.
class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text, this.style});

  final IconData icon;
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 22, color: Theme.of(context).colorScheme.secondary),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          style: style ?? Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    ],
  );
}

/// The single money row: a truck icon and the localized label, then the
/// full fee as a prominent red amount (as on the card). A [Wrap], so at narrow widths
/// and large text the amount moves under the label instead of being
/// squeezed. Read as one sentence by screen readers.
class _FeeLine extends StatelessWidget {
  const _FeeLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.secondary;
    return MergeSemantics(
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_shipping_outlined, size: 22, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
