part of 'login_cubit.dart';

/// Where the Login form is in its lifecycle.
enum LoginStatus {
  /// Editing; nothing in flight.
  idle,

  /// A sign-in request is running; further submits are ignored.
  submitting,

  /// Signed in and the session published to `AppSessionCubit`. The router
  /// then leaves Login.
  success,
}

/// Why the last submission failed (shown as a toast, not as a field error).
enum LoginFailure {
  invalidCredentials,
  accountBlocked,
  noInternet,
  serviceUnavailable,
  profileFailure,
  backendNotConfigured,
  unexpected,
}

/// Login form state.
///
/// SECURITY: the password is deliberately **not** part of this state, so it
/// can never appear in `toString`, logs, debugging tools or tests' state
/// dumps. Only the Cubit holds it, privately.
@immutable
final class LoginState {
  const LoginState({
    this.username = '',
    this.usernameError,
    this.passwordError,
    this.status = LoginStatus.idle,
    this.failure,
    this.failureCount = 0,
  });

  /// Current username, as typed.
  final String username;

  /// Local validation errors; null means no error shown.
  final ValidationError? usernameError;
  final ValidationError? passwordError;

  final LoginStatus status;

  /// Failure of the latest submission, or null.
  final LoginFailure? failure;

  /// Increments with every failure, so the UI shows a toast again even when
  /// the same failure repeats.
  final int failureCount;

  bool get isSubmitting => status == LoginStatus.submitting;

  LoginState copyWith({
    String? username,
    ValidationError? Function()? usernameError,
    ValidationError? Function()? passwordError,
    LoginStatus? status,
    LoginFailure? Function()? failure,
    int? failureCount,
  }) => LoginState(
    username: username ?? this.username,
    usernameError: usernameError != null ? usernameError() : this.usernameError,
    passwordError: passwordError != null ? passwordError() : this.passwordError,
    status: status ?? this.status,
    failure: failure != null ? failure() : this.failure,
    failureCount: failureCount ?? this.failureCount,
  );

  @override
  String toString() =>
      'LoginState(status: $status, failure: $failure, '
      'usernameError: $usernameError, passwordError: $passwordError)';
}
