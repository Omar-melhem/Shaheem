// Home: the one place that starts Home's loads and re-reads them on resume.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/view/screens/home_screen/cubit/home_availability_cubit.dart';
import 'package:mobile_frontend/view/screens/home_screen/cubit/pending_offers_cubit.dart';

/// Owns Home's only Flutter lifecycle resource: one [AppLifecycleListener].
///
/// - On mount (once per Home element, not per rebuild): availability and
///   offers are loaded.
/// - On each app resume **while Home is visible**: both are read again
///   (the captain may have changed permissions; offers may have expired).
///   A resume while Home is hidden behind another tab or a full page loads
///   nothing (Task 29); the re-activation below then reads once. Never
///   prompts, never polls.
/// - On re-activation (Task 28): the main shell keeps Home mounted while
///   another tab is shown, so returning to it runs neither `initState` nor
///   a resume. GoRouter's indexed stack disables [TickerMode] for hidden
///   branches; when it turns back on, both are read again once. Rebuilds
///   and re-selecting the visible Home tab do not change it, so they load
///   nothing.
/// - On unmount (sign-out closes the shell): the listener is disposed, so
///   no callback runs afterwards.
///
/// A load requested while one is running is ignored by the Cubits, so
/// overlapping triggers send one request.
///
/// It is a `StatefulWidget` only because the listener must be created and
/// disposed with this element; it holds no business state (that stays in
/// the Cubits, which already drop late answers).
class HomeLifecycleBridge extends StatefulWidget {
  const HomeLifecycleBridge({super.key, required this.child});

  /// The Home content.
  final Widget child;

  @override
  State<HomeLifecycleBridge> createState() => _HomeLifecycleBridgeState();
}

class _HomeLifecycleBridgeState extends State<HomeLifecycleBridge> {
  late final AppLifecycleListener _lifecycle;

  /// Whether Home's branch was active (visible) at the last dependency
  /// change; null before the first one (the mount load already covers it).
  bool? _wasActive;

  @override
  void initState() {
    super.initState();
    _loadBoth();
    _lifecycle = AppLifecycleListener(onResume: _loadIfVisible);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Depends on the enclosing TickerMode, so this runs again when the
    // shell shows or hides Home's branch.
    final active = TickerMode.valuesOf(context).enabled;
    if (_wasActive == false && active) _loadBoth();
    _wasActive = active;
  }

  /// App resume: reads again only while Home is visible. The cached flag
  /// is current here: it is updated on every visibility change, and a
  /// resume does not change visibility.
  void _loadIfVisible() {
    if (_wasActive ?? true) _loadBoth();
  }

  /// Asks both Cubits to read the server again.
  void _loadBoth() {
    unawaited(context.read<HomeAvailabilityCubit>().load());
    unawaited(context.read<PendingOffersCubit>().load());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
