// Home: page composition only (content-sized app bar and one scrollable body).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobile_frontend/util/responsive/app_breakpoints.dart';
import 'package:mobile_frontend/view/screens/home_screen/widget/home_active_order_card.dart';
import 'package:mobile_frontend/view/screens/home_screen/widget/home_app_bar.dart';
import 'package:mobile_frontend/view/screens/home_screen/widget/home_availability_rationale_listener.dart';
import 'package:mobile_frontend/view/screens/home_screen/widget/home_lifecycle_bridge.dart';
import 'package:mobile_frontend/view/screens/home_screen/widget/pending_offers_header.dart';
import 'package:mobile_frontend/view/screens/home_screen/widget/pending_offers_sliver.dart';

/// The Home destination (client revision D-A71; offers since Task 26;
/// section widgets since Task 27).
///
/// - **App bar** ([HomeAppBar]): greeting, wallet balance chip and the
///   controlled availability switch with its notices. No Profile button,
///   logo or patterned header.
/// - **Body:** the active-order line when there is one or its check failed
///   ([HomeActiveOrderCard]), then [PendingOffersHeader] and the lazily
///   built [PendingOffersSliver] of real offer cards, in one
///   [CustomScrollView].
///
/// This widget only composes. Each section subscribes to its own state
/// (session name, `HomeAvailabilityCubit`, `PendingOffersCubit`,
/// `CurrentOrderCubit`); [HomeLifecycleBridge] starts the loads and
/// re-reads them on resume; [HomeAvailabilityRationaleListener] shows the
/// permission explanation.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.walletBalanceFils});

  /// Total wallet balance in integer fils from the single authoritative
  /// wallet source. Null (the default, as no wallet backend exists yet)
  /// shows «—» and an "unavailable" label, never a zero amount.
  final int? walletBalanceFils;

  @override
  Widget build(BuildContext context) {
    return HomeLifecycleBridge(
      child: HomeAvailabilityRationaleListener(
        child: Scaffold(
          body: LayoutBuilder(
            // The bar's cap comes from the height this page really has (a
            // debug strip, large text or a short screen reduce it), not
            // from the screen size.
            builder: (context, page) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HomeAppBar(
                  walletBalanceFils: walletBalanceFils,
                  availableHeight: page.maxHeight,
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Start-aligned content capped at the shared form
                      // width: screen padding at the start, the rest at the
                      // end.
                      final side = AppBreakpoints.screenPadding(context);
                      final maxWidth = AppBreakpoints.formMaxWidth(context);
                      final end = math.max(
                        side,
                        constraints.maxWidth - side - maxWidth,
                      );
                      return CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                              side,
                              16,
                              end,
                              0,
                            ),
                            sliver: SliverList.list(
                              children: const [
                                HomeActiveOrderCard(),
                                PendingOffersHeader(),
                                SizedBox(height: 12),
                              ],
                            ),
                          ),
                          SliverPadding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                              side,
                              0,
                              end,
                              24,
                            ),
                            sliver: const PendingOffersSliver(),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
