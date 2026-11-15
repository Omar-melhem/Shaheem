// Home: the captain availability card (toggle and explanation).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/domain/entities/captain_availability.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/view/screens/home_screen/cubit/home_availability_cubit.dart';
import 'package:mobile_frontend/view/screens/home_screen/widget/home_availability_notice.dart';
import 'package:mobile_frontend/view/widget/toggle/app_availability_toggle.dart';

/// The availability card: heading, the toggle and any explanation.
class HomeAvailabilityCard extends StatelessWidget {
  const HomeAvailabilityCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<HomeAvailabilityCubit>();
    final state = context.watch<HomeAvailabilityCubit>().state;

    final status = state.isBusy
        ? l10n.availabilityChecking
        : switch (state.confirmed) {
            CaptainAvailability.available => l10n.availabilityStatusAvailable,
            CaptainAvailability.unavailable =>
              l10n.availabilityStatusUnavailable,
            null => l10n.availabilityStatusUnknown,
          };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.availabilityCardTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColor.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            AppAvailabilityToggle(
              value: state.isAvailable,
              onChanged: state.canChange ? cubit.requestChange : null,
              label: l10n.availabilityToggleLabel,
              supportingText: status,
              isBusy: state.isBusy,
            ),
            if (state.notice case final notice?) ...[
              const SizedBox(height: 8),
              HomeAvailabilityNotice(
                notice: notice,
                confirmed: state.confirmed,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
