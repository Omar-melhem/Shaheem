// First screen shown at launch while startup checks run.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/util/images.dart';
import 'package:mobile_frontend/view/screens/splash_screen/widget/splash_startup_status.dart';

/// Shows the SHAHM logo with startup progress, or a recoverable startup
/// error with Retry (service unavailable, profile failure, blocked account,
/// unexpected error).
///
/// Composition only: the logo plus [SplashStartupStatus]. It does not
/// navigate: the router's redirect moves the user on once startup resolves. Startup itself is started by `MainApp`, so rebuilding
/// or re-showing this screen never repeats it.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logoWidth = MediaQuery.sizeOf(context).width * 0.6;

    return Scaffold(
      backgroundColor: AppColor.splashBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Image.asset(
                    AppImages.logo,
                    width: logoWidth,
                    fit: BoxFit.contain,
                    semanticLabel: context.l10n.appName,
                  ),
                ),
                const SizedBox(height: 32),
                const SplashStartupStatus(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
