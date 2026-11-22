// Test doubles for app-level dependencies. Used in tests only; the
// production app always runs with the placeholder repository (no fake
// signed-in user) and the real connectivity service.

import 'dart:async';

import 'package:mobile_frontend/helper/legal/legal_page_launcher.dart';
import 'package:mobile_frontend/domain/entities/active_order.dart';
import 'package:mobile_frontend/domain/entities/app_user.dart';
import 'package:mobile_frontend/domain/repositories/active_order_repository.dart';
import 'package:mobile_frontend/domain/repositories/auth_repository.dart';
import 'package:mobile_frontend/domain/repositories/captain_location_repository.dart';
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

  /// When set, [signIn] compares the received password with this value and
  /// records only the outcome in [lastPasswordMatched]. The received
  /// password itself is never stored, so a failing test can't print it.
  String? expectedPassword;

  /// Whether the last [signIn] password equalled [expectedPassword]
  /// exactly (null when [expectedPassword] was not set).
  bool? lastPasswordMatched;

  /// Fake sign-in: records the username (never the password), then fails
  /// with [signInError] or "stores" a session.
  @override
  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    signInCalls++;
    lastUsername = username;
    lastPasswordMatched = expectedPassword == null
        ? null
        : password == expectedPassword;
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

/// A sample active order with a valid restaurant location. Test data only:
/// production code never contains an order or a coordinate.
const testPickup = GeoPoint(latitude: 31.9539, longitude: 35.9106);
const testActiveOrder = ActiveOrder(
  status: ActiveOrderStatus.accepted,

  orderId: 'order-42',
  restaurantName: 'مطعم الاختبار',
  pickupLocation: testPickup,
  pickupInstructions: 'الاستلام من الباب الخلفي',
);

/// Active-order source whose answer each test controls.
class FakeActiveOrderRepository implements ActiveOrderRepository {
  FakeActiveOrderRepository({this.order});

  /// What the server "reports"; null means no active order.
  ActiveOrder? order;

  /// When set, [getActiveOrder] throws this.
  Object? error;

  /// When set, [getActiveOrder] waits on this completer (lookup in flight).
  Completer<void>? pending;

  int calls = 0;

  @override
  Future<ActiveOrder?> getActiveOrder() async {
    calls++;
    if (pending != null) await pending!.future;
    if (error != null) throw error!;
    return order;
  }
}

/// Device-location source whose answer each test controls.
class FakeCaptainLocationRepository implements CaptainLocationRepository {
  FakeCaptainLocationRepository({this.location});

  /// The position returned when [error] is null.
  GeoPoint? location;

  /// When set, [getCurrentLocation] throws this (e.g. permission denied).
  Object? error;

  int calls = 0;

  @override
  Future<GeoPoint> getCurrentLocation() async {
    calls++;
    if (error != null) throw error!;
    return location!;
  }
}

/// Records in-app open requests; never opens anything. [supports],
/// [opens] and [error] script the platform's answer.
class FakeInAppWebPageLauncher implements InAppWebPageLauncher {
  FakeInAppWebPageLauncher({this.supports = true, this.opens = true});

  bool supports;
  bool opens;

  /// When set, [openInAppWebView] throws it.
  Object? error;

  int supportChecks = 0;

  /// Every URL passed to [openInAppWebView], in order.
  final List<Uri> opened = [];

  @override
  Future<bool> supportsInAppWebView() async {
    supportChecks++;
    return supports;
  }

  /// When set, [openInAppWebView] waits for it (an open still in flight).
  Completer<bool>? pending;

  @override
  Future<bool> openInAppWebView(Uri url) async {
    opened.add(url);
    if (error != null) throw error!;
    if (pending != null) return pending!.future;
    return opens;
  }
}
