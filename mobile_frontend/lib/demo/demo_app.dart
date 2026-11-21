// SHAHM DEMO (Task 37) — the demo composition: real MainApp, demo adapters.
// Removed by `bash tool/demo/remove_demo.sh --apply`.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_frontend/demo/demo_state.dart';
import 'package:mobile_frontend/demo/model/demo_fixtures.dart';
import 'package:mobile_frontend/demo/repo/demo_auth_repository.dart';
import 'package:mobile_frontend/demo/repo/demo_repositories.dart';
import 'package:mobile_frontend/demo/widget/demo_home_wallet.dart';
import 'package:mobile_frontend/demo/widget/demo_shell_bridge.dart';
import 'package:mobile_frontend/demo/widget/demo_strip.dart';
import 'package:mobile_frontend/helper/network/internet_connection_service.dart';
import 'package:mobile_frontend/helper/translation/generated/app_localizations.dart';
import 'package:mobile_frontend/main.dart';
import 'package:mobile_frontend/theme/app_color.dart';

/// The demo app: loads the fixtures, then runs the **real** [MainApp] with
/// the demo repositories, the demo strip above every screen, the shell
/// bridge and the Home wallet connector ([DemoHomeWallet]). Started only from `main` when the demo is enabled.
///
/// Not used: maps (the pickup map stays "unavailable"), location (the real
/// "not configured" placeholder) and every production repository. The
/// connectivity monitor is the real one unless [connectivityService] is
/// given (tests).
class DemoApp extends StatefulWidget {
  const DemoApp({
    super.key,
    required this.connectivityService,
    this.bundle,
    this.clock,
  });

  final InternetConnectionService connectivityService;

  /// Where the fixtures are read from (the app's asset bundle by default).
  final AssetBundle? bundle;

  /// The demo clock (tests pass a fixed one).
  final DateTime Function()? clock;

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  late final Future<DemoState> _ready = DemoFixtures.load(
    widget.bundle ?? rootBundle,
  ).then((fixtures) => DemoState(fixtures, clock: widget.clock));

  @override
  Widget build(BuildContext context) => FutureBuilder<DemoState>(
    future: _ready,
    builder: (context, snapshot) {
      final state = snapshot.data;
      if (snapshot.hasError) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: ColoredBox(
            color: AppColor.background,
            child: Center(
              child: Text(
                lookupAppLocalizations(const Locale('ar')).demoFixturesError,
                style: const TextStyle(color: AppColor.textPrimary),
              ),
            ),
          ),
        );
      }
      if (state == null) return const ColoredBox(color: AppColor.background);
      return MainApp(
        connectivityService: widget.connectivityService,
        authRepository: DemoAuthRepository(state),
        activeOrderRepository: DemoActiveOrderRepository(state),
        captainAvailabilityRepository: DemoAvailabilityRepository(state),
        availabilityPermissions: const DemoPermissionGateway(),
        orderOfferRepository: DemoOfferRepository(state),
        walletRepository: DemoWalletRepository(state),
        orderHistoryRepository: DemoOrderHistoryRepository(state),
        demoAppOverlay: (context, child) =>
            DemoStrip(state: state, child: child!),
        demoShellBuilder: (context, child) =>
            DemoShellBridge(state: state, child: child!),
        // Task 38: Home's wallet chip shows the same demo total as Wallet.
        demoHomeBuilder: (context, home) =>
            DemoHomeWallet(state: state, home: home),
      );
    },
  );
}
