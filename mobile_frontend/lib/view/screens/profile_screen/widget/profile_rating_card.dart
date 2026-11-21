// «حسابي»: the captain's rating from an explicit read model (D-A77).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/helper/money/jod_format.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/view/screens/profile_screen/cubit/profile_rating_cubit.dart';
import 'package:mobile_frontend/view/widget/buttons/app_text_button.dart';

/// Shows the rating exactly as the server reports it:
/// - a value, «x من y» only when the server states the scale (never an
///   assumed 5-star scale, D-P37), with the number of ratings;
/// - «لا توجد تقييمات بعد» for a confirmed "no ratings";
/// - «التقييم غير متوفر» when unknown (not configured, offline, failure),
///   with Retry for the last two.
/// Never a fabricated or perfect rating.
class ProfileRatingCard extends StatelessWidget {
  const ProfileRatingCard({super.key});

  static String _number(double value) {
    final rounded = (value * 10).round() / 10;
    return rounded == rounded.truncateToDouble()
        ? rounded.toInt().toString()
        : rounded.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = context.watch<ProfileRatingCubit>().state;
    final rating = state.rating;

    final (String value, String? detail) = switch (state.status) {
      ProfileRatingStatus.initial ||
      ProfileRatingStatus.loading => (l10n.profileRatingLoading, null),
      ProfileRatingStatus.loaded when rating != null && rating.hasRatings => (
        rating.scaleMax == null
            ? ltrIsolate(_number(rating.average!))
            : l10n.profileRatingOutOf(
                ltrIsolate(_number(rating.average!)),
                ltrIsolate(_number(rating.scaleMax!)),
              ),
        l10n.profileRatingCount(rating.ratingsCount),
      ),
      ProfileRatingStatus.loaded => (l10n.profileRatingNone, null),
      _ => (l10n.profileRatingUnavailable, null),
    };

    return Semantics(
      container: true,
      label: [l10n.profileRatingTitle, value, ?detail].join('. '),
      excludeSemantics: !state.canRetry,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.divider),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.star_outline,
                size: 24,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.profileRatingTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColor.textPrimary,
                      ),
                    ),
                    if (detail != null)
                      Text(
                        detail,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColor.textSecondary,
                        ),
                      ),
                    if (state.canRetry)
                      AppTextButton(
                        label: l10n.retry,
                        onPressed: () => unawaited(
                          context.read<ProfileRatingCubit>().load(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
