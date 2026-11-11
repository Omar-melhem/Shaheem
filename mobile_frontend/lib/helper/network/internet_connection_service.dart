// The app's single internet-reachability monitor.

import 'dart:async';

import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Normalized internet reachability, independent of any package types.
enum InternetReachability {
  /// No result yet (only used by state holders before the first check).
  unknown,

  /// A real request to a public endpoint succeeded.
  connected,

  /// Every probe failed: no usable internet. This is a confirmed result.
  disconnected,

  /// The check itself failed or timed out, so reachability is not known.
  /// Must not be shown as "offline".
  checkFailed,
}

/// Monitors actual internet reachability (not just whether Wi-Fi or mobile
/// data is switched on).
///
/// Exactly one instance exists per app run. It is created at the composition
/// root (`main.dart`) and used only by `AppConnectivityCubit`; screens never
/// create or call it directly. It says nothing about whether the SHAHM
/// backend is healthy.
abstract class InternetConnectionService {
  /// Reachability changes. Probing runs only while this stream has a
  /// listener, so cancelling the subscription stops background probes.
  Stream<InternetReachability> get statusChanges;

  /// One bounded probe right now. Never returns [InternetReachability.unknown].
  /// Concurrent calls share the same probe instead of starting new ones.
  Future<InternetReachability> checkNow();

  /// Releases resources. Call once, when the app is shutting down.
  Future<void> dispose();
}

/// [InternetConnectionService] backed by `internet_connection_checker_plus`.
///
/// The package sends lightweight requests to several public endpoints.
/// While [statusChanges] is listened to, it probes every [checkInterval]
/// (10 s by default, deliberately not high-frequency) and emits only when
/// the status changes.
class InternetConnectionCheckerPlusService
    implements InternetConnectionService {
  /// [connection] is injectable for tests. When omitted, the service creates
  /// and owns its own instance (rather than the package singleton), so
  /// [dispose] can safely close it.
  InternetConnectionCheckerPlusService({
    InternetConnection? connection,
    Duration checkInterval = const Duration(seconds: 10),
    this.checkTimeout = const Duration(seconds: 10),
  }) : _connection =
           connection ??
           InternetConnection.createInstance(checkInterval: checkInterval);

  final InternetConnection _connection;

  /// Upper bound for one [checkNow] probe. Hitting it yields
  /// [InternetReachability.checkFailed], not "disconnected".
  final Duration checkTimeout;

  /// The probe currently running, shared by overlapping [checkNow] calls.
  Future<InternetReachability>? _inFlight;

  @override
  Stream<InternetReachability> get statusChanges =>
      _connection.onStatusChange.map(
        (status) => status == InternetStatus.connected
            ? InternetReachability.connected
            : InternetReachability.disconnected,
      );

  @override
  Future<InternetReachability> checkNow() =>
      _inFlight ??= _probe().whenComplete(() => _inFlight = null);

  Future<InternetReachability> _probe() async {
    try {
      final reachable = await _connection.hasInternetAccess.timeout(
        checkTimeout,
      );
      return reachable
          ? InternetReachability.connected
          : InternetReachability.disconnected;
    } on TimeoutException {
      return InternetReachability.checkFailed;
    } catch (_) {
      // A checker error is not evidence of being offline.
      return InternetReachability.checkFailed;
    }
  }

  @override
  Future<void> dispose() => _connection.dispose();
}
