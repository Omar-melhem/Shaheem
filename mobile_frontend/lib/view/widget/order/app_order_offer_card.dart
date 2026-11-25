// Shared card for one order offer: merchant, pickup, delivery area, fee and
// the single accept action (D-A82).

import 'package:flutter/material.dart';
import 'package:mobile_frontend/domain/entities/order_offer.dart';
import 'package:mobile_frontend/helper/money/jod_format.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/view/widget/buttons/app_button.dart';

/// One order offer, presentation only.
///
/// Shows the merchant name, the merchant pickup information (or a neutral
/// "not available"), the customer delivery **area** and the delivery fee
/// (the **full** fee, integer fils formatted as JOD, never a double), and
/// **one** full-width «قبول» action (the theme's filled red primary with a
/// check icon). The card has no rejection action (D-A82): an unanswered
/// offer stays actionable until the server withdraws it. The new-offer
/// sheet has no decline either (it offers only Accept and «لاحقاً»).
///
/// It owns no state: the caller passes the offer, the accept callback (null
/// disables it), whether the accept is running ([accepting]), and an optional [notice]
/// line. A tap is an **intent**; the card never removes itself or changes
/// its look until the caller passes new values.
///
/// Look (Task 33 layout, D-A69 colors): a white card with a light
/// [AppColor.divider] outline and a restrained shadow; each detail starts
/// with a decorative dark-neutral (`colorScheme.secondary`) outlined icon
/// at the logical start — storefront (merchant), location pin (pickup),
/// flag (delivery area), payments (fee). A thin [AppColor.divider] line
/// separates the details from the fee, which is emphasized in red.
///
/// Full parent width, content height (it never has a fixed height); texts
/// wrap instead of being truncated. One screen-reader summary for the
/// offer, then the button. Previews use this card with sample data;
/// there is no second card implementation.
class AppOrderOfferCard extends StatelessWidget {
  /// Creates the card. [onAccept] is required so every caller decides;
  /// null disables it.
  const AppOrderOfferCard({
    super.key,
    required this.offer,
    required this.onAccept,
    this.accepting = false,
    this.notice,
  });

  /// The offer to show. Its name and area must not be blank, and its fee
  /// must not be negative (asserted).
  final CaptainOrderOffer offer;

  /// Accept intent; null disables «قبول».
  final VoidCallback? onAccept;

  /// Whether this offer's accept command is running: Accept then shows a
  /// spinner and ignores taps (duplicate-tap protection). Any other
  /// running command is the caller's to express by passing a null
  /// [onAccept].
  final bool accepting;

  /// Optional localized explanation under the details (e.g. "no longer
  /// available"). Null shows nothing; blank asserts.
  final String? notice;

  @override
  Widget build(BuildContext context) {
    assert(
      offer.merchantName.trim().isNotEmpty,
      'AppOrderOfferCard: offer.merchantName must not be blank.',
    );
    assert(
      offer.deliveryAreaName.trim().isNotEmpty,
      'AppOrderOfferCard: offer.deliveryAreaName must not be blank.',
    );
    assert(
      offer.deliveryFeeFils >= 0,
      'AppOrderOfferCard: offer.deliveryFeeFils must not be negative.',
    );
    assert(
      notice == null || notice!.trim().isNotEmpty,
      'AppOrderOfferCard: notice must not be blank; pass null instead.',
    );
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final fee = formatJodFils(offer.deliveryFeeFils);
    final pickup = offer.pickupLabel?.trim().isNotEmpty ?? false
        ? offer.pickupLabel!
        : l10n.offerPickupUnknown;
    final detailStyle = theme.textTheme.bodyMedium;
    final iconColor = colors.secondary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.divider),
        boxShadow: [
          BoxShadow(
            color: AppColor.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // One summary for screen readers; the visible lines repeat it.
            Semantics(
              container: true,
              label: l10n.offerCardSemantics(
                offer.merchantName,
                pickup,
                offer.deliveryAreaName,
                fee,
              ),
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        size: 24,
                        color: iconColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          offer.merchantName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _DetailLine(
                    icon: Icons.location_on_outlined,
                    color: iconColor,
                    text: l10n.offerPickupLine(pickup),
                    style: detailStyle,
                  ),
                  const SizedBox(height: 14),
                  _DetailLine(
                    icon: Icons.flag_outlined,
                    color: iconColor,
                    text: l10n.offerDeliveryAreaLine(offer.deliveryAreaName),
                    style: detailStyle,
                  ),
                  const SizedBox(height: 20),
                  const Divider(
                    height: 1,
                    thickness: 0.7,
                    color: AppColor.divider,
                  ),
                  const SizedBox(height: 20),
                  // Wrap instead of a Row: at narrow widths and large text
                  // the amount moves under the label instead of squeezing it.
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.payments_outlined,
                            size: 22,
                            color: iconColor,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              l10n.offerDeliveryFeeLabel,
                              style: detailStyle,
                            ),
                          ),
                        ],
                      ),
                      // LTR isolate keeps the sign and digits in order.
                      Text(
                        '${ltrIsolate(fee)} ${l10n.walletCurrencySymbol}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (notice != null) ...[
              const SizedBox(height: 8),
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
            const SizedBox(height: 20),
            // One full-width primary action: the theme's filled red (D-A69)
            // with its pressed, disabled and loading states.
            AppButton(
              label: l10n.offerAccept,
              icon: const Icon(Icons.check_circle_outline),
              expand: true,
              isLoading: accepting,
              // While accepting: a no-op callback, so AppButton shows its
              // spinner (not the disabled look) and ignores taps.
              onPressed: accepting ? () {} : onAccept,
            ),
          ],
        ),
      ),
    );
  }
}

/// A decorative icon (no semantics: the card's summary already names
/// every detail) at the logical start of a line that wraps beside it.
class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.color,
    required this.text,
    required this.style,
  });

  final IconData icon;
  final Color color;
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 22, color: color),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: style)),
    ],
  );
}
