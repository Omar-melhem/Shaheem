part of 'splash_cubit.dart';

/// Progress of the startup sequence. The router uses it to pick the startup
/// screen, and Splash/No Internet use it for their UI.
@immutable
sealed class SplashState {
  const SplashState();
}

/// Startup has not begun yet.
final class SplashInitial extends SplashState {
  const SplashInitial();
}

/// Internet, session and profile checks are running.
final class SplashChecking extends SplashState {
  const SplashChecking();
}

/// The device has no usable internet. Shown on the No Internet screen.
final class SplashOffline extends SplashState {
  const SplashOffline();
}

/// The internet check itself failed or timed out, so reachability is
/// unknown. Shown on Splash with Retry; not presented as "no internet".
final class SplashConnectivityCheckFailed extends SplashState {
  const SplashConnectivityCheckFailed();
}

/// Internet works but the SHAHM backend is unreachable or timed out.
final class SplashServiceUnavailable extends SplashState {
  const SplashServiceUnavailable();
}

/// The session is valid but the user's profile could not be loaded or was
/// malformed. The user stays signed in; Retry tries again.
final class SplashProfileFailure extends SplashState {
  const SplashProfileFailure();
}

/// The account may not use this app (disabled, suspended or wrong role).
final class SplashBlocked extends SplashState {
  const SplashBlocked();
}

/// An unexpected error. Recoverable via Retry; not treated as signed out.
final class SplashFailure extends SplashState {
  const SplashFailure();
}

/// Startup finished and handed its outcome (signed in or not) to
/// `AppSessionCubit`. The router takes over from here.
final class SplashResolved extends SplashState {
  const SplashResolved();
}
