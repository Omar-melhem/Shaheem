// Route table and router construction for the app.

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_frontend/domain/use_cases/sign_in.dart';
import 'package:mobile_frontend/util/routes/route_guard.dart';
import 'package:mobile_frontend/util/routes/routes_string.dart';
import 'package:mobile_frontend/view/navigation/app_nav_bar.dart';
import 'package:mobile_frontend/view/screens/authentication/cubit/login_cubit.dart';
import 'package:mobile_frontend/view/screens/authentication/view/login_screen.dart';
import 'package:mobile_frontend/view/screens/home_screen/view/home_screen.dart';
import 'package:mobile_frontend/view/screens/no_internet_screen/view/no_internet_screen.dart';
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
GoRouter createAppRouter({
  required SplashCubit splashCubit,
  required AppSessionCubit sessionCubit,
  required Listenable refreshListenable,
  required SignIn signIn,
}) {
  return GoRouter(
    initialLocation: RoutesString.splash,
    refreshListenable: refreshListenable,
    redirect: (context, state) => resolveRedirect(
      location: state.matchedLocation,
      startup: splashCubit.state,
      session: sessionCubit.state,
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
          child: const LoginScreen(),
        ),
      ),
      // Protected: the redirect only allows this shell once the session is
      // authenticated and the user profile is loaded.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppNavBar(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutesString.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
