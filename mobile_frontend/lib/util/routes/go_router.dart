// Route table and router construction for the app.

import 'package:flutter/foundation.dart';
// SHAHM_DEMO_START router-import
import 'package:flutter/widgets.dart'
    show BuildContext, Builder, TransitionBuilder, Widget;
// SHAHM_DEMO_END router-import
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_frontend/domain/repositories/availability_permission_gateway.dart';
import 'package:mobile_frontend/domain/use_cases/captain_account.dart';
import 'package:mobile_frontend/domain/use_cases/captain_availability.dart';
import 'package:mobile_frontend/domain/use_cases/order_offers.dart';
import 'package:mobile_frontend/domain/use_cases/get_declined_offers.dart';
import 'package:mobile_frontend/domain/use_cases/get_wallet.dart';
import 'package:mobile_frontend/domain/use_cases/sign_in.dart';
import 'package:mobile_frontend/util/routes/debug_shell_preview.dart';
import 'package:mobile_frontend/util/routes/route_guard.dart';
import 'package:mobile_frontend/util/routes/routes_string.dart';
import 'package:mobile_frontend/view/navigation/app_nav_bar.dart';
import 'package:mobile_frontend/view/navigation/new_offer_sheet_host.dart';
import 'package:mobile_frontend/view/screens/authentication/cubit/login_cubit.dart';
import 'package:mobile_frontend/view/screens/authentication/view/login_screen.dart';
import 'package:mobile_frontend/view/screens/home_screen/cubit/home_availability_cubit.dart';
import 'package:mobile_frontend/view/screens/home_screen/cubit/pending_offers_cubit.dart';
import 'package:mobile_frontend/view/screens/home_screen/view/home_screen.dart';
import 'package:mobile_frontend/view/screens/no_internet_screen/view/no_internet_screen.dart';
import 'package:mobile_frontend/view/screens/order_history_screen/cubit/declined_offers_cubit.dart';
import 'package:mobile_frontend/view/screens/order_history_screen/view/order_history_screen.dart';
import 'package:mobile_frontend/view/screens/about_screen/view/about_screen.dart';
import 'package:mobile_frontend/view/screens/profile_screen/cubit/profile_rating_cubit.dart';
import 'package:mobile_frontend/view/screens/profile_screen/view/profile_screen.dart';
import 'package:mobile_frontend/view/screens/settings_screen/cubit/account_deletion_cubit.dart';
import 'package:mobile_frontend/view/screens/settings_screen/view/settings_screen.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/cubit/current_order_cubit.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/view/current_order_screen.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/widget/pickup_map.dart';
import 'package:mobile_frontend/view/screens/splash_screen/cubit/splash_cubit.dart';
import 'package:mobile_frontend/view/screens/splash_screen/view/splash_screen.dart';
import 'package:mobile_frontend/view/screens/wallet_screen/cubit/wallet_cubit.dart';
import 'package:mobile_frontend/view/screens/wallet_screen/view/wallet_screen.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';

/// Builds the app's router.
///
/// It is created per app instance (not as a global) because its redirect
/// policy reads the live [splashCubit] and [sessionCubit]. [refreshListenable]
/// must fire whenever either cubit changes so redirects re-run; the caller
/// owns and disposes it. [signIn] is the use case the feature-scoped
/// `LoginCubit` is built with each time the Login route is shown.
///
/// [currentOrderCubit] is the app-level owner of the authoritative active
/// order (D-A73): the redirect reads it to choose the post-sign-in
/// destination, and the standalone Current Order page, the offer flow and
/// recovery share it. [refreshListenable] must also fire on its changes.
/// [pickupMapBuilder] is the in-app map for an active order's pickup; it is
/// null until a maps provider is configured, and the Current Order screen
/// then shows a "map unavailable" state.
///
/// [getCaptainAvailability], [changeCaptainAvailability] and
/// [availabilityPermissions] build the Home-scoped `HomeAvailabilityCubit`;
/// [getEligibleOffers], [acceptOrderOffer] and [declineOrderOffer] build the
/// shell-scoped `PendingOffersCubit` (shared by Home and the new-offer
/// sheet, Task 36). [getWallet] and [getDeliveryStatistics] build the
/// Wallet-scoped `WalletCubit` (balance and lifetime statistics, D-A76);
/// [getDeclinedOffers] the shell-scoped `DeclinedOffersCubit` (read by
/// My Orders, refreshed after a confirmed decline, Task 38).
/// [getCaptainRating] builds the Profile-scoped `ProfileRatingCubit`;
/// [requestAccountDeletion] the Settings-scoped `AccountDeletionCubit`,
/// whose confirmed completion (and "sign in again") end the session
/// through [sessionCubit] (D-A77, D-A78).
///
/// [debugShellPreview] is the TEMPORARY debug-only preview switch; tests
/// pass their own to simulate a non-debug build. It is inert outside debug
/// builds (see [DebugShellPreview]).
GoRouter createAppRouter({
  required SplashCubit splashCubit,
  required AppSessionCubit sessionCubit,
  required Listenable refreshListenable,
  required SignIn signIn,
  required CurrentOrderCubit currentOrderCubit,
  required GetCaptainAvailability getCaptainAvailability,
  required ChangeCaptainAvailability changeCaptainAvailability,
  required AvailabilityPermissionGateway availabilityPermissions,
  required GetEligibleOffers getEligibleOffers,
  required AcceptOrderOffer acceptOrderOffer,
  required DeclineOrderOffer declineOrderOffer,
  required GetWallet getWallet,
  required GetDeliveryStatistics getDeliveryStatistics,
  required GetDeclinedOffers getDeclinedOffers,
  required GetCaptainRating getCaptainRating,
  required RequestAccountDeletion requestAccountDeletion,
  PickupMapBuilder? pickupMapBuilder,
  DebugShellPreview? debugShellPreview,
  // SHAHM_DEMO_START router-param
  // Debug demo only (Task 37): wraps the shell's content.
  TransitionBuilder? demoShellBuilder,
  // Debug demo only (Task 38): builds Home with its wallet total.
  Widget Function(BuildContext context, Widget Function(int? total) home)?
  demoHomeBuilder,
  // SHAHM_DEMO_END router-param
}) {
  // TODO(debug-preview): remove with DebugShellPreview.
  final preview = debugShellPreview ?? DebugShellPreview();

  return GoRouter(
    initialLocation: RoutesString.splash,
    refreshListenable: refreshListenable,
    redirect: (context, state) => resolveRedirect(
      location: state.matchedLocation,
      startup: splashCubit.state,
      session: sessionCubit.state,
      activeOrder: currentOrderCubit.state,
      debugPreviewActive: preview.isActive,
    ),
    routes: [
      GoRoute(
        path: RoutesString.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutesString.noInternet,
        builder: (context, state) => const NoInternetScreen(),
      ),
      GoRoute(
        path: RoutesString.login,
        // LoginCubit is feature-scoped: created with the route and closed
        // when it leaves the tree.
        builder: (context, state) => BlocProvider(
          create: (_) => LoginCubit(signIn, sessionCubit),
          child: LoginScreen(
            // TODO(debug-preview): remove this argument. Null outside debug
            // builds, which hides the button. The session is not touched:
            // the guard lets the shell open only because the preview is on.
            onDebugPreview: preview.isAvailable
                ? () {
                    preview.enter();
                    context.go(RoutesString.home);
                  }
                : null,
          ),
        ),
      ),
      // Current Order (D-A73): a protected page above the shell, not a tab.
      // It is pushed onto the shell after a confirmed acceptance or a
      // foreground recovery (Back returns to the tab below), or is the
      // first page after startup for an unfinished order (Back goes Home).
      // Its state is the app-level CurrentOrderCubit, so it survives tab
      // changes and is shared with the offer flow and recovery.
      GoRoute(
        path: RoutesString.currentOrder,
        builder: (context, state) =>
            CurrentOrderScreen(pickupMapBuilder: pickupMapBuilder),
      ),
      // Settings and About (D-A77, D-A78): protected pages pushed above the
      // shell from «حسابي»; Back returns there. The deletion Cubit lives
      // with the Settings page only.
      GoRoute(
        path: RoutesString.settings,
        builder: (context, state) => BlocProvider(
          create: (_) => AccountDeletionCubit(
            requestAccountDeletion,
            onCompleted: sessionCubit.endSession,
            onReauthenticate: sessionCubit.endSession,
          ),
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: RoutesString.about,
        builder: (context, state) => const AboutScreen(),
      ),
      // Protected main shell: the redirect only allows it once the session
      // is authenticated and the user profile is loaded (or, in debug
      // builds only, during the temporary preview).
      //
      // One branch per destination, each with its own Navigator, so every
      // tab keeps its own stack and state. The branch order MUST match
      // `MainNavDestination.values` and `mainShellRoutes`: the bar selects
      // a branch by index (D-A70: Home, My Orders, Wallet, My Account).
      StatefulShellRoute.indexedStack(
        // PendingOffersCubit is shell-scoped (Task 36): Home's list and
        // the new-offer sheet (NewOfferSheetHost, above every tab and page)
        // share one owner of offers and commands. The host also turns a
        // confirmed instant acceptance into Current Order (D-A73). The
        // session check keeps the debug preview (no session) inert.
        //
        // DeclinedOffersCubit is shell-scoped since Task 38: My Orders reads
        // it, and a server-confirmed decline from Home or the sheet
        // refreshes it, so the new record shows even while that tab stays
        // open. It reads nothing before My Orders first opens.
        builder: (context, state, navigationShell) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => DeclinedOffersCubit(
                getDeclinedOffers,
                () => sessionCubit.state is SessionAuthenticated,
              ),
            ),
            BlocProvider(
              create: (context) => PendingOffersCubit(
                getEligibleOffers,
                acceptOrderOffer,
                declineOrderOffer,
                () => sessionCubit.state is SessionAuthenticated,
                onDeclineConfirmed: context.read<DeclinedOffersCubit>().refresh,
              ),
            ),
          ],
          child: NewOfferSheetHost(
            hasSession: () => sessionCubit.state is SessionAuthenticated,
            // SHAHM_DEMO_START router-shell
            child: demoShellBuilder == null
                ? AppNavBar(navigationShell: navigationShell)
                : Builder(
                    builder: (context) => demoShellBuilder(
                      context,
                      AppNavBar(navigationShell: navigationShell),
                    ),
                  ),
            // SHAHM_DEMO_END router-shell
          ),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutesString.home,
                // Feature-scoped: created with Home, closed when the shell
                // leaves the tree (sign-out), which drops late answers. The
                // session check keeps the debug preview (no session) from
                // asking for permissions or claiming availability. Home's
                // offers come from the shell's PendingOffersCubit.
                builder: (context, state) => BlocProvider(
                  create: (_) => HomeAvailabilityCubit(
                    getCaptainAvailability,
                    changeCaptainAvailability,
                    availabilityPermissions,
                    () => sessionCubit.state is SessionAuthenticated,
                  ),
                  // SHAHM_DEMO_START router-home
                  child: demoHomeBuilder == null
                      ? const HomeScreen()
                      : demoHomeBuilder(
                          context,
                          (total) => HomeScreen(walletBalanceFils: total),
                        ),
                  // SHAHM_DEMO_END router-home
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutesString.orderHistory,
                // «طلباتي» (D-A70). Read-only (Task 36): the offers this
                // captain declined, as the server records them, from the
                // shell's DeclinedOffersCubit.
                builder: (context, state) => const OrderHistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutesString.wallet,
                // Feature-scoped: created with the Wallet branch, closed
                // when the shell leaves the tree (sign-out), which drops
                // late answers. Read-only (D-A50).
                builder: (context, state) => BlocProvider(
                  create: (_) => WalletCubit(
                    getWallet,
                    getDeliveryStatistics,
                    () => sessionCubit.state is SessionAuthenticated,
                  ),
                  child: const WalletScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutesString.profile,
                // «حسابي» (D-A70, D-A77): a root tab, so it has no back
                // button. Name and phone come from AppSessionCubit; the
                // rating Cubit is created with the branch and closed on
                // sign-out.
                builder: (context, state) => BlocProvider(
                  create: (_) => ProfileRatingCubit(
                    getCaptainRating,
                    () => sessionCubit.state is SessionAuthenticated,
                  ),
                  child: const ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
