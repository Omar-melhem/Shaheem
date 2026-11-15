// TEMPORARY development aid: debug-only access to the main navigation shell.

import 'package:flutter/foundation.dart';

// TODO(debug-preview): delete this file, the `debugPreviewActive` rule in
// `route_guard.dart`, the wiring in `go_router.dart` / `main.dart` and the
// Login preview button once a real backend sign-in exists.

/// Remembers that the developer asked, from the Login preview button, to
/// look at the main navigation shell without signing in.
///
/// It is NOT a session: it holds no user, token, role or permission and it
/// never touches `AppSessionCubit`, which stays unauthenticated. The route
/// guard only uses it to let the five main-shell routes open.
///
/// Strictly debug-only: every getter is ANDed with [kDebugMode], a
/// compile-time constant that is `false` in profile and release builds. So
/// there [isAvailable] and [isActive] are always false, [enter] does nothing
/// and the guard keeps requiring real authentication.
class DebugShellPreview {
  /// [allowed] exists so tests can simulate a non-debug build (`false`). It
  /// can only narrow access: it can never enable the preview outside debug.
  DebugShellPreview({this.allowed = true});

  /// False simulates a non-debug build; true changes nothing outside debug.
  final bool allowed;
  bool _active = false;

  /// Whether the preview button may be shown at all.
  bool get isAvailable => kDebugMode && allowed;

  /// Whether the main shell is currently open for preview.
  bool get isActive => isAvailable && _active;

  /// Opens the main shell for preview. No-op outside debug builds.
  void enter() {
    if (isAvailable) _active = true;
  }

  /// Closes the preview; the guard protects the shell again.
  void exit() => _active = false;
}
