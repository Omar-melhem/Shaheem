// SHAHM DEMO (Task 37) — debug-only demonstration mode switch.
// Removed by `bash tool/demo/remove_demo.sh --apply`.

import 'package:flutter/foundation.dart';

/// Whether `--dart-define=SHAHM_DEMO=true` was passed at build time.
const bool shahmDemoRequested = bool.fromEnvironment('SHAHM_DEMO');

/// The double guard: the demo runs only when it was requested **and** this
/// is a debug build. In profile and release builds it is always false, even
/// with the define.
bool resolveShahmDemo({required bool requested, required bool debugBuild}) =>
    requested && debugBuild;

/// The value the composition root (`main`) uses.
final bool shahmDemoEnabled = resolveShahmDemo(
  requested: shahmDemoRequested,
  debugBuild: kDebugMode,
);
