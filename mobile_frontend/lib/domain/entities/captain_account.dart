// The captain's rating and account-deletion outcomes as the SHAHM backend
// reports them (client revision D-A77, D-A78).

/// The captain's rating from an explicit server read model (D-A77).
///
/// The scale and aggregation are an open owner/contract question (D-P37):
/// [scaleMax] is whatever the server states, or null when it states none —
/// the UI never assumes a 5-star scale. "No ratings yet" ([hasRatings]
/// false) is a confirmed answer, distinct from "unknown" (a failed or
/// unconfigured read, which never produces this object). Never a
/// fabricated perfect rating.
class CaptainRating {
  const CaptainRating({required this.ratingsCount, this.average, this.scaleMax})
    : assert(ratingsCount >= 0, 'ratingsCount cannot be negative');

  /// How many ratings the server aggregated.
  final int ratingsCount;

  /// The server's aggregated value; null when there are no ratings.
  final double? average;

  /// The top of the scale, only when the server states it.
  final double? scaleMax;

  /// Whether there is a value to show.
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
