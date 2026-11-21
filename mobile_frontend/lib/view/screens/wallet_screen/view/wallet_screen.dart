// Wallet destination (D-A74–D-A76): the single balance, the two lifetime
// metric cards and the last-7-days commission-debit history.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/util/responsive/app_breakpoints.dart';
import 'package:mobile_frontend/view/screens/wallet_screen/cubit/wallet_cubit.dart';
import 'package:mobile_frontend/view/screens/wallet_screen/widget/wallet_balance_card.dart';
import 'package:mobile_frontend/view/screens/wallet_screen/widget/wallet_debit_card.dart';
import 'package:mobile_frontend/view/screens/wallet_screen/widget/wallet_metric_cards.dart';
import 'package:mobile_frontend/view/widget/buttons/app_text_button.dart';

/// Root screen of the Wallet branch (tab «المحفظة», D-A70).
///
/// Read-only. Shows, top to bottom:
/// 1. the server's single balance ([WalletBalanceCard]) — no held or
///    available amounts (D-A74);
/// 2. exactly two lifetime metric cards, delivered orders and earnings
///    ([WalletMetricCards]), with their own loading/unavailable states;
/// 3. «سجل الخصم»: the commission debits of the last 7 days, newest first.
///
/// There is no recharge action, contact popup or credit list (D-A76):
/// recharges are arranged outside the app and credited by Admin; credits
/// stay in the server's immutable ledger.
///
/// [WalletCubit] (provided by the route) owns the data. Loads once when
/// created and again each time the tab becomes visible after another tab
/// (GoRouter's indexed stack turns `TickerMode` off for hidden branches),
/// never by polling.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  /// Whether the branch was visible at the last dependency change.
  bool? _wasActive;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<WalletCubit>();
    if (cubit.state.status == WalletStatus.initial) unawaited(cubit.load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = TickerMode.valuesOf(context).enabled;
    if (_wasActive == false && active) {
      unawaited(context.read<WalletCubit>().load());
    }
    _wasActive = active;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = context.watch<WalletCubit>().state;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        // Text only: no decorative title icon and no actions.
        title: Text(l10n.walletTitle),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final side = AppBreakpoints.screenPadding(context);
          final maxWidth = AppBreakpoints.formMaxWidth(context);
          final end = math.max(side, constraints.maxWidth - side - maxWidth);
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsetsDirectional.fromSTEB(side, 16, end, 0),
                sliver: SliverList.list(
                  children: [
                    WalletBalanceCard(summary: state.overview?.summary),
                    const SizedBox(height: 16),
                    const WalletMetricCards(),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              l10n.walletDebitHistory,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.walletHistoryWindowNote,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColor.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              SliverPadding(
                padding: EdgeInsetsDirectional.fromSTEB(side, 0, end, 24),
                sliver: _debitsSliver(context, state),
              ),
            ],
          );
        },
      ),
    );
  }

  /// The commission debits (lazily built), or one status line that tells a
  /// confirmed empty history apart from "not configured" or a failure.
  Widget _debitsSliver(BuildContext context, WalletState state) {
    final l10n = context.l10n;
    final overview = state.overview;
    if (state.status == WalletStatus.loaded && overview != null) {
      final debits = overview.debits;
      if (debits.isNotEmpty) {
        return SliverList.separated(
          itemCount: debits.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) => WalletDebitCard(
            key: ValueKey('debit-${debits[index].id}'),
            debit: debits[index],
          ),
        );
      }
    }
    final text = switch (state.status) {
      WalletStatus.initial || WalletStatus.loading => l10n.walletLoading,
      WalletStatus.noSession => l10n.walletNoSession,
      WalletStatus.notConfigured => l10n.walletNotConfigured,
      WalletStatus.noInternet => l10n.walletNoInternet,
      WalletStatus.failure => l10n.walletLoadFailed,
      WalletStatus.loaded => l10n.walletDebitsEmpty,
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
                onPressed: () => unawaited(context.read<WalletCubit>().load()),
              ),
          ],
        ),
      ),
    );
  }
}
