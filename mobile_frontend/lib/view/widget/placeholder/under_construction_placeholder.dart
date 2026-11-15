// Shared placeholder body for screens whose feature is not built yet.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/view/widget/status/app_status_message.dart';

/// "Under construction" state: an icon, the shared heading and a
/// screen-specific [message], laid out by [AppStatusMessage].
///
/// Shows no data and calls nothing; it only says the feature is coming.
class UnderConstructionPlaceholder extends StatelessWidget {
  const UnderConstructionPlaceholder({
    super.key,
    required this.icon,
    required this.message,
  });

  /// Decorative icon identifying the feature.
  final IconData icon;

  /// Localized sentence for this screen.
  final String message;

  @override
  Widget build(BuildContext context) => AppStatusMessage(
    icon: icon,
    title: context.l10n.underConstructionTitle,
    message: message,
  );
}
