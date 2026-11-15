// Home: the availability notice text and its Retry / Settings actions.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/domain/entities/captain_availability.dart';
import 'package:mobile_frontend/helper/translation/generated/app_localizations.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/view/screens/home_screen/cubit/home_availability_cubit.dart';
import 'package:mobile_frontend/view/widget/buttons/app_text_button.dart';

/// Explains a notice and offers the matching action (retry or settings).
class HomeAvailabilityNotice extends StatelessWidget {
  const HomeAvailabilityNotice({
    super.key,
    required this.notice,
    required this.confirmed,
  });

  final AvailabilityNotice notice;
  final CaptainAvailability? confirmed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<HomeAvailabilityCubit>();
    final textStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: AppColor.textPrimary);

    final (
      String message,
      List<AvailabilityRequirement> missing,
    ) = switch (notice) {
      AvailabilityNoticeNotConfigured() => (
        l10n.availabilityNotConfigured,
        const <AvailabilityRequirement>[],
      ),
      AvailabilityNoticeNoSession() => (l10n.availabilityNoSession, const []),
      AvailabilityNoticeNoInternet() => (l10n.availabilityNoInternet, const []),
      AvailabilityNoticeServiceUnavailable() => (
        l10n.serviceUnavailableMessage,
        const [],
      ),
      AvailabilityNoticeRejected() => (l10n.availabilityRejected, const []),
      AvailabilityNoticePermissionsNotConfigured() => (
        l10n.availabilityPermissionsNotConfigured,
        const [],
      ),
      AvailabilityNoticeMissingRequirements(:final missing) => (
        l10n.availabilityMissingIntro,
        missing,
      ),
      AvailabilityNoticeRequirementsLost(:final missing) => (
        l10n.availabilityRequirementsLost,
        missing,
      ),
      AvailabilityNoticeUnconfirmed() => (
        confirmed == CaptainAvailability.available
            ? l10n.availabilityUnconfirmedWasAvailable
            : l10n.availabilityUnconfirmedWasUnavailable,
        const [],
      ),
    };

    final showRetry = switch (notice) {
      AvailabilityNoticeNoInternet() ||
      AvailabilityNoticeServiceUnavailable() ||
      AvailabilityNoticeUnconfirmed() => true,
      _ => false,
    };
    final showSettings = switch (notice) {
      AvailabilityNoticeMissingRequirements(:final settingsRequired) =>
        settingsRequired,
      AvailabilityNoticeRequirementsLost() => true,
      _ => false,
    };

    // Announced when it appears or changes.
    return Semantics(
      container: true,
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: textStyle),
          for (final requirement in missing)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 8, top: 4),
              child: Text(
                '• ${_requirementLabel(l10n, requirement)}',
                style: textStyle,
              ),
            ),
          if (showRetry || showSettings)
            Wrap(
              spacing: 8,
              children: [
                if (showRetry)
                  AppTextButton(
                    label: l10n.retry,
                    onPressed: () => unawaited(cubit.load()),
                  ),
                if (showSettings)
                  AppTextButton(
                    label: l10n.availabilityOpenSettings,
                    onPressed: () => unawaited(cubit.openSettings()),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  static String _requirementLabel(
    AppLocalizations l10n,
    AvailabilityRequirement requirement,
  ) => switch (requirement) {
    AvailabilityRequirement.locationService =>
      l10n.availabilityNeedLocationService,
    AvailabilityRequirement.preciseLocation =>
      l10n.availabilityNeedPreciseLocation,
    AvailabilityRequirement.backgroundLocation =>
      l10n.availabilityNeedBackgroundLocation,
    AvailabilityRequirement.notifications => l10n.availabilityNeedNotifications,
  };
}
