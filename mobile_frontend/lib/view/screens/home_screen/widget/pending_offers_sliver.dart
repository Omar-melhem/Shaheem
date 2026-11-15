// Home: the lazily built pending-offer cards or their status line.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/view/screens/home_screen/cubit/pending_offers_cubit.dart';
import 'package:mobile_frontend/view/widget/buttons/app_text_button.dart';
import 'package:mobile_frontend/view/widget/order/app_order_offer_card.dart';

/// The offers: a lazily built list of cards, or a compact status line
/// (loading, not connected, no session, confirmed empty, failure).
class PendingOffersSliver extends StatelessWidget {
  const PendingOffersSliver({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<PendingOffersCubit>();
    final state = context.watch<PendingOffersCubit>().state;

    if (state.status == PendingOffersStatus.loaded && state.offers.isNotEmpty) {
      return SliverList.separated(
        itemCount: state.offers.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final offer = state.offers[index];
          final notice = state.notices[offer.id];
          final pending = state.pending;
          final busy = pending != null && pending.offerId == offer.id
              ? switch (pending.action) {
                  OfferAction.accept => AppOfferCardAction.accept,
                  OfferAction.decline => AppOfferCardAction.decline,
                }
              : null;
          // Another card's command, or a notice that needs a refresh,
          // keeps this card's actions off.
          final enabled = pending == null && !(notice?.blocksActions ?? false);
          return AppOrderOfferCard(
            key: ValueKey(offer.id),
            offer: offer,
            busyAction: busy,
            onAccept: enabled ? () => unawaited(cubit.accept(offer.id)) : null,
            onDecline: enabled
                ? () => unawaited(cubit.decline(offer.id))
                : null,
            notice: switch (notice) {
              OfferCardNotice.noLongerAvailable => l10n.offerNoLongerAvailable,
              OfferCardNotice.refused => l10n.offerRefused,
              OfferCardNotice.notConfigured => l10n.offerNotConfigured,
              OfferCardNotice.unconfirmed => l10n.offerUnconfirmed,
              null => null,
            },
          );
        },
      );
    }

    final (String text, bool canRefresh) = switch (state.status) {
      PendingOffersStatus.initial ||
      PendingOffersStatus.loading => (l10n.offersLoading, false),
      PendingOffersStatus.noSession => (l10n.offersNoSession, false),
      PendingOffersStatus.notConfigured => (l10n.offersNotConfigured, false),
      PendingOffersStatus.noInternet => (l10n.offersNoInternet, true),
      PendingOffersStatus.failure => (l10n.offersLoadFailed, true),
      PendingOffersStatus.loaded => (l10n.offersEmpty, true),
    };
    final hasStaleCards = state.notices.values.any((n) => n.blocksActions);
    return SliverToBoxAdapter(
      child: Semantics(
        container: true,
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColor.textPrimary),
            ),
            if (canRefresh || hasStaleCards)
              AppTextButton(
                label: l10n.refresh,
                onPressed: () => unawaited(cubit.load()),
              ),
          ],
        ),
      ),
    );
  }
}
