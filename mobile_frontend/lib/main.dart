// App entry point and composition root.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:mobile_frontend/data/repositories/active_order_repository_placeholder.dart';
import 'package:mobile_frontend/data/repositories/auth_repository_placeholder.dart';
import 'package:mobile_frontend/data/repositories/availability_permission_gateway_placeholder.dart';
import 'package:mobile_frontend/data/repositories/captain_account_repository_placeholder.dart';
import 'package:mobile_frontend/data/repositories/captain_availability_repository_placeholder.dart';
import 'package:mobile_frontend/data/repositories/captain_location_repository_placeholder.dart';
import 'package:mobile_frontend/data/repositories/order_offer_repository_placeholder.dart';
import 'package:mobile_frontend/data/repositories/order_history_repository_placeholder.dart';
import 'package:mobile_frontend/data/repositories/wallet_repository_placeholder.dart';
import 'package:mobile_frontend/domain/repositories/active_order_repository.dart';
import 'package:mobile_frontend/domain/repositories/auth_repository.dart';
import 'package:mobile_frontend/domain/repositories/availability_permission_gateway.dart';
import 'package:mobile_frontend/domain/repositories/captain_account_repository.dart';
import 'package:mobile_frontend/domain/repositories/captain_availability_repository.dart';
import 'package:mobile_frontend/domain/repositories/captain_location_repository.dart';
import 'package:mobile_frontend/domain/repositories/order_offer_repository.dart';
import 'package:mobile_frontend/domain/repositories/order_history_repository.dart';
import 'package:mobile_frontend/domain/repositories/wallet_repository.dart';
import 'package:mobile_frontend/domain/use_cases/captain_account.dart';
import 'package:mobile_frontend/domain/use_cases/captain_availability.dart';
import 'package:mobile_frontend/domain/use_cases/check_auth_status.dart';
import 'package:mobile_frontend/domain/use_cases/get_active_order.dart';
import 'package:mobile_frontend/domain/use_cases/get_captain_location.dart';
import 'package:mobile_frontend/domain/use_cases/get_current_user.dart';
import 'package:mobile_frontend/domain/use_cases/get_declined_offers.dart';
import 'package:mobile_frontend/domain/use_cases/get_wallet.dart';
import 'package:mobile_frontend/domain/use_cases/order_offers.dart';
import 'package:mobile_frontend/domain/use_cases/sign_in.dart';
import 'package:mobile_frontend/domain/use_cases/sign_out.dart';
import 'package:mobile_frontend/helper/network/internet_connection_service.dart';
import 'package:mobile_frontend/helper/translation/generated/app_localizations.dart';
import 'package:mobile_frontend/theme/app_theme.dart';
import 'package:mobile_frontend/util/responsive/app_breakpoints.dart';
import 'package:mobile_frontend/util/routes/debug_shell_preview.dart';
import 'package:mobile_frontend/util/routes/go_router.dart';
import 'package:mobile_frontend/util/routes/routes_string.dart';
import 'package:mobile_frontend/util/routes/stream_refresh_listenable.dart';
import 'package:mobile_frontend/view/app_state/connectivity/app_connectivity_cubit.dart';
import 'package:mobile_frontend/view/app_state/connectivity/global_connectivity_banner.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/cubit/current_order_cubit.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/widget/pickup_map.dart';
import 'package:mobile_frontend/view/screens/splash_screen/cubit/splash_cubit.dart';
// SHAHM_DEMO_START main-import
import 'package:mobile_frontend/demo/demo_app.dart';
import 'package:mobile_frontend/demo/demo_mode.dart';
// SHAHM_DEMO_END main-import

void main() {
  // SHAHM_DEMO_START main-entry
  // Debug-only demonstration (Task 37): a debug build started with
  // `--dart-define=SHAHM_DEMO=true`. Inert otherwise. Remove with
  // `bash tool/demo/remove_demo.sh --apply`.
  if (shahmDemoEnabled) {
    runApp(
      DemoApp(connectivityService: InternetConnectionCheckerPlusService()),
    );
    return;
  }
  // SHAHM_DEMO_END main-entry
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
    this.activeOrderRepository = const ActiveOrderRepositoryPlaceholder(),
    this.captainLocationRepository =
        const CaptainLocationRepositoryPlaceholder(),
    this.captainAvailabilityRepository =
        const CaptainAvailabilityRepositoryPlaceholder(),
    this.availabilityPermissions =
        const AvailabilityPermissionGatewayPlaceholder(),
    this.orderOfferRepository = const OrderOfferRepositoryPlaceholder(),
    this.walletRepository = const WalletRepositoryPlaceholder(),
    this.orderHistoryRepository = const OrderHistoryRepositoryPlaceholder(),
    this.captainAccountRepository = const CaptainAccountRepositoryPlaceholder(),
    // SHAHM_DEMO_START main-params
    this.demoAppOverlay,
    this.demoShellBuilder,
    this.demoHomeBuilder,
    // SHAHM_DEMO_END main-params
    this.pickupMapBuilder,
    this.debugShellPreview,
  });

  final InternetConnectionService connectivityService;
  final AuthRepository authRepository;

  /// Source of the captain's active order. Defaults to the placeholder,
  /// which reports "backend not configured" (no orders backend exists yet),
  /// so production startup/resume recovery finds no real order yet.
  final ActiveOrderRepository activeOrderRepository;

  /// Source of the device location. Defaults to the placeholder, which
  /// reports "not configured" and requests no permission.
  final CaptainLocationRepository captainLocationRepository;

  /// The captain's availability on the backend. Defaults to the
  /// placeholder, which reports "backend not configured": nobody can be
  /// made Available until the real API exists.
  final CaptainAvailabilityRepository captainAvailabilityRepository;

  /// Location and notification checks/requests for availability. Defaults
  /// to the placeholder, which reports "not configured" and shows no
  /// prompt (no native permission configuration exists yet).
  final AvailabilityPermissionGateway availabilityPermissions;

  /// The captain's actionable order offers. Defaults to the placeholder,
  /// which reports "backend not configured": no offer is ever shown or
  /// answered until the real API exists.
  final OrderOfferRepository orderOfferRepository;

  /// The captain's wallet (balance, commission debits and lifetime delivery
  /// statistics, read-only). Defaults to the placeholder, which reports
  /// "backend not configured": no balance, history or statistic is ever
  /// shown until the real API exists.
  final WalletRepository walletRepository;

  /// The captain's history: today only the offers this captain declined
  /// (read-only, Task 36). Defaults to the placeholder, which reports
  /// "backend not configured": no record is ever shown or invented.
  final OrderHistoryRepository orderHistoryRepository;

  /// The captain's rating and the account-deletion request (D-A77,
  /// D-A78). Defaults to the placeholder, which reports "backend not
  /// configured": no rating is shown and no deletion is ever sent or
  /// claimed until the real API exists.
  final CaptainAccountRepository captainAccountRepository;
  // SHAHM_DEMO_START main-fields
  /// Debug demo only (Task 37): wraps every screen (the demo strip).
  final TransitionBuilder? demoAppOverlay;

  /// Debug demo only (Task 37): wraps the main shell's content.
  final TransitionBuilder? demoShellBuilder;

  /// Debug demo only (Task 38): builds Home with its wallet total.
  final Widget Function(BuildContext context, Widget Function(int? total) home)?
  demoHomeBuilder;
  // SHAHM_DEMO_END main-fields

  /// In-app map for an active order's pickup. Null until a maps provider is
  /// approved and configured; the screen then says the map is unavailable.
  final PickupMapBuilder? pickupMapBuilder;

  // TODO(debug-preview): remove with DebugShellPreview.
  /// TEMPORARY debug-only preview switch. Left null in the app (the router
  /// creates the default one); tests pass `DebugShellPreview(allowed: false)`
  /// to simulate a non-debug build.
  final DebugShellPreview? debugShellPreview;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  // App-wide state (one instance each for the app's lifetime).
  late final AppConnectivityCubit _connectivityCubit;
  late final AppSessionCubit _sessionCubit;

  // Startup orchestration; idle once startup resolves.
  late final SplashCubit _splashCubit;

  // The authoritative active order (D-A73): one owner for the startup
  // redirect, the standalone Current Order page, the offer flow and
  // recovery. Reset on sign-out so no captain's order outlives a session.
  late final CurrentOrderCubit _currentOrderCubit;
  late final StreamSubscription<AppSessionState> _sessionSubscription;

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
    _currentOrderCubit = CurrentOrderCubit(
      GetActiveOrder(widget.activeOrderRepository),
      GetCaptainLocation(widget.captainLocationRepository),
    );
    // Startup / sign-in: resolve the active order before the post-sign-in
    // destination is chosen (the redirect waits for it). Sign-out: drop
    // the previous captain's order and any lookup still running.
    _sessionSubscription = _sessionCubit.stream.listen(_onSessionChanged);
    _routerRefresh = StreamRefreshListenable([
      _splashCubit.stream,
      _sessionCubit.stream,
      _currentOrderCubit.stream,
    ]);
    _router = createAppRouter(
      splashCubit: _splashCubit,
      sessionCubit: _sessionCubit,
      refreshListenable: _routerRefresh,
      signIn: SignIn(widget.authRepository, getCurrentUser),
      currentOrderCubit: _currentOrderCubit,
      getCaptainAvailability: GetCaptainAvailability(
        widget.captainAvailabilityRepository,
      ),
      changeCaptainAvailability: ChangeCaptainAvailability(
        widget.captainAvailabilityRepository,
      ),
      availabilityPermissions: widget.availabilityPermissions,
      getEligibleOffers: GetEligibleOffers(widget.orderOfferRepository),
      acceptOrderOffer: AcceptOrderOffer(widget.orderOfferRepository),
      declineOrderOffer: DeclineOrderOffer(widget.orderOfferRepository),
      getWallet: GetWallet(widget.walletRepository),
      getDeliveryStatistics: GetDeliveryStatistics(widget.walletRepository),
      getDeclinedOffers: GetDeclinedOffers(widget.orderHistoryRepository),
      getCaptainRating: GetCaptainRating(widget.captainAccountRepository),
      requestAccountDeletion: RequestAccountDeletion(
        widget.captainAccountRepository,
      ),
      pickupMapBuilder: widget.pickupMapBuilder,
      // SHAHM_DEMO_START main-router
      demoShellBuilder: widget.demoShellBuilder,
      demoHomeBuilder: widget.demoHomeBuilder,
      // SHAHM_DEMO_END main-router
      debugShellPreview: widget.debugShellPreview,
    );

    // Background: stop probing. Foreground: fresh subscription + one check.
    // Only connectivity reacts to lifecycle; the session is deliberately not
    // revalidated (and Splash not re-shown) on resume — that happens only
    // when an API call reports the session invalid.
    _lifecycleListener = AppLifecycleListener(
      onPause: _connectivityCubit.pauseMonitoring,
      onResume: () {
        _connectivityCubit.resumeMonitoring();
        unawaited(_recoverActiveOrder());
      },
    );

    // Started here, not in a widget's build, so each runs exactly once per
    // launch. Splash's internet check joins the monitor's first check
    // instead of starting a second probe.
    _connectivityCubit.start();
    _splashCubit.start();
  }

  /// Session transitions drive the active-order lifecycle: a new
  /// authenticated session resolves it once (startup and sign-in); leaving
  /// it (sign-out, rejected session) resets it. The debug preview never
  /// authenticates, so it never triggers a lookup.
  void _onSessionChanged(AppSessionState session) {
    switch (session) {
      case SessionAuthenticated():
        unawaited(_currentOrderCubit.refreshed());
      case SessionUnauthenticated():
        _currentOrderCubit.reset();
      case SessionUnknown():
        break;
    }
  }

  /// Foreground return (D-A73): with a valid session, re-read the active
  /// order once (concurrent triggers are coalesced by the Cubit) and bring
  /// the captain to Current Order when the server reports an unfinished
  /// order and it is not already open. An open offer sheet is closed by
  /// `NewOfferSheetHost` as soon as an active order is reported (closing is
  /// never a decline). A failed or "not configured" answer navigates
  /// nowhere and is never treated as "no order".
  Future<void> _recoverActiveOrder() async {
    if (_sessionCubit.state is! SessionAuthenticated) return;
    final result = await _currentOrderCubit.refreshed();
    if (!mounted ||
        result is! CurrentOrderActive ||
        _sessionCubit.state is! SessionAuthenticated) {
      return;
    }
    // The top route: after a push the URI stays on the page below, so the
    // visible page is read from the router's top state.
    final location = _router.state.matchedLocation;
    // Startup routing is the redirect's job; only signed-in pages here.
    if (location == RoutesString.currentOrder ||
        location == RoutesString.splash ||
        location == RoutesString.login ||
        location == RoutesString.noInternet) {
      return;
    }
    unawaited(_router.push(RoutesString.currentOrder));
  }

  @override
  void dispose() {
    _sessionSubscription.cancel();
    _lifecycleListener.dispose();
    _router.dispose();
    _routerRefresh.dispose();
    _splashCubit.close();
    _currentOrderCubit.close();
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
        BlocProvider.value(value: _currentOrderCubit),
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
          // SHAHM_DEMO_START main-overlay
          child:
              widget.demoAppOverlay?.call(
                context,
                GlobalConnectivityBanner(child: child!),
              ) ??
              GlobalConnectivityBanner(child: child!),
          // SHAHM_DEMO_END main-overlay
        ),
      ),
    );
  }
}
