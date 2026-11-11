// App entry point and composition root.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:mobile_frontend/data/repositories/auth_repository_placeholder.dart';
import 'package:mobile_frontend/domain/repositories/auth_repository.dart';
import 'package:mobile_frontend/domain/use_cases/check_auth_status.dart';
import 'package:mobile_frontend/domain/use_cases/get_current_user.dart';
import 'package:mobile_frontend/domain/use_cases/sign_in.dart';
import 'package:mobile_frontend/domain/use_cases/sign_out.dart';
import 'package:mobile_frontend/helper/network/internet_connection_service.dart';
import 'package:mobile_frontend/helper/translation/generated/app_localizations.dart';
import 'package:mobile_frontend/theme/app_theme.dart';
import 'package:mobile_frontend/util/responsive/app_breakpoints.dart';
import 'package:mobile_frontend/util/routes/go_router.dart';
import 'package:mobile_frontend/util/routes/stream_refresh_listenable.dart';
import 'package:mobile_frontend/view/app_state/connectivity/app_connectivity_cubit.dart';
import 'package:mobile_frontend/view/app_state/connectivity/global_connectivity_banner.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';
import 'package:mobile_frontend/view/screens/splash_screen/cubit/splash_cubit.dart';

void main() {
  // App-level services are created exactly once, here. Plain constructor
  // injection: no DI package until one is agreed. The placeholder
  // repository always reports "no session", so the app opens Login until
  // the real backend is connected.
  runApp(
    MainApp(
      connectivityService: InternetConnectionCheckerPlusService(),
      authRepository: const AuthRepositoryPlaceholder(),
    ),
  );
}

/// Root widget. Creates the app-scoped cubits once, provides them above the
/// router so every route shares the same instances, and owns the router.
///
/// Services are passed in so tests can supply fakes. They live for the whole
/// app run and are owned by the caller (`main`), so they are not disposed
/// here.
class MainApp extends StatefulWidget {
  const MainApp({
    super.key,
    required this.connectivityService,
    required this.authRepository,
  });

  final InternetConnectionService connectivityService;
  final AuthRepository authRepository;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  // App-wide state (one instance each for the app's lifetime).
  late final AppConnectivityCubit _connectivityCubit;
  late final AppSessionCubit _sessionCubit;

  // Startup orchestration; idle once startup resolves.
  late final SplashCubit _splashCubit;

  late final StreamRefreshListenable _routerRefresh;
  late final GoRouter _router;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _connectivityCubit = AppConnectivityCubit(widget.connectivityService);
    _sessionCubit = AppSessionCubit(SignOut(widget.authRepository));
    final getCurrentUser = GetCurrentUser(widget.authRepository);
    _splashCubit = SplashCubit(
      _connectivityCubit,
      CheckAuthStatus(widget.authRepository),
      getCurrentUser,
      _sessionCubit,
    );
    _routerRefresh = StreamRefreshListenable([
      _splashCubit.stream,
      _sessionCubit.stream,
    ]);
    _router = createAppRouter(
      splashCubit: _splashCubit,
      sessionCubit: _sessionCubit,
      refreshListenable: _routerRefresh,
      signIn: SignIn(widget.authRepository, getCurrentUser),
    );

    // Background: stop probing. Foreground: fresh subscription + one check.
    // Only connectivity reacts to lifecycle; the session is deliberately not
    // revalidated (and Splash not re-shown) on resume — that happens only
    // when an API call reports the session invalid.
    _lifecycleListener = AppLifecycleListener(
      onPause: _connectivityCubit.pauseMonitoring,
      onResume: _connectivityCubit.resumeMonitoring,
    );

    // Started here, not in a widget's build, so each runs exactly once per
    // launch. Splash's internet check joins the monitor's first check
    // instead of starting a second probe.
    _connectivityCubit.start();
    _splashCubit.start();
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _router.dispose();
    _routerRefresh.dispose();
    _splashCubit.close();
    _sessionCubit.close();
    _connectivityCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _connectivityCubit),
        BlocProvider.value(value: _sessionCubit),
        BlocProvider.value(value: _splashCubit),
      ],
      child: MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context).appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
        // Arabic-first localization (gen_l10n). Arabic is the only active
        // locale; the Arabic locale also makes the whole app RTL, so no
        // manual Directionality is needed. Add a locale by adding its ARB.
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        // Mounted once around every route:
        // - the single source of responsive breakpoints (AppBreakpoints);
        // - the global offline banner.
        builder: (context, child) => ResponsiveBreakpoints.builder(
          breakpoints: AppBreakpoints.all,
          child: GlobalConnectivityBanner(child: child!),
        ),
      ),
    );
  }
}
