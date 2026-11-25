// «حسابي»: five read-only stars with fractional fill for the rating.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/domain/entities/captain_account.dart';
import 'package:mobile_frontend/theme/app_color.dart';

/// Five **decorative, read-only** stars for a rating value on the fixed
/// 0..[CaptainRating.scale] scale (feature-scoped to Profile).
///
/// Each star is filled by the part of [value] that falls on it (4.3 → four
/// full stars and 30 % of the fifth), so the fill is exact and never
/// rounded up to a fuller look. The fill starts at the logical start of
/// the row (right in Arabic, left in English) and follows the ambient
/// [Directionality]. It produces **no semantics**: the parent exposes one
/// localized sentence with the exact value instead (no duplicate labels).
///
/// [value] must already be valid (finite, within the scale); the widget
/// asserts it and never clamps a server value into range.
class ProfileRatingStars extends StatelessWidget {
  const ProfileRatingStars({super.key, required this.value, this.size = 28});

  /// The validated rating value.
  final double value;

  /// Edge length of one star.
  final double size;

  /// Key of the row, for tests.
  static const Key rowKey = Key('profile-rating-stars');

  /// How much of the star at [index] (0-based) [value] fills, 0..1.
  static double fillOf(double value, int index) {
    final part = value - index;
    if (part <= 0) return 0;
    if (part >= 1) return 1;
    return part;
  }

  @override
  Widget build(BuildContext context) {
    assert(
      value.isFinite && value >= 0 && value <= CaptainRating.scale,
      'ProfileRatingStars: value must be a validated 0..5 rating.',
    );
    const count = 5;
    return ExcludeSemantics(
      child: Row(
        key: rowKey,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            _Star(fill: fillOf(value, i), size: size),
        ],
      ),
    );
  }
}

/// One star: an outline, with the filled star clipped to [fill] of its
/// width from the logical start.
class _Star extends StatelessWidget {
  const _Star({required this.fill, required this.size});

  final double fill;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Stack(
      children: [
        Icon(
          Icons.star_outline_rounded,
          size: size,
          color: AppColor.inputOutline,
        ),
        if (fill > 0)
          ClipRect(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: fill,
              child: Icon(
                Icons.star_rounded,
                size: size,
                color: AppColor.primary,
              ),
            ),
          ),
      ],
    ),
  );
}
