// iOS-style loading indicator used by `AppTools.showLoading`.

import 'package:flutter/cupertino.dart';
import 'package:mobile_frontend/theme/app_color.dart';

/// iOS "HUD" look: a 100×100 dark rounded box with a Cupertino activity
/// indicator, centered on screen.
///
/// `AppTools.showLoading` shows it on iOS and macOS with a transparent
/// barrier. It uses only Cupertino widgets, so it renders on any platform.
class IosLoading extends StatelessWidget {
  const IosLoading({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        // withValues replaces the deprecated withOpacity; same 80% black.
        color: AppColor.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      // The old Theme(cupertinoOverrideTheme: dark) wrapper was dropped: the
      // indicator's color is set explicitly, so it had no visible effect.
      child: const Center(
        child: CupertinoActivityIndicator(
          radius: 17.0,
          color: AppColor.secondary300,
        ),
      ),
    ),
  );
}
