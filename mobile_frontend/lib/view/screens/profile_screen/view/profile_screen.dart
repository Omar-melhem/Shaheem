// «حسابي» (D-A70, D-A77): identity, rating, Settings, Terms, About and
// sign-out.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_frontend/helper/legal/legal_page_launcher.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/util/responsive/app_breakpoints.dart';
import 'package:mobile_frontend/util/routes/routes_string.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';
import 'package:mobile_frontend/view/screens/profile_screen/cubit/profile_rating_cubit.dart';
import 'package:mobile_frontend/view/screens/profile_screen/widget/profile_summary_section.dart';
import 'package:mobile_frontend/view/widget/legal/terms_page_opener.dart';
import 'package:mobile_frontend/view/widget/pop_up_screen/app_popup.dart';

/// Root screen of the «حسابي» tab: a root tab, so it has no back button.
///
/// - [ProfileSummarySection]: one centered section with the name and phone
///   from the session and the 5-star rating from `ProfileRatingCubit`
///   (provided by the route), loaded on the first show, on each re-show of
///   the tab and on app resume while visible (R03) — never on rebuilds or
///   language changes.
/// - Entries: Settings (`/settings`, with account deletion), Terms &
///   Conditions (the same in-app legal flow as Login, [legalPageLauncher])
///   and About (`/about`). There is no Wallet entry (D-A77): the Wallet is
///   its own tab.
/// - Sign-out, after a confirmation popup, ends the session through
///   `AppSessionCubit` (the router then shows Login), so signing out never
///   depends on any debug tool.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.legalPageLauncher = const LegalPageLauncher(),
  });

  /// Opens the Terms page in-app (tests pass one with a fake launcher).
  final LegalPageLauncher legalPageLauncher;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// Ignores a second Terms tap while the first is opening.
  bool _openingTerms = false;

  late final AppLifecycleListener _lifecycle;

  /// Whether the branch was visible at the last dependency change; null
  /// before the first one (the mount load already covers it).
  bool? _wasActive;

  // Rating refresh (R03, STATE-01), the same visibility mechanics as My
  // Orders: once on the first show, once each time the tab becomes visible
  // again (go_router's indexed stack turns TickerMode off for hidden
  // branches), and on app resume only while visible. Never on rebuilds,
  // never by polling; the Cubit ignores a trigger while a read runs.
  @override
  void initState() {
    super.initState();
    final cubit = context.read<ProfileRatingCubit>();
    if (cubit.state.status == ProfileRatingStatus.initial) {
      unawaited(cubit.load());
    }
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (_wasActive ?? true) {
          unawaited(context.read<ProfileRatingCubit>().load());
        }
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = TickerMode.valuesOf(context).enabled;
    if (_wasActive == false && active) {
      unawaited(context.read<ProfileRatingCubit>().load());
    }
    _wasActive = active;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _openTerms() async {
    if (_openingTerms) return;
    _openingTerms = true;
    try {
      await openTermsPage(context, widget.legalPageLauncher);
    } finally {
      _openingTerms = false;
    }
  }

  Future<void> _confirmSignOut() async {
    final l10n = context.l10n;
    final session = context.read<AppSessionCubit>();
    final confirmed = await showAppPopup<bool>(
      context,
      title: l10n.profileSignOut,
      message: l10n.profileSignOutConfirm,
      actions: [
        AppPopupAction(label: l10n.cancel),
        // Typed result (R06): only this action completes with true.
        AppPopupAction<bool>(
          label: l10n.profileSignOut,
          isPrimary: true,
          result: true,
        ),
      ],
    );
    if (confirmed == true) await session.endSession();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(l10n.profileTitle),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final side = AppBreakpoints.screenPadding(context);
          final maxWidth = AppBreakpoints.formMaxWidth(context);
          final end = math.max(side, constraints.maxWidth - side - maxWidth);
          return ListView(
            padding: EdgeInsetsDirectional.fromSTEB(side, 16, end, 24),
            children: [
              const ProfileSummarySection(),
              const SizedBox(height: 16),
              _MenuTile(
                icon: Icons.settings_outlined,
                label: l10n.settingsTitle,
                onTap: () => context.push(RoutesString.settings),
              ),
              _MenuTile(
                icon: Icons.description_outlined,
                label: l10n.termsAndConditions,
                onTap: () => unawaited(_openTerms()),
              ),
              _MenuTile(
                icon: Icons.info_outline,
                label: l10n.aboutTitle,
                onTap: () => context.push(RoutesString.about),
              ),
              const Divider(height: 24, color: AppColor.divider),
              _MenuTile(
                icon: Icons.logout,
                label: l10n.profileSignOut,
                onTap: () => unawaited(_confirmSignOut()),
                showChevron: false,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One accessible Profile entry (whole row is the ≥ 56 px target).
class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    minTileHeight: 56,
    leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
    title: Text(label),
    trailing: showChevron
        ? const Icon(Icons.chevron_right, color: AppColor.textSecondary)
        : null,
    onTap: onTap,
  );
}
