// The captain's rating and account-deletion outcomes as the SHAHM backend
// reports them (client revision D-A77, D-A78).

/// The captain's rating from an explicit server read model (D-A77).
///
/// The scale is **fixed at 0..[scale] (5 stars)** by owner decision; who
/// rates captains and how the server aggregates ratings are still open
/// (D-P37) and nothing here assumes them. The object carries the server's
/// values unchanged: it never clamps, rounds or rescales them. Whether
/// they may be shown is [isValid]; the use case turns an invalid answer
/// into an "unavailable" outcome instead of displaying it.
///
/// "No ratings yet" ([hasRatings] false, a count of 0 without an average)
/// is a confirmed answer, distinct from "unknown" (a failed, unconfigured
/// or invalid read, which never reaches the UI as a value) and never shown
/// as a zero score. Never a fabricated perfect rating.
class CaptainRating {
  const CaptainRating({required this.ratingsCount, this.average});

  /// The top of the rating scale (5 stars).
  static const double scale = 5;

  /// How many ratings the server aggregated.
  final int ratingsCount;

  /// The server's aggregated value; null when there are no ratings.
  final double? average;

  /// Whether the answer is coherent and inside the scale:
  /// - the count is not negative;
  /// - a count of 0 comes without an average ("no ratings yet");
  /// - a positive count comes with a finite average within 0..[scale].
  bool get isValid {
    if (ratingsCount < 0) return false;
    final value = average;
    if (ratingsCount == 0) return value == null;
    return value != null && value.isFinite && value >= 0 && value <= scale;
  }

  /// Whether there is a value to show (only meaningful when [isValid]).
  bool get hasRatings => ratingsCount > 0 && average != null;
}

/// What the server reported after accepting a deletion request (D-A78).
enum AccountDeletionStatus {
  /// Accepted and still being processed: the account is **not** deleted
  /// yet. Session handling follows the server's contract (not invented).
  pending,

  /// The server confirmed the account and its associated personal data
  /// were deleted (or anonymized per the future contract).
  completed,
}
