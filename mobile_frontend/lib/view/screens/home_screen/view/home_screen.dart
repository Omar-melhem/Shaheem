// Home: app bar with the read-only wallet total, greeting and the
// captain's availability card.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/domain/entities/captain_availability.dart';
import 'package:mobile_frontend/helper/money/jod_format.dart';
import 'package:mobile_frontend/helper/translation/generated/app_localizations.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/util/responsive/app_breakpoints.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';
import 'package:mobile_frontend/view/screens/home_screen/cubit/home_availability_cubit.dart';
import 'package:mobile_frontend/view/widget/buttons/app_text_button.dart';
import 'package:mobile_frontend/view/widget/pop_up_screen/app_popup.dart';
import 'package:mobile_frontend/view/widget/toggle/app_availability_toggle.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

/// The Home destination (Task 15 Option A, implemented in Task 24).
///
/// - **App bar:** the «الرئيسية» title when it fits, and the read-only
///   total wallet balance. No Profile button: Profile is still the fifth
///   bottom tab, so one here would only duplicate it until D-A66.
/// - **Body:** a greeting and the availability card. The card's state
///   belongs to [HomeAvailabilityCubit] (provided by the Home route).
///
/// The availability status is read when Home opens and again when the app
/// returns to the foreground; neither ever shows a permission prompt.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.walletTotalFils});

  /// Total wallet balance in integer fils from an authenticated backend
  /// source. Null (the default, as no wallet backend exists yet) shows «—»
  /// and an "unavailable" label, never a zero amount.
  final int? walletTotalFils;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<HomeAvailabilityCubit>();
    unawaited(cubit.load());
    // Reconcile with the server after the app was in the background (the
    // captain may have changed permissions meanwhile). Never prompts.
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(cubit.load()));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = context.watch<AppSessionCubit>().state;
    final name = session is SessionAuthenticated
        ? session.user.displayName
        : null;
    final greeting = name == null || name.trim().isEmpty
        ? l10n.homeGreetingNoName
        : l10n.homeGreeting(name);

    return BlocListener<HomeAvailabilityCubit, HomeAvailabilityState>(
      listenWhen: (previous, current) =>
          previous.pendingRationale == null && current.pendingRationale != null,
      listener: (context, state) => _showRationale(context),
      child: Scaffold(
        appBar: _HomeAppBar(
          walletTotalFils: widget.walletTotalFils,
          height: _HomeAppBar.heightFor(context),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppBreakpoints.screenPadding(context),
            vertical: 16,
          ),
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: AppBreakpoints.formMaxWidth(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    greeting,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColor.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _AvailabilityCard(),
                ],
              ),
            ),
          ),
        ),
      ),
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

/// App bar: title (only when it fits beside the balance) and the wallet
/// total. Grows with the text scale so the balance is never clipped.
class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _HomeAppBar({required this.walletTotalFils, required this.height});

  final int? walletTotalFils;

  /// Toolbar height from [heightFor]. The Scaffold sizes the app bar from
  /// [preferredSize], which has no context, so the caller passes it.
  final double height;

  static const double _verticalPadding = 8;

  /// At least the standard toolbar height, taller when the text scale
  /// needs it: room for two lines of balance text (amount and currency may
  /// wrap onto separate lines on narrow screens with large text).
  static double heightFor(BuildContext context) {
    final chipStyle = _WalletBalanceChip.textStyle(Theme.of(context));
    final line =
        MediaQuery.textScalerOf(context).scale(chipStyle.fontSize!) * 1.5;
    return math.max(
      kToolbarHeight,
      2 * line + 2 * _WalletBalanceChip.verticalPadding + 2 * _verticalPadding,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final titleStyle =
        theme.appBarTheme.titleTextStyle ?? theme.textTheme.titleLarge!;

    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: false,
      toolbarHeight: height,
      titleSpacing: AppBreakpoints.screenPadding(context),
      title: LayoutBuilder(
        builder: (context, constraints) {
          final chip = _WalletBalanceChip(totalFils: walletTotalFils);
          final titleWidth = _textWidth(l10n.homeTitle, titleStyle, scaler);
          final chipWidth = _WalletBalanceChip.naturalWidth(
            context,
            walletTotalFils,
          );
          final titleFits = titleWidth + 16 + chipWidth <= constraints.maxWidth;
          return Row(
            children: [
              if (titleFits)
                Text(l10n.homeTitle, style: titleStyle, maxLines: 1)
              else
                // Kept for screen readers when there is no room to show it.
                Semantics(
                  header: true,
                  label: l10n.homeTitle,
                  child: const SizedBox.shrink(),
                ),
              const Spacer(),
              Flexible(flex: 0, child: chip),
            ],
          );
        },
      ),
    );
  }

  static double _textWidth(String text, TextStyle style, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.rtl,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }
}

/// Read-only total wallet balance (no action until a Wallet route exists).
class _WalletBalanceChip extends StatelessWidget {
  const _WalletBalanceChip({required this.totalFils});

  final int? totalFils;

  static const double iconSize = 20;
  static const double gap = 6;
  static const double horizontalPadding = 12;
  static const double verticalPadding = 6;

  static TextStyle textStyle(ThemeData theme) => theme.textTheme.titleSmall!
      .copyWith(color: AppColor.textPrimary, fontWeight: FontWeight.bold);

  /// The visible text: the LTR-isolated amount and the currency, or «—».
  static String visibleText(AppLocalizations l10n, int? fils) => fils == null
      ? l10n.walletBalanceUnknownValue
      : '${ltrIsolate(formatJodFils(fils))} ${l10n.walletCurrencySymbol}';

  /// Width of the chip on one line.
  static double naturalWidth(BuildContext context, int? fils) =>
      _HomeAppBar._textWidth(
        visibleText(context.l10n, fils),
        textStyle(Theme.of(context)),
        MediaQuery.textScalerOf(context),
      ) +
      iconSize +
      gap +
      2 * horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final fils = totalFils;

    return Semantics(
      container: true,
      label: fils == null
          ? l10n.walletBalanceUnavailableSemantics
          : l10n.walletBalanceSemantics(formatJodFils(fils)),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColor.border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIconsRegular.wallet,
                size: iconSize,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: gap),
              Flexible(
                // Wraps only at the space between amount and currency.
                child: Text(visibleText(l10n, fils), style: textStyle(theme)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The availability card: heading, the toggle and any explanation.
class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard();

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
              _NoticeView(notice: notice, confirmed: state.confirmed),
            ],
          ],
        ),
      ),
    );
  }
}

/// Explains a notice and offers the matching action (retry or settings).
class _NoticeView extends StatelessWidget {
  const _NoticeView({required this.notice, required this.confirmed});

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
