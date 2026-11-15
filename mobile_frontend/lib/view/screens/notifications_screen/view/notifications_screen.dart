// Notifications screen (placeholder).

import 'package:flutter/material.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/view/widget/navigation/main_nav_destination.dart';
import 'package:mobile_frontend/view/widget/placeholder/under_construction_placeholder.dart';

/// Root screen of the Notifications branch of the main shell.
///
/// Placeholder only: a localized title and an under-construction state. The
/// feature itself (data, Cubit, API) is a later task; nothing is invented
/// here.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationsTitle)),
      body: UnderConstructionPlaceholder(
        icon: MainNavDestination.notifications.icon,
        message: l10n.notificationsPlaceholderMessage,
      ),
    );
  }
}
