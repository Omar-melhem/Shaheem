// Route table and router construction for the app.

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_frontend/domain/repositories/availability_permission_gateway.dart';
import 'package:mobile_frontend/domain/use_cases/captain_availability.dart';
import 'package:mobile_frontend/domain/use_cases/get_active_order.dart';
import 'package:mobile_frontend/domain/use_cases/order_offers.dart';
import 'package:mobile_frontend/domain/use_cases/get_captain_location.dart';
import 'package:mobile_frontend/domain/use_cases/sign_in.dart';
import 'package:mobile_frontend/util/routes/debug_shell_preview.dart';
import 'package:mobile_frontend/util/routes/route_guard.dart';
import 'package:mobile_frontend/util/routes/routes_string.dart';
import 'package:mobile_frontend/view/navigation/app_nav_bar.dart';
import 'package:mobile_frontend/view/screens/authentication/cubit/login_cubit.dart';
import 'package:mobile_frontend/view/screens/authentication/view/login_screen.dart';
import 'package:mobile_frontend/view/screens/home_screen/cubit/home_availability_cubit.dart';
import 'package:mobile_frontend/view/screens/home_screen/cubit/pending_offers_cubit.dart';
import 'package:mobile_frontend/view/screens/home_screen/view/home_screen.dart';
import 'package:mobile_frontend/view/screens/no_internet_screen/view/no_internet_screen.dart';
import 'package:mobile_frontend/view/screens/notifications_screen/view/notifications_screen.dart';
import 'package:mobile_frontend/view/screens/order_history_screen/view/order_history_screen.dart';
import 'package:mobile_frontend/view/screens/profile_screen/view/profile_screen.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/cubit/current_order_cubit.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/view/current_order_screen.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/widget/pickup_map.dart';
import 'package:mobile_frontend/view/screens/splash_screen/cubit/splash_cubit.dart';
import 'package:mobile_frontend/view/screens/splash_screen/view/splash_screen.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';

/// Builds the app's router.
///
/// It is created per app instance (not as a global) because its redirect
/// policy reads the live [splashCubit] and [sessionCubit]. [refreshListenable]
/// must fire whenever either cubit changes so redirects re-run; the caller
/// owns and disposes it. [signIn] is the use case the feature-scoped
/// `LoginCubit` is built with each time the Login route is shown.
///
/// [getActiveOrder] and [getCaptainLocation] build the shell-scoped
/// `CurrentOrderCubit`. [pickupMapBuilder] is the in-app map for an active
/// order's pickup; it is null until a maps provider is configured, and the
/// Current Order screen then shows a "map unavailable" state.
///
/// [getCaptainAvailability], [changeCaptainAvailability] and
/// [availabilityPermissions] build the Home-scoped `HomeAvailabilityCubit`;
/// [getEligibleOffers], [acceptOrderOffer] and [declineOrderOffer] build the
/// Home-scoped `PendingOffersCubit`.
///
/// [debugShellPreview] is the TEMPORARY debug-only preview switch; tests
/// pass their own to simulate a non-debug build. It is inert outside debug
/// builds (see [DebugShellPreview]).
GoRouter createAppRouter({
  required SplashCubit splashCubit,
  required AppSessionCubit sessionCubit,
  required Listenable refreshListenable,
  required SignIn signIn,
  required GetActiveOrder getActiveOrder,
  required GetCaptainLocation getCaptainLocation,
  required GetCaptainAvailability getCaptainAvailability,
  required ChangeCaptainAvailability changeCaptainAvailability,
  required AvailabilityPermissionGateway availabilityPermissions,
  required GetEligibleOffers getEligibleOffers,
  required AcceptOrderOffer acceptOrderOffer,
  required DeclineOrderOffer declineOrderOffer,
  PickupMapBuilder? pickupMapBuilder,
  DebugShellPreview? debugShellPreview,
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
      // Protected main shell: the redirect only allows it once the session
      // is authenticated and the user profile is loaded (or, in debug
      // builds only, during the temporary preview).
      //
      // One branch per destination, each with its own Navigator, so every
      // tab keeps its own stack and state. The branch order MUST match
      // `MainNavDestination.values` and `mainShellRoutes`: the bar selects
      // a branch by index.
      StatefulShellRoute.indexedStack(
        // CurrentOrderCubit is scoped to the shell: created once with it,
        // shared by the bar and the Current Order branch, and closed when
        // the shell leaves the tree (sign-out), which drops late answers.
        builder: (context, state, navigationShell) => BlocProvider(
          create: (_) => CurrentOrderCubit(getActiveOrder, getCaptainLocation),
          child: AppNavBar(navigationShell: navigationShell),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutesString.home,
                // Feature-scoped: created with Home, closed when the shell
                // leaves the tree (sign-out), which drops late answers. The
                // session check keeps the debug preview (no session) from
                // asking for permissions or claiming availability.
                builder: (context, state) => MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (_) => HomeAvailabilityCubit(
                        getCaptainAvailability,
                        changeCaptainAvailability,
                        availabilityPermissions,
                        () => sessionCubit.state is SessionAuthenticated,
                      ),
                    ),
                    // After a server-confirmed acceptance, Current Order is
                    // asked to refresh (no automatic navigation).
                    BlocProvider(
                      create: (context) {
                        final currentOrder = context.read<CurrentOrderCubit>();
                        return PendingOffersCubit(
                          getEligibleOffers,
                          acceptOrderOffer,
                          declineOrderOffer,
                          () => sessionCubit.state is SessionAuthenticated,
                          onAcceptConfirmed: currentOrder.load,
                        );
                      },
                    ),
                  ],
                  child: const HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutesString.notifications,
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutesString.currentOrder,
                builder: (context, state) =>
                    CurrentOrderScreen(pickupMapBuilder: pickupMapBuilder),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutesString.orderHistory,
                builder: (context, state) => const OrderHistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutesString.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
