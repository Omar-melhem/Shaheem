// «طلباتي»: the deliveries this captain completed (D-A81) and the offers
// this captain declined (Task 36).

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/util/responsive/app_breakpoints.dart';
import 'package:mobile_frontend/view/screens/order_history_screen/cubit/completed_deliveries_cubit.dart';
import 'package:mobile_frontend/view/screens/order_history_screen/cubit/declined_offers_cubit.dart';
import 'package:mobile_frontend/view/screens/order_history_screen/widget/completed_delivery_tile.dart';
import 'package:mobile_frontend/view/screens/order_history_screen/widget/declined_offer_tile.dart';
import 'package:mobile_frontend/view/widget/buttons/app_text_button.dart';

/// Root screen of the My Orders branch of the main shell, two sections:
///
/// 1. «الطلبات المكتملة» — what the server records as deliveries **this
///    captain** completed ([CompletedDeliveriesCubit]), page by page with
///    «عرض المزيد»;
/// 2. «العروض التي رفضتها» — the offers this captain declined
///    ([DeclinedOffersCubit]). A declined offer is never shown as a
///    delivery, and nothing is added to either list locally.
///
/// Each section shows its rows or one truthful status line (loading, not
/// configured, signed out, offline/failure with Retry, confirmed empty).
/// Both owners are shell-scoped. Both load when first built, each time the
/// tab becomes visible again, and on app resume **only while visible**;
/// never by polling. A confirmed decline or completion elsewhere refreshes
/// the matching owner (`DeclinedOffersCubit.refresh`,
/// `CompletedDeliveriesCubit.refresh`).
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
    final declined = context.read<DeclinedOffersCubit>();
    if (declined.state.status == DeclinedOffersStatus.initial) {
      unawaited(declined.load());
    }
    final completed = context.read<CompletedDeliveriesCubit>();
    if (completed.state.status == CompletedDeliveriesStatus.initial) {
      unawaited(completed.load());
    }
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (_wasActive ?? true) _loadBoth();
      },
    );
  }

  void _loadBoth() {
    unawaited(context.read<DeclinedOffersCubit>().load());
    unawaited(context.read<CompletedDeliveriesCubit>().load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = TickerMode.valuesOf(context).enabled;
    if (_wasActive == false && active) _loadBoth();
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
    final declined = context.watch<DeclinedOffersCubit>().state;
    final completed = context.watch<CompletedDeliveriesCubit>().state;
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
                padding: EdgeInsetsDirectional.fromSTEB(side, 12, end, 12),
                sliver: SliverToBoxAdapter(
                  child: _SectionHeader(
                    icon: Icons.check_circle_outline,
                    title: l10n.completedDeliveriesHeading,
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsetsDirectional.fromSTEB(side, 0, end, 8),
                sliver: _completedSliver(context, completed),
              ),
              if (completed.canLoadMore || completed.moreFailed)
                SliverPadding(
                  padding: EdgeInsetsDirectional.fromSTEB(side, 0, end, 8),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (completed.moreFailed)
                          Text(l10n.completedDeliveriesLoadFailed),
                        AppTextButton(
                          label: completed.moreFailed
                              ? l10n.retry
                              : l10n.completedDeliveriesLoadMore,
                          onPressed: completed.loadingMore
                              ? null
                              : () => unawaited(
                                  context
                                      .read<CompletedDeliveriesCubit>()
                                      .loadMore(),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsetsDirectional.fromSTEB(side, 20, end, 16),
                sliver: SliverList.list(
                  children: [
                    _SectionHeader(
                      icon: Icons.do_not_disturb_on_outlined,
                      title: l10n.declinedOffersHeading,
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.declinedOffersNote, style: secondary),
                  ],
                ),
              ),
              SliverPadding(
                padding: EdgeInsetsDirectional.fromSTEB(side, 0, end, 24),
                sliver: _declinedSliver(context, declined),
              ),
            ],
          );
        },
      ),
    );
  }

  /// The completed deliveries (lazily built), or one status line.
  Widget _completedSliver(
    BuildContext context,
    CompletedDeliveriesState state,
  ) {
    final l10n = context.l10n;
    final items = state.items;
    if (items.isNotEmpty &&
        (state.status == CompletedDeliveriesStatus.loaded ||
            state.status == CompletedDeliveriesStatus.loading)) {
      return SliverList.separated(
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => CompletedDeliveryTile(
          key: ValueKey(items[index].orderId),
          delivery: items[index],
        ),
      );
    }
    return _statusSliver(
      context,
      text: switch (state.status) {
        CompletedDeliveriesStatus.initial ||
        CompletedDeliveriesStatus.loading => l10n.completedDeliveriesLoading,
        CompletedDeliveriesStatus.noSession =>
          l10n.completedDeliveriesNoSession,
        CompletedDeliveriesStatus.notConfigured =>
          l10n.completedDeliveriesNotConfigured,
        CompletedDeliveriesStatus.noInternet =>
          l10n.completedDeliveriesNoInternet,
        CompletedDeliveriesStatus.failure => l10n.completedDeliveriesLoadFailed,
        CompletedDeliveriesStatus.loaded => l10n.completedDeliveriesEmpty,
      },
      onRetry: state.canRetry
          ? () => unawaited(context.read<CompletedDeliveriesCubit>().load())
          : null,
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
    return _statusSliver(
      context,
      text: switch (state.status) {
        DeclinedOffersStatus.initial ||
        DeclinedOffersStatus.loading => l10n.declinedOffersLoading,
        DeclinedOffersStatus.noSession => l10n.declinedOffersNoSession,
        DeclinedOffersStatus.notConfigured => l10n.declinedOffersNotConfigured,
        DeclinedOffersStatus.noInternet => l10n.declinedOffersNoInternet,
        DeclinedOffersStatus.failure => l10n.declinedOffersLoadFailed,
        DeclinedOffersStatus.loaded => l10n.declinedOffersEmpty,
      },
      onRetry: state.canRetry
          ? () => unawaited(context.read<DeclinedOffersCubit>().load())
          : null,
    );
  }

  /// One live status line with an optional Retry.
  Widget _statusSliver(
    BuildContext context, {
    required String text,
    VoidCallback? onRetry,
  }) => SliverToBoxAdapter(
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
          if (onRetry != null)
            AppTextButton(label: context.l10n.retry, onPressed: onRetry),
        ],
      ),
    ),
  );
}

/// A section heading (announced as a header).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.secondary),
        const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
