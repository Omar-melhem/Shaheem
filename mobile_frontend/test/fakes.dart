// Test doubles for app-level dependencies. Used in tests only; the
// production app always runs with the placeholder repository (no fake
// signed-in user) and the real connectivity service.

import 'dart:async';

import 'package:mobile_frontend/domain/entities/app_user.dart';
import 'package:mobile_frontend/domain/repositories/auth_repository.dart';
import 'package:mobile_frontend/helper/network/internet_connection_service.dart';

/// Connectivity service whose probe result and stream each test controls.
class FakeInternetConnectionService implements InternetConnectionService {
  FakeInternetConnectionService({this.result = InternetReachability.connected});

  /// What the next [checkNow] returns.
  InternetReachability result;

  /// When set, [checkNow] waits on this completer, keeping a probe in flight.
  Completer<InternetReachability>? pending;

  /// Number of probes actually started.
  int checks = 0;

  /// Number of times the stream getter was read (one per subscription).
  int streamRequests = 0;

  bool disposed = false;

  final StreamController<InternetReachability> _controller =
      StreamController<InternetReachability>.broadcast();

  /// Whether anything is currently subscribed to [statusChanges].
  bool get hasListener => _controller.hasListener;

  /// Simulates the monitor reporting a change.
  void emit(InternetReachability status) => _controller.add(status);

  @override
  Stream<InternetReachability> get statusChanges {
    streamRequests++;
    return _controller.stream;
  }

  @override
  Future<InternetReachability> checkNow() {
    checks++;
    return pending?.future ?? Future.value(result);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _controller.close();
  }
}

/// A sample user that a fake backend might return.
const testUser = AppUser(id: 'user-1', displayName: 'Test User');

/// Auth repository whose stored session and backend answers each test
/// controls.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.hasSession = false, this.user = testUser});

  bool hasSession;
  AppUser user;

  /// When set, [validateSession] throws this.
  Object? validateError;

  /// When set, [getCurrentUser] throws this instead of returning [user].
  Object? userError;

  /// When set, [validateSession] waits on this completer.
  Completer<void>? validatePending;

  /// When set, [getCurrentUser] waits on this completer.
  Completer<AppUser>? userPending;

  int validateCalls = 0;
  int userCalls = 0;
  int clearCalls = 0;

  @override
  Future<bool> hasStoredSession() async => hasSession;

  @override
  Future<void> validateSession() async {
    validateCalls++;
    if (validatePending != null) return validatePending!.future;
    if (validateError != null) throw validateError!;
  }

  @override
  Future<AppUser> getCurrentUser() async {
    userCalls++;
    if (userPending != null) return userPending!.future;
    if (userError != null) throw userError!;
    return user;
  }

  /// When set, [signIn] throws this (e.g. InvalidCredentialsException).
  Object? signInError;

  /// When set, [signIn] waits on this completer.
  Completer<void>? signInPending;

  int signInCalls = 0;
  String? lastUsername;

  /// Fake sign-in: records the username (never the password), then fails
  /// with [signInError] or "stores" a session.
  @override
  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    signInCalls++;
    lastUsername = username;
    if (signInPending != null) await signInPending!.future;
    if (signInError != null) throw signInError!;
    hasSession = true;
  }

  @override
  Future<void> clearSession() async {
    clearCalls++;
    hasSession = false;
  }
}
