// Profile screen (placeholder).

import 'package:flutter/material.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/view/widget/navigation/main_nav_destination.dart';
import 'package:mobile_frontend/view/widget/placeholder/under_construction_placeholder.dart';

/// Root screen of the Profile branch of the main shell.
///
/// Placeholder only: a localized title and an under-construction state. The
/// feature itself (data, Cubit, API) is a later task; nothing is invented
/// here.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: UnderConstructionPlaceholder(
        icon: MainNavDestination.profile.icon,
        message: l10n.profilePlaceholderMessage,
      ),
    );
  }
}
