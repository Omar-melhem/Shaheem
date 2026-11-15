// Availability orchestration (HomeAvailabilityCubit), its use cases, the
// honest placeholders and the JOD formatter. Backend and permissions are
// fakes here only.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_frontend/data/repositories/availability_permission_gateway_placeholder.dart';
import 'package:mobile_frontend/data/repositories/captain_availability_repository_placeholder.dart';
import 'package:mobile_frontend/domain/entities/captain_availability.dart';
import 'package:mobile_frontend/domain/errors/availability_exceptions.dart';
import 'package:mobile_frontend/domain/use_cases/captain_availability.dart';
import 'package:mobile_frontend/helper/money/jod_format.dart';
import 'package:mobile_frontend/view/screens/home_screen/cubit/home_availability_cubit.dart';

import 'availability_fakes.dart';

const available = CaptainAvailability.available;
const unavailable = CaptainAvailability.unavailable;

void main() {
  late FakeAvailabilityRepository repo;
  late FakePermissionGateway permissions;
  late bool session;

  HomeAvailabilityCubit build() => HomeAvailabilityCubit(
    GetCaptainAvailability(repo),
    ChangeCaptainAvailability(repo),
    permissions,
    () => session,
  );

  setUp(() {
    repo = FakeAvailabilityRepository();
    permissions = FakePermissionGateway(prerequisites());
    session = true;
  });

  group('load', () {
    test('starts unknown; load shows the server status', () async {
      final cubit = build();
      expect(cubit.state.confirmed, isNull);
      expect(cubit.state.isAvailable, isFalse);
      await cubit.load();
      expect(cubit.state.confirmed, unavailable);
      expect(cubit.state.notice, isNull);
      expect(permissions.checkCalls, 0);
    });

    test('backend not configured: notice, unknown status, no permission '
        'work at all', () async {
      repo.getError = const AvailabilityBackendNotConfiguredException();
      final cubit = build();
      await cubit.load();
      expect(cubit.state.notice, isA<AvailabilityNoticeNotConfigured>());
      expect(cubit.state.confirmed, isNull);
      expect(cubit.state.canChange, isFalse);
      await cubit.requestChange(true);
      expect(permissions.checkCalls, 0);
      expect(permissions.requestCalls, 0);
      expect(repo.setCalls, isEmpty);
    });

    test('no session: nothing is asked, nothing is claimed', () async {
      session = false;
      final cubit = build();
      await cubit.load();
      await cubit.requestChange(true);
      expect(cubit.state.notice, isA<AvailabilityNoticeNoSession>());
      expect(cubit.state.isAvailable, isFalse);
      expect(repo.getCalls, 0);
      expect(permissions.checkCalls, 0);
      expect(permissions.requestCalls, 0);
    });

    test(
      'offline and server failures keep the last confirmed status',
      () async {
        final cubit = build();
        await cubit.load();
        repo.getError = const AvailabilityNetworkUnavailableException();
        await cubit.load();
        expect(cubit.state.notice, isA<AvailabilityNoticeNoInternet>());
        expect(cubit.state.confirmed, unavailable);
        repo.getError = const AvailabilityServiceUnavailableException();
        await cubit.load();
        expect(cubit.state.notice, isA<AvailabilityNoticeServiceUnavailable>());
      },
    );

    test('resume while Available with a revoked permission: warns, never '
        'prompts, never switches off by itself', () async {
      repo.status = available;
      permissions.current = prerequisites(
        overrides: {
          AvailabilityRequirement.backgroundLocation: RequirementStatus.denied,
        },
      );
      final cubit = build();
      await cubit.load();
      expect(cubit.state.confirmed, available);
      final notice = cubit.state.notice;
      expect(notice, isA<AvailabilityNoticeRequirementsLost>());
      expect((notice! as AvailabilityNoticeRequirementsLost).missing, [
        AvailabilityRequirement.backgroundLocation,
      ]);
      expect(permissions.requestCalls, 0);
      expect(repo.setCalls, isEmpty);
    });
  });

  group('enable', () {
    test(
      'all granted: no prompt, Available only after the server confirms',
      () async {
        final pending = Completer<CaptainAvailability>();
        repo.setPending = pending;
        final cubit = build();
        await cubit.load();

        final enabling = cubit.requestChange(true);
        await pumpEventQueue();
        // The command is out: still not Available (never optimistic).
        expect(repo.setCalls, [available]);
        expect(cubit.state.activity, AvailabilityActivity.enabling);
        expect(cubit.state.isAvailable, isFalse);
        expect(cubit.state.confirmed, unavailable);

        pending.complete(available);
        await enabling;
        expect(cubit.state.isAvailable, isTrue);
        expect(permissions.requestCalls, 0);
      },
    );

    test(
      'first time: explanation first, prompts only after continue',
      () async {
        permissions.current = prerequisites(
          base: RequirementStatus.notDetermined,
        );
        permissions.afterRequest = prerequisites();
        final cubit = build();
        await cubit.load();

        await cubit.requestChange(true);
        expect(cubit.state.pendingRationale, AvailabilityRequirement.values);
        expect(permissions.requestCalls, 0);
        expect(repo.setCalls, isEmpty);
        // While the explanation is open, further intents are ignored.
        await cubit.requestChange(true);
        expect(permissions.requestCalls, 0);

        await cubit.continueAfterRationale();
        expect(permissions.requestCalls, 1);
        expect(repo.setCalls, [available]);
        expect(cubit.state.isAvailable, isTrue);
      },
    );

    test('declining the explanation requests nothing', () async {
      permissions.current = prerequisites(
        base: RequirementStatus.notDetermined,
      );
      final cubit = build();
      await cubit.load();
      await cubit.requestChange(true);
      cubit.dismissRationale();
      expect(cubit.state.pendingRationale, isNull);
      expect(permissions.requestCalls, 0);
      expect(cubit.state.isAvailable, isFalse);
      expect(cubit.state.notice, isA<AvailabilityNoticeMissingRequirements>());
    });

    for (final requirement in AvailabilityRequirement.values) {
      test('$requirement denied at the prompt: stays not Available', () async {
        permissions.current = prerequisites(
          overrides: {requirement: RequirementStatus.notDetermined},
        );
        permissions.afterRequest = prerequisites(
          overrides: {requirement: RequirementStatus.denied},
        );
        final cubit = build();
        await cubit.load();
        await cubit.requestChange(true);
        await cubit.continueAfterRationale();
        final notice = cubit.state.notice;
        expect(notice, isA<AvailabilityNoticeMissingRequirements>());
        final missing = notice! as AvailabilityNoticeMissingRequirements;
        expect(missing.missing, [requirement]);
        expect(missing.settingsRequired, isFalse);
        expect(cubit.state.isAvailable, isFalse);
        expect(repo.setCalls, isEmpty);
      });
    }

    final settingsCases = {
      'background location permanently denied': {
        AvailabilityRequirement.backgroundLocation:
            RequirementStatus.permanentlyDenied,
      },
      'location service off': {
        AvailabilityRequirement.locationService:
            RequirementStatus.serviceDisabled,
      },
      'notifications only provisional': {
        AvailabilityRequirement.notifications: RequirementStatus.provisional,
      },
      'notifications permanently denied': {
        AvailabilityRequirement.notifications:
            RequirementStatus.permanentlyDenied,
      },
    };
    for (final MapEntry(key: name, value: overrides) in settingsCases.entries) {
      test('$name: no prompt, Settings offered (opened only on tap)', () async {
        permissions.current = prerequisites(overrides: overrides);
        final cubit = build();
        await cubit.load();
        await cubit.requestChange(true);
        expect(cubit.state.pendingRationale, isNull);
        final notice = cubit.state.notice;
        expect(notice, isA<AvailabilityNoticeMissingRequirements>());
        expect(
          (notice! as AvailabilityNoticeMissingRequirements).settingsRequired,
          isTrue,
        );
        expect(permissions.requestCalls, 0);
        expect(permissions.settingsCalls, 0);
        expect(repo.setCalls, isEmpty);
        await cubit.openSettings();
        expect(permissions.settingsCalls, 1);
      });
    }

    test(
      'restricted by device policy: stays not Available, no prompt',
      () async {
        permissions.current = prerequisites(
          overrides: {
            AvailabilityRequirement.preciseLocation:
                RequirementStatus.restricted,
          },
        );
        final cubit = build();
        await cubit.load();
        await cubit.requestChange(true);
        expect(cubit.state.isAvailable, isFalse);
        expect(permissions.requestCalls, 0);
        expect(repo.setCalls, isEmpty);
      },
    );

    test('permissions not configured in this build: honest notice', () async {
      permissions.current = prerequisites(
        base: RequirementStatus.notConfigured,
      );
      final cubit = build();
      await cubit.load();
      await cubit.requestChange(true);
      expect(
        cubit.state.notice,
        isA<AvailabilityNoticePermissionsNotConfigured>(),
      );
      expect(permissions.requestCalls, 0);
      expect(repo.setCalls, isEmpty);
    });

    test('server refuses: not Available, rejected notice', () async {
      repo.setError = const AvailabilityRejectedException();
      final cubit = build();
      await cubit.load();
      await cubit.requestChange(true);
      expect(cubit.state.isAvailable, isFalse);
      expect(cubit.state.notice, isA<AvailabilityNoticeRejected>());
    });

    test(
      'server confirms a different status than requested: shown as is',
      () async {
        repo.confirm = (_) => unavailable;
        final cubit = build();
        await cubit.load();
        await cubit.requestChange(true);
        expect(cubit.state.confirmed, unavailable);
      },
    );

    test('command failure: outcome unknown, never Available', () async {
      repo.setError = const AvailabilityServiceUnavailableException();
      final cubit = build();
      await cubit.load();
      await cubit.requestChange(true);
      expect(cubit.state.isAvailable, isFalse);
      expect(cubit.state.confirmed, unavailable);
      expect(cubit.state.notice, isA<AvailabilityNoticeUnconfirmed>());
    });

    test('rapid double tap sends one command', () async {
      final pending = Completer<CaptainAvailability>();
      repo.setPending = pending;
      final cubit = build();
      await cubit.load();
      final first = cubit.requestChange(true);
      final second = cubit.requestChange(true);
      await pumpEventQueue();
      unawaited(cubit.requestChange(true));
      pending.complete(available);
      await Future.wait([first, second]);
      expect(repo.setCalls, [available]);
      expect(permissions.checkCalls, 1);
    });

    test(
      'sign-out during the command: answer dropped, status cleared',
      () async {
        final pending = Completer<CaptainAvailability>();
        repo.setPending = pending;
        final cubit = build();
        await cubit.load();
        final enabling = cubit.requestChange(true);
        await pumpEventQueue();
        session = false;
        pending.complete(available);
        await enabling;
        expect(cubit.state.isAvailable, isFalse);
        expect(cubit.state.confirmed, isNull);
        expect(cubit.state.notice, isA<AvailabilityNoticeNoSession>());
      },
    );

    test('closed during the command (shell left): no error, no emit', () async {
      final pending = Completer<CaptainAvailability>();
      repo.setPending = pending;
      final cubit = build();
      await cubit.load();
      final enabling = cubit.requestChange(true);
      await pumpEventQueue();
      await cubit.close();
      pending.complete(available);
      await enabling;
      expect(cubit.isClosed, isTrue);
    });
  });

  group('disable', () {
    setUp(() => repo.status = available);

    test('no permission work; not Available only after confirmation', () async {
      final pending = Completer<CaptainAvailability>();
      final cubit = build();
      await cubit.load();
      final checksAfterLoad = permissions.checkCalls;
      repo.setPending = pending;

      final disabling = cubit.requestChange(false);
      await pumpEventQueue();
      expect(cubit.state.activity, AvailabilityActivity.disabling);
      expect(cubit.state.confirmed, available);
      pending.complete(unavailable);
      await disabling;
      expect(cubit.state.confirmed, unavailable);
      expect(permissions.checkCalls, checksAfterLoad);
      expect(permissions.requestCalls, 0);
    });

    test(
      'failure: last confirmed Available is kept and marked unconfirmed',
      () async {
        final cubit = build();
        await cubit.load();
        repo.setError = const AvailabilityNetworkUnavailableException();
        await cubit.requestChange(false);
        expect(cubit.state.confirmed, available);
        expect(cubit.state.notice, isA<AvailabilityNoticeUnconfirmed>());
      },
    );
  });

  group('use cases', () {
    test('map each failure; anything else is unknown, never success', () async {
      final get = GetCaptainAvailability(repo);
      final cases = <Object, Type>{
        const AvailabilityBackendNotConfiguredException():
            AvailabilityNotConfigured,
        const AvailabilityNetworkUnavailableException(): AvailabilityNoInternet,
        const AvailabilityServiceUnavailableException():
            AvailabilityServiceUnavailable,
        const AvailabilityRejectedException(): AvailabilityRejected,
        StateError('boom'): AvailabilityServiceUnavailable,
      };
      for (final MapEntry(key: error, value: type) in cases.entries) {
        repo.getError = error;
        expect((await get()).runtimeType, type);
      }
    });

    test('a hanging server times out as an unknown outcome', () async {
      repo.setPending = Completer<CaptainAvailability>();
      final change = ChangeCaptainAvailability(
        repo,
        timeout: const Duration(milliseconds: 10),
      );
      expect(await change(available), isA<AvailabilityServiceUnavailable>());
    });
  });

  group('placeholders shipped in the app', () {
    test('availability backend: not configured, never a status', () async {
      const placeholder = CaptainAvailabilityRepositoryPlaceholder();
      expect(
        placeholder.getAvailability,
        throwsA(isA<AvailabilityBackendNotConfiguredException>()),
      );
      expect(
        () => placeholder.setAvailability(available),
        throwsA(isA<AvailabilityBackendNotConfiguredException>()),
      );
    });

    test(
      'permissions: every requirement not configured, nothing opens',
      () async {
        const placeholder = AvailabilityPermissionGatewayPlaceholder();
        for (final result in [
          await placeholder.check(),
          await placeholder.requestMissing(),
        ]) {
          expect(result.allGranted, isFalse);
          expect(result.anyUnavailableInApp, isTrue);
          for (final r in AvailabilityRequirement.values) {
            expect(result.status(r), RequirementStatus.notConfigured);
          }
        }
        expect(await placeholder.openSettings(), isFalse);
      },
    );

    test('an unchecked requirement never counts as granted', () {
      const partial = AvailabilityPrerequisites({
        AvailabilityRequirement.preciseLocation: RequirementStatus.granted,
      });
      expect(partial.allGranted, isFalse);
      expect(
        partial.status(AvailabilityRequirement.notifications),
        RequirementStatus.notConfigured,
      );
    });
  });

  group('formatJodFils (integer only)', () {
    test('three decimals, grouping and sign', () {
      expect(formatJodFils(0), '0.000');
      expect(formatJodFils(5), '0.005');
      expect(formatJodFils(1000), '1.000');
      expect(formatJodFils(500), '0.500');
      expect(formatJodFils(12345678), '12,345.678');
      expect(formatJodFils(-1), '-0.001');
      expect(formatJodFils(-1000), '-1.000');
      expect(formatJodFils(-1234567890), '-1,234,567.890');
      expect(formatJodFils(9223372036854775807), '9,223,372,036,854,775.807');
      expect(formatJodFils(-9223372036854775808), '-9,223,372,036,854,775.808');
    });

    test('ltrIsolate wraps with LRI/PDI', () {
      expect(ltrIsolate('-1.000'), '\u2066-1.000\u2069');
    });
  });
}
