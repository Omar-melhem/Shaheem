part of 'app_session_cubit.dart';

/// Who is using the app right now, as far as the client knows.
@immutable
sealed class AppSessionState {
  const AppSessionState();
}

/// Not determined yet (startup still running or ended in a recoverable
/// error). Protected routes stay closed in this state.
final class SessionUnknown extends AppSessionState {
  const SessionUnknown();
}

/// Confirmed that nobody is signed in: no session, a rejected session,
/// or the user signed out.
final class SessionUnauthenticated extends AppSessionState {
  const SessionUnauthenticated();
}

/// The backend accepted the session and a valid [user] has been loaded.
/// The only state that opens protected routes.
final class SessionAuthenticated extends AppSessionState {
  const SessionAuthenticated(this.user);

  final AppUser user;
}
