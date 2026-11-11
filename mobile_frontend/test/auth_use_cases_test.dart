// Unit tests for CheckAuthStatus, GetCurrentUser and the user model mapping:
// every backend outcome maps to its own result, and only a confirmed
// session rejection clears credentials.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_frontend/data/models/app_user_model.dart';
import 'package:mobile_frontend/data/repositories/auth_repository_placeholder.dart';
import 'package:mobile_frontend/domain/entities/app_user.dart';
import 'package:mobile_frontend/domain/errors/auth_exceptions.dart';
import 'package:mobile_frontend/domain/use_cases/check_auth_status.dart';
import 'package:mobile_frontend/domain/use_cases/get_current_user.dart';

import 'fakes.dart';

void main() {
  late FakeAuthRepository repo;

  setUp(() => repo = FakeAuthRepository(hasSession: true));

  group('CheckAuthStatus', () {
    test('no stored session → unauthenticated, backend not called', () async {
      repo.hasSession = false;
      expect(await CheckAuthStatus(repo)(), isA<AuthCheckUnauthenticated>());
      expect(repo.validateCalls, 0);
    });

    test('valid session → authenticated', () async {
      expect(await CheckAuthStatus(repo)(), isA<AuthCheckAuthenticated>());
    });

    test('expired/revoked → unauthenticated and credentials cleared', () async {
      repo.validateError = const SessionInvalidException();
      expect(await CheckAuthStatus(repo)(), isA<AuthCheckUnauthenticated>());
      expect(repo.clearCalls, 1);
    });

    test('blocked → blocked, credentials kept', () async {
      repo.validateError = const AccountBlockedException();
      expect(await CheckAuthStatus(repo)(), isA<AuthCheckBlocked>());
      expect(repo.clearCalls, 0);
    });

    test('server failure → service unavailable, session kept', () async {
      repo.validateError = const ServiceUnavailableException();
      expect(await CheckAuthStatus(repo)(), isA<AuthCheckServiceUnavailable>());
      expect(repo.clearCalls, 0);
    });

    test('no answer → service unavailable after timeout', () async {
      repo.validatePending = Completer<void>();
      final useCase = CheckAuthStatus(repo, timeout: Duration.zero);
      expect(await useCase(), isA<AuthCheckServiceUnavailable>());
    });

    test('unknown error → failure, never unauthenticated', () async {
      repo.validateError = StateError('surprise');
      expect(await CheckAuthStatus(repo)(), isA<AuthCheckFailure>());
      expect(repo.clearCalls, 0);
    });

    test('placeholder repository → unauthenticated (no backend yet)', () async {
      expect(
        await const CheckAuthStatus(AuthRepositoryPlaceholder())(),
        isA<AuthCheckUnauthenticated>(),
      );
    });
  });

  group('GetCurrentUser', () {
    test('valid profile → loaded with that user', () async {
      final result = await GetCurrentUser(repo)();
      expect((result as CurrentUserLoaded).user.id, testUser.id);
    });

    test('unauthorized → unauthorized and credentials cleared', () async {
      repo.userError = const SessionInvalidException();
      expect(await GetCurrentUser(repo)(), isA<CurrentUserUnauthorized>());
      expect(repo.clearCalls, 1);
    });

    test('blocked → blocked', () async {
      repo.userError = const AccountBlockedException();
      expect(await GetCurrentUser(repo)(), isA<CurrentUserBlocked>());
    });

    test('server error / timeout → unavailable, session kept', () async {
      repo.userError = const ProfileUnavailableException();
      expect(await GetCurrentUser(repo)(), isA<CurrentUserUnavailable>());
      repo.userError = const ServiceUnavailableException();
      expect(await GetCurrentUser(repo)(), isA<CurrentUserUnavailable>());

      repo.userError = null;
      repo.userPending = Completer<AppUser>();
      expect(
        await GetCurrentUser(repo, timeout: Duration.zero)(),
        isA<CurrentUserUnavailable>(),
      );
      expect(repo.clearCalls, 0);
    });

    test('malformed profile → invalid, no user produced', () async {
      repo.userError = const InvalidProfileException();
      expect(await GetCurrentUser(repo)(), isA<CurrentUserInvalid>());
    });

    test('unknown error → failure', () async {
      repo.userError = StateError('surprise');
      expect(await GetCurrentUser(repo)(), isA<CurrentUserFailure>());
      expect(repo.clearCalls, 0);
    });
  });

  group('AppUserModel.toEntity', () {
    test('maps a payload with an identifier', () {
      final user = const AppUserModel(id: ' u-7 ', role: 'captain').toEntity();
      expect(user.id, 'u-7');
      expect(user.role, 'captain');
    });

    test('rejects a missing or blank identifier', () {
      expect(
        () => const AppUserModel(displayName: 'No id').toEntity(),
        throwsA(isA<InvalidProfileException>()),
      );
      expect(
        () => const AppUserModel(id: '   ').toEntity(),
        throwsA(isA<InvalidProfileException>()),
      );
    });
  });
}
