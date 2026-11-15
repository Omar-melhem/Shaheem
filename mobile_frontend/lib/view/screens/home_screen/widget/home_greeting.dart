// Home: the greeting with the signed-in captain's name.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';

/// «مرحباً، {name}», or «مرحباً بك» when no name is known (no session, as in
/// the debug preview, or a missing/blank name). No name is ever invented.
///
/// Subscribes only to the display name, so a session change rebuilds this
/// line and nothing else on Home.
class HomeGreeting extends StatelessWidget {
  const HomeGreeting({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = context.select<AppSessionCubit, String?>((cubit) {
      final session = cubit.state;
      return session is SessionAuthenticated ? session.user.displayName : null;
    });
    return Text(
      name == null || name.trim().isEmpty
          ? l10n.homeGreetingNoName
          : l10n.homeGreeting(name),
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        color: AppColor.textPrimary,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
