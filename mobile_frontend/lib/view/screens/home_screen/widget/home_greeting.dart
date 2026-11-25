// Home: the greeting with the signed-in captain's first name (D-A82).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';

/// «مرحباً، {name}» with only the captain's **first name** (D-A82), or
/// «مرحباً بك» when no name is known (no session, as in the debug preview,
/// or a missing/blank name). No name is ever invented.
///
/// The first name is a presentation of the session's full `displayName`
/// ([firstName]); the stored name and Profile keep the full name.
/// Subscribes only to that first name, so a session change rebuilds this
/// line and nothing else on Home.
class HomeGreeting extends StatelessWidget {
  const HomeGreeting({super.key});

  /// The first non-empty whitespace-delimited token of [displayName]
  /// (spaces, tabs and newlines all separate), or null when there is none.
  static String? firstName(String? displayName) {
    if (displayName == null) return null;
    final tokens = displayName.trim().split(RegExp(r'\s+'));
    final first = tokens.isEmpty ? '' : tokens.first;
    return first.isEmpty ? null : first;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = context.select<AppSessionCubit, String?>((cubit) {
      final session = cubit.state;
      return session is SessionAuthenticated
          ? firstName(session.user.displayName)
          : null;
    });
    return Text(
      name == null ? l10n.homeGreetingNoName : l10n.homeGreeting(name),
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        color: AppColor.textPrimary,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
