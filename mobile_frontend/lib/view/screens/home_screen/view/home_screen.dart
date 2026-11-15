// Home: page composition only (app bar and one scrollable body).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobile_frontend/util/responsive/app_breakpoints.dart';
import 'package:mobile_frontend/view/screens/home_screen/widget/home_app_bar.dart';
import 'package:mobile_frontend/view/screens/home_screen/widget/home_availability_card.dart';
import 'package:mobile_frontend/view/screens/home_screen/widget/home_availability_rationale_listener.dart';
import 'package:mobile_frontend/view/screens/home_screen/widget/home_greeting.dart';
import 'package:mobile_frontend/view/screens/home_screen/widget/home_lifecycle_bridge.dart';
import 'package:mobile_frontend/view/screens/home_screen/widget/pending_offers_header.dart';
import 'package:mobile_frontend/view/screens/home_screen/widget/pending_offers_sliver.dart';

/// The Home destination (Task 15 Option A, implemented in Task 24; offers
/// in Task 26; split into section widgets in Task 27).
///
/// - **App bar** ([HomeAppBar]): the «الرئيسية» title when it fits and the
///   read-only total wallet balance. No Profile button: Profile is still
///   the fifth bottom tab, so one here would only duplicate it until D-A66.
/// - **Body:** [HomeGreeting], [HomeAvailabilityCard], [PendingOffersHeader]
///   and the lazily built [PendingOffersSliver], in one [CustomScrollView].
///
/// This widget only composes. Each section subscribes to its own state
/// (session name, `HomeAvailabilityCubit` or `PendingOffersCubit`, both
/// provided by the Home route); [HomeLifecycleBridge] starts the loads and
/// re-reads them on resume; [HomeAvailabilityRationaleListener] shows the
/// permission explanation.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.walletTotalFils});

  /// Total wallet balance in integer fils from an authenticated backend
  /// source. Null (the default, as no wallet backend exists yet) shows «—»
  /// and an "unavailable" label, never a zero amount.
  final int? walletTotalFils;

  @override
  Widget build(BuildContext context) {
    return HomeLifecycleBridge(
      child: HomeAvailabilityRationaleListener(
        child: Scaffold(
          appBar: HomeAppBar(
            walletTotalFils: walletTotalFils,
            height: HomeAppBar.heightFor(context),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              // Start-aligned content capped at the shared form width:
              // screen padding at the start, the rest at the end.
              final side = AppBreakpoints.screenPadding(context);
              final maxWidth = AppBreakpoints.formMaxWidth(context);
              final end = math.max(
                side,
                constraints.maxWidth - side - maxWidth,
              );
              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsetsDirectional.fromSTEB(side, 16, end, 0),
                    sliver: SliverList.list(
                      children: [
                        const HomeGreeting(),
                        const SizedBox(height: 16),
                        const HomeAvailabilityCard(),
                        const SizedBox(height: 24),
                        const PendingOffersHeader(),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsetsDirectional.fromSTEB(side, 0, end, 24),
                    sliver: const PendingOffersSliver(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
