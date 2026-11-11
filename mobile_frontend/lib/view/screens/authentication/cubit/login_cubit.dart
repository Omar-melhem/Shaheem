// State management for the Login form.

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/domain/use_cases/sign_in.dart';
import 'package:mobile_frontend/util/validators/validation_error.dart';
import 'package:mobile_frontend/util/validators/validators.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';

part 'login_state.dart';

/// Drives the Login form: field values, local validation, submission and
/// the hand-off of a successful sign-in to the app-wide [AppSessionCubit].
///
/// Feature-scoped: created by the `/login` route, not app-wide. It calls
/// the pure [Validators] and the [SignIn] use case; it never does HTTP or
/// JSON itself, and never invents a user or token.
///
/// On success it publishes the user through the session's attempt-token
/// API (the same path startup uses). The router then leaves Login because
/// the session became authenticated — the Cubit itself never navigates.
class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._signIn, this._session) : super(const LoginState());

  final SignIn _signIn;
  final AppSessionCubit _session;

  /// The password, kept out of [LoginState] on purpose (see its doc).
  String _password = '';

  /// Updates the username and clears its error, if any.
  void usernameChanged(String value) {
    emit(state.copyWith(username: value, usernameError: () => null));
  }

  /// Updates the password and clears its error, if any.
  void passwordChanged(String value) {
    _password = value;
    if (state.passwordError != null) {
      emit(state.copyWith(passwordError: () => null));
    }
  }

  /// Validates and signs in. Ignored while a submission is running, so
  /// repeated taps can't start overlapping requests.
  Future<void> submit() async {
    if (state.isSubmitting || state.status == LoginStatus.success) return;

    // Local rules are "required" only: no email format, charset or length
    // rules are approved for Login.
    final usernameError = Validators.loginUsername(state.username);
    final passwordError = Validators.loginPassword(_password);
    if (usernameError != null || passwordError != null) {
      emit(
        state.copyWith(
          usernameError: () => usernameError,
          passwordError: () => passwordError,
        ),
      );
      return;
    }

    emit(state.copyWith(status: LoginStatus.submitting, failure: () => null));
    // A newer attempt (or a sign-out) invalidates this token, so a late
    // response can't sign the user in afterwards.
    final token = _session.beginAttempt();

    final result = await _signIn(username: state.username, password: _password);
    if (isClosed || !_session.isCurrent(token)) return;

    switch (result) {
      case SignInSuccess(:final user):
        // Session first; the router reacts to it and opens Home.
        _session.authenticate(user, token);
        emit(state.copyWith(status: LoginStatus.success));
      case SignInInvalidCredentials():
        _fail(LoginFailure.invalidCredentials);
      case SignInAccountBlocked():
        _fail(LoginFailure.accountBlocked);
      case SignInNoInternet():
        _fail(LoginFailure.noInternet);
      case SignInServiceUnavailable():
        _fail(LoginFailure.serviceUnavailable);
      case SignInProfileFailure():
        _fail(LoginFailure.profileFailure);
      case SignInBackendNotConfigured():
        _fail(LoginFailure.backendNotConfigured);
      case SignInFailure():
        _fail(LoginFailure.unexpected);
    }
  }

  /// Back to idle with [failure]; the typed values are kept.
  void _fail(LoginFailure failure) {
    emit(
      state.copyWith(
        status: LoginStatus.idle,
        failure: () => failure,
        failureCount: state.failureCount + 1,
      ),
    );
  }
}
