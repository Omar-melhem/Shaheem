// Domain representation of the currently signed-in user.

/// The authenticated user, as confirmed by the backend during startup or login.
///
/// Only [id] is required: it is the one field every session needs to be
/// trustworthy. The other fields are optional until the backend contract
/// confirms which ones always exist. Role values are deliberately a plain
/// string because the roles this mobile app supports are not decided yet.
class AppUser {
  const AppUser({required this.id, this.displayName, this.phone, this.role});

  /// Stable backend identifier. Never empty (enforced when mapping from data).
  final String id;

  /// Name shown in the UI, if the backend provides one.
  final String? displayName;

  /// Contact phone number, if the backend provides one.
  final String? phone;

  /// Backend role name. Not used for routing until role rules are approved.
  final String? role;
}
