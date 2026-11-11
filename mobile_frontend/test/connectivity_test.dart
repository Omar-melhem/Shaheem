// Tests for the single app-wide connectivity monitor:
// - InternetConnectionCheckerPlusService, driven by the real package with a
//   custom check callback (no real network traffic);
// - AppConnectivityCubit, driven by a fake service.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:mobile_frontend/helper/network/internet_connection_service.dart';
import 'package:mobile_frontend/view/app_state/connectivity/app_connectivity_cubit.dart';

import 'fakes.dart';

/// A package instance whose probe calls [check] instead of the network.
InternetConnection fakeConnection(
  Future<bool> Function() check, {
  Duration interval = const Duration(milliseconds: 20),
}) => InternetConnection.createInstance(
  checkInterval: interval,
  customCheckOptions: [InternetCheckOption(uri: Uri.parse('https://test'))],
  useDefaultOptions: false,
  customConnectivityCheck: (option) async =>
      InternetCheckResult(option: option, isSuccess: await check()),
);

void main() {
  group('InternetConnectionCheckerPlusService', () {
    test('checkNow maps reachable / unreachable', () async {
      var online = true;
      final service = InternetConnectionCheckerPlusService(
        connection: fakeConnection(() async => online),
      );
      expect(await service.checkNow(), InternetReachability.connected);
      online = false;
      expect(await service.checkNow(), InternetReachability.disconnected);
      await service.dispose();
    });

    test('timeout → checkFailed, not disconnected', () async {
      final service = InternetConnectionCheckerPlusService(
        connection: fakeConnection(() => Completer<bool>().future),
        checkTimeout: const Duration(milliseconds: 10),
      );
      expect(await service.checkNow(), InternetReachability.checkFailed);
    });

    test('checker error is never reported as connected', () async {
      final service = InternetConnectionCheckerPlusService(
        connection: fakeConnection(() async => throw Exception('boom')),
      );
      // The package itself treats a throwing check as "no success", so the
      // result is either disconnected or checkFailed — never connected.
      expect(await service.checkNow(), isNot(InternetReachability.connected));
      await service.dispose();
    });

    test('overlapping checkNow calls share one probe', () async {
      var probes = 0;
      final gate = Completer<bool>();
      final service = InternetConnectionCheckerPlusService(
        connection: fakeConnection(() {
          probes++;
          return gate.future;
        }),
      );
      final a = service.checkNow();
      final b = service.checkNow();
      gate.complete(true);
      expect(await Future.wait([a, b]), [
        InternetReachability.connected,
        InternetReachability.connected,
      ]);
      expect(probes, 1);
      await service.dispose();
    });

    test('stream emits connected then disconnected on change', () async {
      var online = true;
      final service = InternetConnectionCheckerPlusService(
        connection: fakeConnection(() async => online),
      );
      final events = <InternetReachability>[];
      final sub = service.statusChanges.listen(events.add);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      online = false;
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await sub.cancel();
      expect(events.first, InternetReachability.connected);
      expect(events, contains(InternetReachability.disconnected));
      await service.dispose();
    });
  });

  group('AppConnectivityCubit', () {
    late FakeInternetConnectionService service;
    late AppConnectivityCubit cubit;

    setUp(() {
      service = FakeInternetConnectionService();
      cubit = AppConnectivityCubit(service);
    });

    tearDown(() => cubit.close());

    test('starts unknown, not checking', () {
      expect(cubit.state.status, InternetReachability.unknown);
      expect(cubit.state.isChecking, isFalse);
    });

    test('start → one subscription + initial check → connected', () async {
      cubit.start();
      await pumpEventQueue();
      expect(cubit.state.status, InternetReachability.connected);
      expect(service.streamRequests, 1);
      expect(service.checks, 1);
    });

    test('start twice does not subscribe or check twice', () async {
      cubit.start();
      cubit.start();
      await pumpEventQueue();
      expect(service.streamRequests, 1);
      expect(service.checks, 1);
    });

    test('initial check offline → disconnected', () async {
      service.result = InternetReachability.disconnected;
      cubit.start();
      await pumpEventQueue();
      expect(cubit.state.isDisconnected, isTrue);
    });

    test('check failure → checkFailed, not reported as disconnected', () async {
      service.result = InternetReachability.checkFailed;
      cubit.start();
      await pumpEventQueue();
      expect(cubit.state.status, InternetReachability.checkFailed);
      expect(cubit.state.isDisconnected, isFalse);
    });

    test('stream events update the state', () async {
      cubit.start();
      await pumpEventQueue();
      service.emit(InternetReachability.disconnected);
      await pumpEventQueue();
      expect(cubit.state.isDisconnected, isTrue);
      service.emit(InternetReachability.connected);
      await pumpEventQueue();
      expect(cubit.state.status, InternetReachability.connected);
    });

    test(
      'overlapping checks share one probe; isChecking while running',
      () async {
        service.pending = Completer<InternetReachability>();
        final a = cubit.check();
        final b = cubit.check();
        expect(cubit.state.isChecking, isTrue);
        service.pending!.complete(InternetReachability.disconnected);
        expect(await a, InternetReachability.disconnected);
        expect(await b, InternetReachability.disconnected);
        expect(service.checks, 1);
        expect(cubit.state.isChecking, isFalse);
      },
    );

    test('stale check result is ignored after a newer stream event', () async {
      cubit.start();
      await pumpEventQueue();
      service.pending = Completer<InternetReachability>();
      final pendingCheck = cubit.check();

      service.emit(InternetReachability.connected); // newer information
      await pumpEventQueue();
      service.pending!.complete(InternetReachability.disconnected); // stale

      expect(await pendingCheck, InternetReachability.connected);
      expect(cubit.state.status, InternetReachability.connected);
    });

    test(
      'pause cancels the subscription; resume resubscribes + checks',
      () async {
        cubit.start();
        await pumpEventQueue();
        expect(service.hasListener, isTrue);

        cubit.pauseMonitoring();
        expect(service.hasListener, isFalse);

        // Events while paused are not received.
        service.emit(InternetReachability.disconnected);
        await pumpEventQueue();
        expect(cubit.state.status, InternetReachability.connected);

        service.result = InternetReachability.disconnected;
        cubit.resumeMonitoring();
        await pumpEventQueue();
        expect(service.hasListener, isTrue);
        expect(service.streamRequests, 2);
        expect(service.checks, 2);
        expect(cubit.state.isDisconnected, isTrue);
      },
    );

    test('resume without pause does nothing', () async {
      cubit.start();
      await pumpEventQueue();
      cubit.resumeMonitoring();
      await pumpEventQueue();
      expect(service.streamRequests, 1);
      expect(service.checks, 1);
    });

    test('close cancels the subscription', () async {
      cubit.start();
      await pumpEventQueue();
      await cubit.close();
      expect(service.hasListener, isFalse);
    });
  });
}
