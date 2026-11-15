// Home: «طلبات بانتظار القبول» heading, count and confirmed-result line.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/view/screens/home_screen/cubit/pending_offers_cubit.dart';
import 'package:mobile_frontend/view/widget/buttons/app_text_button.dart';

/// «طلبات بانتظار القبول», the count (only from a server list) and the
/// one-line explanation.
class PendingOffersHeader extends StatelessWidget {
  const PendingOffersHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = context.watch<PendingOffersCubit>().state;
    final loaded = state.status == PendingOffersStatus.loaded;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            loaded && state.offers.isNotEmpty
                ? l10n.offersSectionTitleWithCount(state.offers.length)
                : l10n.offersSectionTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColor.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.offersSectionSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColor.textSecondary,
          ),
        ),
        // A card needs a refresh (its outcome is unknown or it expired).
        if (loaded &&
            state.offers.isNotEmpty &&
            state.notices.values.any((n) => n.blocksActions))
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppTextButton(
              label: l10n.refresh,
              onPressed: () =>
                  unawaited(context.read<PendingOffersCubit>().load()),
            ),
          ),
        if (state.message case final message?) ...[
          const SizedBox(height: 8),
          Semantics(
            container: true,
            liveRegion: true,
            child: Text(
              switch (message) {
                PendingOffersMessage.accepted => l10n.offersAcceptedMessage,
                PendingOffersMessage.declined => l10n.offersDeclinedMessage,
              },
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColor.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
