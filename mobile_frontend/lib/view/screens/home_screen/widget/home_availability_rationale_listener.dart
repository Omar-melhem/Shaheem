// Home: shows the permission explanation when the availability flow asks.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/view/screens/home_screen/cubit/home_availability_cubit.dart';
import 'package:mobile_frontend/view/widget/pop_up_screen/app_popup.dart';

/// Presentation side effect only: when [HomeAvailabilityCubit] starts
/// waiting for the captain to read why location and notifications are
/// needed (`pendingRationale` becomes non-null), shows the explanation
/// popup once. «متابعة» continues the flow; «إلغاء», back or the barrier
/// dismiss it and request nothing. The Cubit never shows UI itself.
class HomeAvailabilityRationaleListener extends StatelessWidget {
  const HomeAvailabilityRationaleListener({super.key, required this.child});

  /// The Home content the listener wraps.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeAvailabilityCubit, HomeAvailabilityState>(
      listenWhen: (previous, current) =>
          previous.pendingRationale == null && current.pendingRationale != null,
      listener: (context, state) => _showRationale(context),
      child: child,
    );
  }

  /// Explains why location and notifications are needed before any system
  /// prompt. Closing it any other way than «متابعة» requests nothing.
  Future<void> _showRationale(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<HomeAvailabilityCubit>();
    await showAppPopup<void>(
      context,
      title: l10n.availabilityRationaleTitle,
      message: l10n.availabilityRationaleMessage,
      actions: [
        AppPopupAction(label: l10n.cancel, onPressed: cubit.dismissRationale),
        AppPopupAction(
          label: l10n.availabilityContinue,
          isPrimary: true,
          onPressed: () => unawaited(cubit.continueAfterRationale()),
        ),
      ],
    );
    // Back button or barrier: the actions above did not run.
    if (!cubit.isClosed && cubit.state.pendingRationale != null) {
      cubit.dismissRationale();
    }
  }
}
