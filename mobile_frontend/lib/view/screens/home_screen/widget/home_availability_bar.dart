// Home AppBar, second row: the controlled availability switch (D-A71).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/domain/entities/captain_availability.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/view/screens/home_screen/cubit/home_availability_cubit.dart';
import 'package:mobile_frontend/view/screens/home_screen/widget/home_availability_notice.dart';
import 'package:mobile_frontend/view/widget/toggle/app_availability_toggle.dart';

/// The availability row of the Home AppBar: the existing controlled
/// [AppAvailabilityToggle] with its server-confirmed status line, and any
/// notice (errors, missing requirements, not configured) with its Retry /
/// Settings action underneath.
///
/// It moved from a body card into the AppBar (D-A71) without changing
/// behavior: the switch shows only the last server-confirmed value, is
/// disabled while a command runs or when no change is possible, and the
/// permission explanation is still shown by
/// `HomeAvailabilityRationaleListener`. It reads the one Home-scoped
/// `HomeAvailabilityCubit`.
class HomeAvailabilityBar extends StatelessWidget {
  const HomeAvailabilityBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppAvailabilityToggle(
          value: state.isAvailable,
          onChanged: state.canChange ? cubit.requestChange : null,
          label: l10n.availabilityToggleLabel,
          supportingText: status,
          isBusy: state.isBusy,
        ),
        if (state.notice case final notice?) ...[
          const SizedBox(height: 4),
          HomeAvailabilityNotice(notice: notice, confirmed: state.confirmed),
        ],
      ],
    );
  }
}
