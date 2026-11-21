// Order History destination: the offers this captain declined (Task 36);
// completed-delivery history is a later task.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/util/responsive/app_breakpoints.dart';
import 'package:mobile_frontend/view/screens/order_history_screen/cubit/declined_offers_cubit.dart';
import 'package:mobile_frontend/view/screens/order_history_screen/widget/declined_offer_tile.dart';
import 'package:mobile_frontend/view/widget/buttons/app_text_button.dart';

/// Root screen of the Order History branch of the main shell.
///
/// Shows a short note that completed-delivery history is not built yet,
/// then «العروض التي رفضتها»: what the server records as offers **this
/// captain** declined ([DeclinedOffersCubit], provided by the main shell),
/// newest first, or one truthful status line (loading, not configured,
/// signed out, offline/failure with Retry, confirmed empty). A decline
/// never adds a row locally, and a declined offer is never shown as a
/// delivery or a cancelled order.
///
/// Loads when first built, each time the tab becomes visible again, and on
/// app resume **only while visible**; never by polling. A server-confirmed
/// decline elsewhere in the shell (e.g. the new-offer sheet opened over
/// this tab) re-reads through the same Cubit (`DeclinedOffersCubit.refresh`,
/// Task 38), so the new record appears without leaving the tab.
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late final AppLifecycleListener _lifecycle;

  /// Whether the branch was visible at the last dependency change.
  bool? _wasActive;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<DeclinedOffersCubit>();
    if (cubit.state.status == DeclinedOffersStatus.initial) {
      unawaited(cubit.load());
    }
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (_wasActive ?? true) {
          unawaited(context.read<DeclinedOffersCubit>().load());
        }
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = TickerMode.valuesOf(context).enabled;
    if (_wasActive == false && active) {
      unawaited(context.read<DeclinedOffersCubit>().load());
    }
    _wasActive = active;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = context.watch<DeclinedOffersCubit>().state;
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: AppColor.textSecondary,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.orderHistoryTitle)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final side = AppBreakpoints.screenPadding(context);
          final maxWidth = AppBreakpoints.formMaxWidth(context);
          final end = math.max(side, constraints.maxWidth - side - maxWidth);
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsetsDirectional.fromSTEB(side, 12, end, 16),
                sliver: SliverList.list(
                  children: [
                    Text(l10n.orderHistoryPlaceholderMessage, style: secondary),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(
                          Icons.do_not_disturb_on_outlined,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              l10n.declinedOffersHeading,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.declinedOffersNote, style: secondary),
                  ],
                ),
              ),
              SliverPadding(
                padding: EdgeInsetsDirectional.fromSTEB(side, 0, end, 24),
                sliver: _declinedSliver(context, state),
              ),
            ],
          );
        },
      ),
    );
  }

  /// The declined offers (lazily built), or one status line.
  Widget _declinedSliver(BuildContext context, DeclinedOffersState state) {
    final l10n = context.l10n;
    final records = state.records;
    if (records.isNotEmpty &&
        (state.status == DeclinedOffersStatus.loaded ||
            state.status == DeclinedOffersStatus.loading)) {
      return SliverList.separated(
        itemCount: records.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => DeclinedOfferTile(
          key: ValueKey(records[index].offerId),
          record: records[index],
        ),
      );
    }
    final text = switch (state.status) {
      DeclinedOffersStatus.initial ||
      DeclinedOffersStatus.loading => l10n.declinedOffersLoading,
      DeclinedOffersStatus.noSession => l10n.declinedOffersNoSession,
      DeclinedOffersStatus.notConfigured => l10n.declinedOffersNotConfigured,
      DeclinedOffersStatus.noInternet => l10n.declinedOffersNoInternet,
      DeclinedOffersStatus.failure => l10n.declinedOffersLoadFailed,
      DeclinedOffersStatus.loaded => l10n.declinedOffersEmpty,
    };
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
            if (state.canRetry)
              AppTextButton(
                label: l10n.retry,
                onPressed: () =>
                    unawaited(context.read<DeclinedOffersCubit>().load()),
              ),
          ],
        ),
      ),
    );
  }
}
