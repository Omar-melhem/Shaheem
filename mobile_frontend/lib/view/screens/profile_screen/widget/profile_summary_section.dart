// «حسابي»: one centered section with the captain's name, phone and rating.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/domain/entities/captain_account.dart';
import 'package:mobile_frontend/helper/money/jod_format.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';
import 'package:mobile_frontend/view/screens/profile_screen/cubit/profile_rating_cubit.dart';
import 'package:mobile_frontend/view/screens/profile_screen/widget/profile_rating_stars.dart';
import 'package:mobile_frontend/view/widget/buttons/app_text_button.dart';

/// The top of «حسابي»: **one** centered section, top to bottom:
///
/// 1. the captain's full name;
/// 2. the phone, LTR-isolated so its digits keep their order in Arabic;
/// 3. the rating: five read-only stars with fractional fill
///    ([ProfileRatingStars]) and the exact value, e.g. «4.3 / 5», with the
///    number of ratings.
///
/// Name and phone come from the one `AppSessionCubit` (no second user
/// store, no editing); missing values show honest fallbacks. The rating
/// comes from `ProfileRatingCubit` (already validated by the use case) and
/// has its own states: loading, «لا توجد تقييمات بعد» (never a zero
/// score), the value, «التقييم غير متوفر» (not configured or invalid data),
/// offline and failure — the last two with Retry. The identity stays
/// visible whatever the rating state is.
///
/// Screen readers get one sentence each for the name, the phone and the
/// rating; the stars are decorative and add no label of their own.
class ProfileSummarySection extends StatelessWidget {
  const ProfileSummarySection({super.key});

  /// Key of the section, for tests.
  static const Key sectionKey = Key('profile-summary-section');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final user = context.select<AppSessionCubit, (String?, String?)>((cubit) {
      final s = cubit.state;
      return s is SessionAuthenticated
          ? (s.user.displayName, s.user.phone)
          : (null, null);
    });
    String? clean(String? v) => v == null || v.trim().isEmpty ? null : v.trim();
    final name = clean(user.$1);
    final phone = clean(user.$2);

    return DecoratedBox(
      key: sectionKey,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Semantics(
              label: l10n.profileNameSemantics(
                name ?? l10n.profileNameUnavailable,
              ),
              excludeSemantics: true,
              child: Text(
                name ?? l10n.profileNameUnavailable,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: name == null
                      ? AppColor.textSecondary
                      : AppColor.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Semantics(
              label: l10n.profilePhoneSemantics(
                phone ?? l10n.profilePhoneUnavailable,
              ),
              excludeSemantics: true,
              child: Text(
                phone == null
                    ? l10n.profilePhoneUnavailable
                    : ltrIsolate(phone),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColor.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _RatingBlock(),
          ],
        ),
      ),
    );
  }
}

/// The rating part of the section, rebuilt only by `ProfileRatingCubit`.
class _RatingBlock extends StatelessWidget {
  const _RatingBlock();

  /// The server's value as text, never rounded up: truncated to at most
  /// two decimals with trailing zeros dropped (4.3 → «4.3», 4.999 → «4.99»,
  /// 5 → «5»), so a value below 5 is never shown as «5».
  static String number(double value) {
    final hundredths = (value * 100 + 1e-9).floor();
    final whole = hundredths ~/ 100;
    final fraction = hundredths % 100;
    if (fraction == 0) return '$whole';
    final digits = fraction.toString().padLeft(2, '0');
    return '$whole.${digits.endsWith('0') ? digits[0] : digits}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = context.watch<ProfileRatingCubit>().state;
    final rating = state.rating;
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: AppColor.textSecondary,
    );

    final Widget visual;
    final String semantics;
    if (state.status == ProfileRatingStatus.loaded &&
        rating != null &&
        rating.hasRatings) {
      final average = rating.average!;
      final value = number(average);
      final max = number(CaptainRating.scale);
      final count = l10n.profileRatingCount(rating.ratingsCount);
      semantics = l10n.profileRatingSemanticsValue(value, max, count);
      visual = Column(
        children: [
          ProfileRatingStars(value: average),
          const SizedBox(height: 6),
          Text(
            ltrIsolate(l10n.profileRatingValue(value, max)),
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColor.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(count, textAlign: TextAlign.center, style: secondary),
        ],
      );
    } else {
      final text = switch (state.status) {
        ProfileRatingStatus.initial ||
        ProfileRatingStatus.loading => l10n.profileRatingLoading,
        ProfileRatingStatus.loaded => l10n.profileRatingNone,
        ProfileRatingStatus.noInternet => l10n.profileRatingOffline,
        ProfileRatingStatus.failure => l10n.profileRatingFailed,
        ProfileRatingStatus.noSession ||
        ProfileRatingStatus.notConfigured ||
        ProfileRatingStatus.invalid => l10n.profileRatingUnavailable,
      };
      semantics = l10n.profileRatingSemantics(text);
      visual = Text(text, textAlign: TextAlign.center, style: secondary);
    }

    return Column(
      children: [
        Semantics(
          container: true,
          // One localized sentence (R08); the stars add no label.
          label: semantics,
          excludeSemantics: true,
          child: visual,
        ),
        if (state.canRetry)
          AppTextButton(
            label: l10n.retry,
            onPressed: () =>
                unawaited(context.read<ProfileRatingCubit>().load()),
          ),
      ],
    );
  }
}
