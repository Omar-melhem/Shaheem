// SHAHM DEMO (Task 38) — feeds Home's wallet chip from the demo wallet.
// Removed by `bash tool/demo/remove_demo.sh --apply`.

import 'package:flutter/widgets.dart';
import 'package:mobile_frontend/demo/demo_state.dart';

/// Gives the real Home its `walletBalanceFils` input from the **same**
/// [DemoState.wallet] that the demo wallet repository returns to the Wallet
/// tab, so the Home chip and the Wallet balance always agree.
///
/// Only the authoritative `WalletSummary.balanceFils` is passed (never a
/// sum of ledger rows), in integer fils; Home formats it with the shared
/// JOD formatter. Nothing is read
/// from a repository here, so there is no second wallet read or store.
///
/// With nobody signed in the input is null («—»). The value is read
/// synchronously on every [DemoState] change, and sign-in and reset rebuild
/// the wallet from the fixtures before notifying, so a previous session's
/// amount can never be shown.
class DemoHomeWallet extends StatelessWidget {
  const DemoHomeWallet({super.key, required this.state, required this.home});

  final DemoState state;

  /// Builds the real Home with the given balance (null when unknown).
  final Widget Function(int? walletBalanceFils) home;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) =>
        home(state.session == null ? null : state.wallet.summary.balanceFils),
  );
}
