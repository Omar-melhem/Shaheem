// About (D-A77): the app's identity, without invented details.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/util/images.dart';

/// The protected About page above the shell (pushed from «حسابي»; Back
/// returns there).
///
/// Shows the existing app identity only: the official logo, the app name
/// and the existing one-line product description. No company name, social
/// account, support contact or certification is invented. The version and
/// build number need a source the app does not have yet (no
/// `package_info_plus` dependency), so the page says the version is not
/// available instead of guessing it.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Image.asset(
              AppImages.logo,
              width: 140,
              semanticLabel: l10n.appName,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.appName,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.aboutDescription,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColor.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.info_outline,
              color: theme.colorScheme.secondary,
            ),
            title: Text(l10n.aboutVersionLabel),
            subtitle: Text(l10n.aboutVersionUnavailable),
          ),
        ],
      ),
    );
  }
}
