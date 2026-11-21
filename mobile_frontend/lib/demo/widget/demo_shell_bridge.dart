// SHAHM DEMO (Task 37) — lets demo changes reach the real shell Cubits.
// Removed by `bash tool/demo/remove_demo.sh --apply`.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/demo/demo_state.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/cubit/current_order_cubit.dart';
import 'package:mobile_frontend/view/screens/home_screen/cubit/pending_offers_cubit.dart';
import 'package:mobile_frontend/view/screens/order_history_screen/cubit/declined_offers_cubit.dart';

/// Mounted inside the main shell (under its providers) only in the demo.
///
/// When [DemoState] changes (a demo offer arrived, a scenario, a reset, an
/// accepted offer), it asks the shell's real Cubits to read again, as a
/// push event would in production. The real `NewOfferSheetHost` then
/// presents a new offer with the real sheet. Each `load()` is ignored while
/// its Cubit is busy, so a command in flight is never disturbed.
///
/// The declined-offers history (Task 38) is re-read only after a **reset**
/// ([DemoState.resetCount] changed), through `DeclinedOffersCubit.refresh`,
/// so the visible Order History tab shows the restored fixture history. A
/// demo decline needs nothing here: the app's own confirmed-decline path
/// (`PendingOffersCubit.onDeclineConfirmed`) refreshes it once the demo
/// repository has answered, and other demo changes never touch it.
class DemoShellBridge extends StatefulWidget {
  const DemoShellBridge({super.key, required this.state, required this.child});

  final DemoState state;
  final Widget child;

  @override
  State<DemoShellBridge> createState() => _DemoShellBridgeState();
}

class _DemoShellBridgeState extends State<DemoShellBridge> {
  /// The reset generation the history was last read for.
  late int _seenResets;

  @override
  void initState() {
    super.initState();
    _seenResets = widget.state.resetCount;
    widget.state.addListener(_onDemoChange);
  }

  @override
  void dispose() {
    widget.state.removeListener(_onDemoChange);
    super.dispose();
  }

  void _onDemoChange() {
    if (!mounted || widget.state.session == null) return;
    unawaited(context.read<PendingOffersCubit>().load());
    unawaited(context.read<CurrentOrderCubit>().load());
    final resets = widget.state.resetCount;
    if (resets != _seenResets) {
      _seenResets = resets;
      unawaited(context.read<DeclinedOffersCubit>().refresh());
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
