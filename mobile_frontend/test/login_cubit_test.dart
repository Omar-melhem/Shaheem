// Unit tests for SignIn and LoginCubit: local D-A65 validation, the exact
// normalized username and unchanged password sent to SignIn, every backend
// outcome, duplicate-submit protection, session hand-off and password
// redaction.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_frontend/data/repositories/auth_repository_placeholder.dart';
import 'package:mobile_frontend/domain/errors/auth_exceptions.dart';
import 'package:mobile_frontend/domain/use_cases/get_current_user.dart';
import 'package:mobile_frontend/domain/use_cases/sign_in.dart';
import 'package:mobile_frontend/domain/use_cases/sign_out.dart';
import 'package:mobile_frontend/util/validators/validation_error.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';
import 'package:mobile_frontend/view/screens/authentication/cubit/login_cubit.dart';

import 'fakes.dart';

void main() {
  late FakeAuthRepository repo;
  late AppSessionCubit session;
  late LoginCubit cubit;

  setUp(() {
    repo = FakeAuthRepository();
    session = AppSessionCubit(SignOut(repo));
    cubit = LoginCubit(SignIn(repo, GetCurrentUser(repo)), session);
  });

  tearDown(() async {
    await cubit.close();
    await session.close();
  });

  /// Fills both fields with valid values.
  void fill() {
    cubit.usernameChanged('captain01');
    cubit.passwordChanged('p@ss word');
  }

  test('initial state: idle, empty, no errors', () {
    expect(cubit.state.status, LoginStatus.idle);
    expect(cubit.state.username, '');
    expect(cubit.state.usernameError, isNull);
    expect(cubit.state.passwordError, isNull);
  });

  test('both empty → both required errors, no request', () async {
    await cubit.submit();
    expect(cubit.state.usernameError, ValidationError.usernameRequired);
    expect(cubit.state.passwordError, ValidationError.passwordRequired);
    expect(repo.signInCalls, 0);
  });

  test('only username empty / only password empty', () async {
    cubit.passwordChanged('secret123');
    await cubit.submit();
    expect(cubit.state.usernameError, ValidationError.usernameRequired);
    expect(cubit.state.passwordError, isNull);

    cubit.usernameChanged('captain01');
    cubit.passwordChanged('');
    await cubit.submit();
    expect(cubit.state.usernameError, isNull);
    expect(cubit.state.passwordError, ValidationError.passwordRequired);
  });

  test('editing a field clears only that field\'s error', () async {
    await cubit.submit();
    cubit.usernameChanged('u');
    expect(cubit.state.usernameError, isNull);
    expect(cubit.state.passwordError, ValidationError.passwordRequired);
    cubit.passwordChanged('p');
    expect(cubit.state.passwordError, isNull);
  });

  test('username is not validated as email (plain username accepted)', () {
    fill();
    expect(cubit.state.usernameError, isNull);
  });

  test('valid input → use case called once with the typed values', () async {
    fill();
    repo.expectedPassword = 'p@ss word';
    await cubit.submit();
    expect(repo.signInCalls, 1);
    expect(repo.lastUsername, 'captain01');
    expect(repo.lastPasswordMatched, isTrue);
  });

  // D-A65 rules and the owner-approved clarifications, through the Cubit.
  group('D-A65 validation and submission', () {
    test('whitespace-only username → usernameRequired, no request', () async {
      cubit.usernameChanged('   ');
      cubit.passwordChanged('secret123');
      await cubit.submit();
      expect(cubit.state.usernameError, ValidationError.usernameRequired);
      expect(repo.signInCalls, 0);
    });

    test(
      'malformed username / short password → their codes, no request',
      () async {
        cubit.usernameChanged('abc');
        cubit.passwordChanged('1234567');
        await cubit.submit();
        expect(cubit.state.usernameError, ValidationError.usernameLength);
        expect(cubit.state.passwordError, ValidationError.passwordLength);
        expect(repo.signInCalls, 0);

        cubit.usernameChanged('captain@shahm');
        cubit.passwordChanged('a' * 129);
        await cubit.submit();
        expect(cubit.state.usernameError, ValidationError.usernameFormat);
        expect(cubit.state.passwordError, ValidationError.passwordLength);
        expect(repo.signInCalls, 0);
      },
    );

    test('editing clears a new-rule error on that field only', () async {
      cubit.usernameChanged('abc');
      cubit.passwordChanged('short');
      await cubit.submit();
      cubit.usernameChanged('abcd');
      expect(cubit.state.usernameError, isNull);
      expect(cubit.state.passwordError, ValidationError.passwordLength);
      cubit.passwordChanged('long enough');
      expect(cubit.state.passwordError, isNull);
    });

    test(
      'outer username spaces trimmed for SignIn; case and inside kept',
      () async {
        cubit.usernameChanged('  Captain.Name_1  ');
        cubit.passwordChanged('secret123');
        await cubit.submit();
        expect(repo.signInCalls, 1);
        expect(repo.lastUsername, 'Captain.Name_1');
        // The state keeps what the user typed.
        expect(cubit.state.username, '  Captain.Name_1  ');
      },
    );

    final phones = {
      'Latin': '0791234567',
      'Arabic-Indic': '٠٧٩١٢٣٤٥٦٧',
      'Extended Arabic-Indic': '۰۷۹۱۲۳۴۵۶۷',
      'mixed scripts': '07٩١23۴٥6٧',
    };
    phones.forEach((script, typed) {
      test('phone username ($script) → SignIn gets 10 Latin digits', () async {
        cubit.usernameChanged(' $typed ');
        cubit.passwordChanged('secret123');
        await cubit.submit();
        expect(cubit.state.usernameError, isNull);
        expect(repo.signInCalls, 1);
        expect(repo.lastUsername, '0791234567');
      });
    });

    test('+962 phone is not shortened into a local username', () async {
      cubit.usernameChanged('+962791234567');
      cubit.passwordChanged('secret123');
      await cubit.submit();
      expect(cubit.state.usernameError, ValidationError.usernameFormat);
      expect(repo.signInCalls, 0);
    });

    test(
      'password with outer and inner spaces reaches SignIn unchanged',
      () async {
        for (final password in ['  pass word  ', ' ' * 8, '   abcde']) {
          final repo = FakeAuthRepository()..expectedPassword = password;
          final session = AppSessionCubit(SignOut(repo));
          final cubit = LoginCubit(SignIn(repo, GetCurrentUser(repo)), session);
          cubit.usernameChanged('captain01');
          cubit.passwordChanged(password);
          await cubit.submit();
          expect(cubit.state.passwordError, isNull);
          expect(repo.signInCalls, 1);
          expect(repo.lastPasswordMatched, isTrue);
          await cubit.close();
          await session.close();
        }
      },
    );

    test('a common password is not rejected at sign-in', () async {
      cubit.usernameChanged('captain01');
      cubit.passwordChanged('password');
      await cubit.submit();
      expect(cubit.state.passwordError, isNull);
      expect(repo.signInCalls, 1);
    });

    test('password never appears in state or toString', () async {
      const secret = 'S3cret pass!';
      cubit.usernameChanged('captain01');
      cubit.passwordChanged(secret);
      expect(cubit.state.toString(), isNot(contains(secret)));
      repo.signInError = const InvalidCredentialsException();
      await cubit.submit();
      expect(cubit.state.toString(), isNot(contains(secret)));
    });
  });

  test('success → session authenticated with the backend user', () async {
    fill();
    await cubit.submit();
    expect(cubit.state.status, LoginStatus.success);
    final state = session.state as SessionAuthenticated;
    expect(state.user.id, testUser.id);
  });

  test('submitting state and duplicate-submit prevention', () async {
    fill();
    repo.signInPending = Completer<void>();
    final first = cubit.submit();
    expect(cubit.state.status, LoginStatus.submitting);
    await cubit.submit();
    await cubit.submit();
    repo.signInPending!.complete();
    await first;
    expect(repo.signInCalls, 1);
  });

  final failures = <Object, LoginFailure>{
    const InvalidCredentialsException(): LoginFailure.invalidCredentials,
    const AccountBlockedException(): LoginFailure.accountBlocked,
    const NetworkUnavailableException(): LoginFailure.noInternet,
    const ServiceUnavailableException(): LoginFailure.serviceUnavailable,
    const BackendNotConfiguredException(): LoginFailure.backendNotConfigured,
    StateError('boom'): LoginFailure.unexpected,
  };
  failures.forEach((error, expected) {
    test('${error.runtimeType} → $expected, no user, values kept', () async {
      fill();
      repo.signInError = error;
      await cubit.submit();
      expect(cubit.state.status, LoginStatus.idle);
      expect(cubit.state.failure, expected);
      expect(cubit.state.username, 'captain01');
      expect(session.state, isA<SessionUnknown>());
    });
  });

  test('profile failure after accepted credentials → no fake user', () async {
    fill();
    repo.userError = const ProfileUnavailableException();
    await cubit.submit();
    expect(cubit.state.failure, LoginFailure.profileFailure);
    expect(session.state, isA<SessionUnknown>());
  });

  test(
    'repeated identical failures are distinguishable (toast again)',
    () async {
      fill();
      repo.signInError = const InvalidCredentialsException();
      await cubit.submit();
      final firstCount = cubit.state.failureCount;
      await cubit.submit();
      expect(cubit.state.failureCount, firstCount + 1);
    },
  );

  test('a late success after sign-out does not authenticate', () async {
    fill();
    repo.signInPending = Completer<void>();
    final run = cubit.submit();
    await session.endSession(); // supersedes the login attempt
    repo.signInPending!.complete();
    await run;
    expect(session.state, isA<SessionUnauthenticated>());
  });

  test('password never appears in the state or its toString', () {
    fill();
    expect(cubit.state.toString(), isNot(contains('p@ss word')));
  });

  test('placeholder backend → backendNotConfigured, never success', () async {
    final placeholder = const AuthRepositoryPlaceholder();
    final realCubit = LoginCubit(
      SignIn(placeholder, GetCurrentUser(placeholder)),
      session,
    );
    // Valid under D-A65, so the request really reaches the placeholder.
    realCubit.usernameChanged('captain01');
    realCubit.passwordChanged('secret123');
    await realCubit.submit();
    expect(realCubit.state.failure, LoginFailure.backendNotConfigured);
    expect(session.state, isA<SessionUnknown>());
    await realCubit.close();
  });
}
