// Cubit tests for the startup sequence (SplashCubit) and the shared session
// holder (AppSessionCubit): transitions, retry rules, reuse of the shared
// connectivity monitor, and protection against stale or overlapping work.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_frontend/domain/entities/app_user.dart';
import 'package:mobile_frontend/domain/errors/auth_exceptions.dart';
import 'package:mobile_frontend/domain/use_cases/check_auth_status.dart';
import 'package:mobile_frontend/domain/use_cases/get_current_user.dart';
import 'package:mobile_frontend/domain/use_cases/sign_out.dart';
import 'package:mobile_frontend/helper/network/internet_connection_service.dart';
import 'package:mobile_frontend/view/app_state/connectivity/app_connectivity_cubit.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';
import 'package:mobile_frontend/view/screens/splash_screen/cubit/splash_cubit.dart';

import 'fakes.dart';

void main() {
  late FakeInternetConnectionService internet;
  late FakeAuthRepository repo;
  late AppConnectivityCubit connectivity;
  late AppSessionCubit session;
  late SplashCubit splash;

  setUp(() {
    internet = FakeInternetConnectionService();
    repo = FakeAuthRepository(hasSession: true);
    connectivity = AppConnectivityCubit(internet);
    session = AppSessionCubit(SignOut(repo));
    splash = SplashCubit(
      connectivity,
      CheckAuthStatus(repo),
      GetCurrentUser(repo),
      session,
    );
  });

  tearDown(() async {
    await splash.close();
    await session.close();
    await connectivity.close();
  });

  test('session starts unknown, never assumed authenticated', () {
    expect(session.state, isA<SessionUnknown>());
  });

  test('offline → SplashOffline; auth never runs', () async {
    internet.result = InternetReachability.disconnected;
    await splash.start();
    expect(splash.state, isA<SplashOffline>());
    expect(repo.validateCalls, 0);
  });

  test('checker failure → recoverable check state, not offline', () async {
    internet.result = InternetReachability.checkFailed;
    await splash.start();
    expect(splash.state, isA<SplashConnectivityCheckFailed>());
    expect(repo.validateCalls, 0);
  });

  test('startup reuses the shared monitor\'s in-flight check', () async {
    connectivity.start(); // the app-level initial check
    await splash.start();
    expect(internet.checks, 1); // no second probe
  });

  test('valid session → user fetched, then published, then resolved', () async {
    await splash.start();
    expect(repo.validateCalls, 1);
    expect(repo.userCalls, 1);
    expect(splash.state, isA<SplashResolved>());
    expect((session.state as SessionAuthenticated).user.id, testUser.id);
  });

  test('no session → unauthenticated, profile never fetched', () async {
    repo.hasSession = false;
    await splash.start();
    expect(session.state, isA<SessionUnauthenticated>());
    expect(repo.userCalls, 0);
  });

  test('session rejected during profile fetch → unauthenticated', () async {
    repo.userError = const SessionInvalidException();
    await splash.start();
    expect(session.state, isA<SessionUnauthenticated>());
    expect(repo.clearCalls, 1);
  });

  test('backend unreachable → service unavailable, not offline', () async {
    repo.validateError = const ServiceUnavailableException();
    await splash.start();
    expect(splash.state, isA<SplashServiceUnavailable>());
    expect(session.state, isA<SessionUnknown>());
  });

  test('profile failure → recoverable, user not signed out', () async {
    repo.userError = const ProfileUnavailableException();
    await splash.start();
    expect(splash.state, isA<SplashProfileFailure>());
    expect(session.state, isA<SessionUnknown>());
    expect(repo.clearCalls, 0);
  });

  test('malformed profile → recoverable, no user', () async {
    repo.userError = const InvalidProfileException();
    await splash.start();
    expect(splash.state, isA<SplashProfileFailure>());
    expect(session.state, isA<SessionUnknown>());
  });

  test('blocked account → blocked, no authenticated state', () async {
    repo.userError = const AccountBlockedException();
    await splash.start();
    expect(splash.state, isA<SplashBlocked>());
    expect(session.state, isA<SessionUnknown>());
  });

  test(
    'connection restored while offline → startup resumes by itself',
    () async {
      internet.result = InternetReachability.disconnected;
      connectivity.start();
      await splash.start();
      expect(splash.state, isA<SplashOffline>());

      internet.result = InternetReachability.connected;
      internet.emit(InternetReachability.connected);
      await pumpEventQueue();
      expect(session.state, isA<SessionAuthenticated>());
    },
  );

  test('retry after profile failure can succeed', () async {
    repo.userError = const ProfileUnavailableException();
    await splash.start();
    repo.userError = null;
    await splash.retry();
    expect(session.state, isA<SessionAuthenticated>());
  });

  test('start runs only once', () async {
    await splash.start();
    await splash.start();
    expect(repo.validateCalls, 1);
  });

  test('multiple fast retries → one active request', () async {
    internet.result = InternetReachability.disconnected;
    await splash.start();
    internet.pending = Completer<InternetReachability>();
    final runs = [splash.retry(), splash.retry(), splash.retry()];
    internet.pending!.complete(InternetReachability.disconnected);
    await Future.wait(runs);
    expect(internet.checks, 2); // start + exactly one retry
  });

  test('retry is ignored once startup resolved', () async {
    await splash.start();
    await splash.retry();
    expect(repo.validateCalls, 1);
  });

  test('old response after sign-out does not restore the session', () async {
    repo.userPending = Completer<AppUser>();
    final run = splash.start();
    await pumpEventQueue(); // reach the profile request

    await session.endSession();
    repo.userPending!.complete(testUser); // the stale response arrives
    await run;

    expect(session.state, isA<SessionUnauthenticated>());
  });

  test('endSession clears the user and stored credentials', () async {
    await splash.start();
    await session.endSession();
    expect(session.state, isA<SessionUnauthenticated>());
    expect(repo.clearCalls, 1);
  });

  test('outdated token cannot authenticate', () {
    final oldToken = session.beginAttempt();
    session.beginAttempt();
    session.authenticate(testUser, oldToken);
    expect(session.state, isA<SessionUnknown>());
  });
}
