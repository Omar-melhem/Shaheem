// State management for the captain's availability card on Home.

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/domain/entities/captain_availability.dart';
import 'package:mobile_frontend/domain/repositories/availability_permission_gateway.dart';
import 'package:mobile_frontend/domain/use_cases/captain_availability.dart';

part 'home_availability_state.dart';

/// Orchestrates the captain's availability for new order offers.
///
/// The toggle sends intents ([requestChange]); this Cubit decides what
/// happens. The displayed value is always the **server-confirmed** status
/// ([HomeAvailabilityState.confirmed]): never optimistic, never stored
/// locally, never derived from permissions.
///
/// Enabling, in order (stops at the first problem):
/// 1. a signed-in captain;
/// 2. the backend is reachable and configured (asked again; when it is not
///    configured, no permission is ever requested);
/// 3. device requirements checked without prompts; when some can be asked
///    for, an explanation is shown first ([pendingRationale]) and the
///    prompts only follow the captain's [continueAfterRationale];
/// 4. requirements checked again;
/// 5. the backend enable command; its answer is the new status.
///
/// Disabling asks no permission: it sends the disable command and shows
/// the server's answer. When a command's outcome is unknown, the last
/// confirmed status stays and an "unconfirmed" notice is shown.
///
/// Scoped to the Home route inside the main shell, so it is closed on
/// sign-out; late answers are dropped by a generation counter, by
/// [isClosed] and by the session check.
class HomeAvailabilityCubit extends Cubit<HomeAvailabilityState> {
  /// [hasSession] reports whether a real captain session exists right now
  /// (the shell passes the `AppSessionCubit` check).
  HomeAvailabilityCubit(
    this._getAvailability,
    this._changeAvailability,
    this._permissions,
    this._hasSession,
  ) : super(const HomeAvailabilityState());

  final GetCaptainAvailability _getAvailability;
  final ChangeCaptainAvailability _changeAvailability;
  final AvailabilityPermissionGateway _permissions;

  /// Whether a real captain session exists right now.
  final bool Function() _hasSession;

  /// Identifies the latest operation, so late answers to older work are
  /// dropped.
  int _generation = 0;

  /// Reads the server status (on opening Home, on returning to it from
  /// another tab, on resume and on retry).
  /// Never prompts. Ignored while other work is running.
  Future<void> load() async {
    if (state.isBusy || state.pendingRationale != null) return;
    if (!_requireSession()) return;
    final generation = ++_generation;
    emit(
      HomeAvailabilityState(
        confirmed: state.confirmed,
        activity: AvailabilityActivity.loading,
      ),
    );

    final result = await _getAvailability();
    if (_isStale(generation)) return;
    if (result is! AvailabilityConfirmed) {
      emit(
        HomeAvailabilityState(
          confirmed: result is AvailabilityNotConfigured
              ? null
              : state.confirmed,
          notice: _noticeForRead(result),
        ),
      );
      return;
    }
    if (result.availability == CaptainAvailability.unavailable) {
      emit(
        const HomeAvailabilityState(confirmed: CaptainAvailability.unavailable),
      );
      return;
    }

    // Confirmed Available: only check (no prompts) whether a requirement
    // was revoked meanwhile, and say so. The server decides the rest.
    final prerequisites = await _permissions.check();
    if (_isStale(generation)) return;
    emit(
      HomeAvailabilityState(
        confirmed: CaptainAvailability.available,
        notice: prerequisites.allGranted
            ? null
            : AvailabilityNoticeRequirementsLost(prerequisites.missing),
      ),
    );
  }

  /// The toggle's intent: [available] true asks to enable, false to
  /// disable. Ignored while work is running or an explanation is open.
  Future<void> requestChange(bool available) async {
    if (state.isBusy || state.pendingRationale != null) return;
    if (!_requireSession()) return;
    if (available) {
      await _enable();
    } else {
      await _disable();
    }
  }

  /// The captain accepted the explanation: show the system prompts, check
  /// again and, when everything is granted, ask the server.
  Future<void> continueAfterRationale() async {
    if (state.isBusy || state.pendingRationale == null) return;
    if (!_requireSession()) return;
    final generation = ++_generation;
    emit(
      HomeAvailabilityState(
        confirmed: state.confirmed,
        activity: AvailabilityActivity.requestingPermissions,
      ),
    );

    await _permissions.requestMissing();
    if (_isStale(generation)) return;
    // Always re-read: what the prompts returned is not trusted alone.
    final prerequisites = await _permissions.check();
    if (_isStale(generation)) return;
    if (prerequisites.allGranted) {
      await _submitEnable(generation);
      return;
    }
    emit(
      HomeAvailabilityState(
        confirmed: state.confirmed,
        notice: _missingNotice(prerequisites),
      ),
    );
  }

  /// The captain declined the explanation: nothing is requested and the
  /// status stays as it was.
  void dismissRationale() {
    final pending = state.pendingRationale;
    if (pending == null) return;
    emit(
      HomeAvailabilityState(
        confirmed: state.confirmed,
        notice: AvailabilityNoticeMissingRequirements(
          pending,
          settingsRequired: false,
        ),
      ),
    );
  }

  /// Opens the system settings; only from the captain's explicit tap.
  Future<void> openSettings() => _permissions.openSettings();

  Future<void> _enable() async {
    final generation = ++_generation;
    emit(
      HomeAvailabilityState(
        confirmed: state.confirmed,
        activity: AvailabilityActivity.checkingRequirements,
      ),
    );

    // Backend readiness first: no sensitive prompt for something that
    // cannot work.
    final readiness = await _getAvailability();
    if (_isStale(generation)) return;
    if (readiness is! AvailabilityConfirmed) {
      emit(
        HomeAvailabilityState(
          confirmed: readiness is AvailabilityNotConfigured
              ? null
              : state.confirmed,
          notice: _noticeForRead(readiness),
        ),
      );
      return;
    }
    if (readiness.availability == CaptainAvailability.available) {
      emit(
        const HomeAvailabilityState(confirmed: CaptainAvailability.available),
      );
      return;
    }

    final prerequisites = await _permissions.check();
    if (_isStale(generation)) return;
    const unavailable = CaptainAvailability.unavailable;
    if (prerequisites.allGranted) {
      await _submitEnable(generation);
    } else if (prerequisites.anyUnavailableInApp) {
      emit(
        const HomeAvailabilityState(
          confirmed: unavailable,
          notice: AvailabilityNoticePermissionsNotConfigured(),
        ),
      );
    } else if (prerequisites.anyRequestable) {
      // Wait for the captain to read why before any system prompt.
      emit(
        HomeAvailabilityState(
          confirmed: unavailable,
          pendingRationale: prerequisites.missing,
        ),
      );
    } else {
      emit(
        HomeAvailabilityState(
          confirmed: unavailable,
          notice: _missingNotice(prerequisites),
        ),
      );
    }
  }

  Future<void> _submitEnable(int generation) async {
    emit(
      HomeAvailabilityState(
        confirmed: state.confirmed,
        activity: AvailabilityActivity.enabling,
      ),
    );
    final result = await _changeAvailability(CaptainAvailability.available);
    if (_isStale(generation)) return;
    _emitCommandResult(result);
  }

  Future<void> _disable() async {
    final generation = ++_generation;
    emit(
      HomeAvailabilityState(
        confirmed: state.confirmed,
        activity: AvailabilityActivity.disabling,
      ),
    );
    final result = await _changeAvailability(CaptainAvailability.unavailable);
    if (_isStale(generation)) return;
    _emitCommandResult(result);
  }

  /// Shows a command's answer: the confirmed status, or the last confirmed
  /// one with a notice.
  void _emitCommandResult(AvailabilityResult result) {
    switch (result) {
      case AvailabilityConfirmed(:final availability):
        emit(HomeAvailabilityState(confirmed: availability));
      case AvailabilityRejected():
        emit(
          HomeAvailabilityState(
            confirmed: state.confirmed,
            notice: const AvailabilityNoticeRejected(),
          ),
        );
      case AvailabilityNotConfigured():
        emit(
          const HomeAvailabilityState(
            notice: AvailabilityNoticeNotConfigured(),
          ),
        );
      case AvailabilityNoInternet() || AvailabilityServiceUnavailable():
        emit(
          HomeAvailabilityState(
            confirmed: state.confirmed,
            notice: const AvailabilityNoticeUnconfirmed(),
          ),
        );
    }
  }

  AvailabilityNotice _noticeForRead(AvailabilityResult result) =>
      switch (result) {
        AvailabilityNotConfigured() => const AvailabilityNoticeNotConfigured(),
        AvailabilityNoInternet() => const AvailabilityNoticeNoInternet(),
        AvailabilityRejected() ||
        AvailabilityServiceUnavailable() ||
        AvailabilityConfirmed() => const AvailabilityNoticeServiceUnavailable(),
      };

  AvailabilityNotice _missingNotice(AvailabilityPrerequisites prerequisites) =>
      prerequisites.anyUnavailableInApp
      ? const AvailabilityNoticePermissionsNotConfigured()
      : AvailabilityNoticeMissingRequirements(
          prerequisites.missing,
          settingsRequired: prerequisites.anyNeedsSettings,
        );

  /// Emits the no-session state and returns false when nobody is signed in.
  bool _requireSession() {
    if (_hasSession()) return true;
    _generation++;
    emit(const HomeAvailabilityState(notice: AvailabilityNoticeNoSession()));
    return false;
  }

  /// Whether the answer for [generation] must be dropped. A lost session
  /// also clears what was shown.
  bool _isStale(int generation) {
    if (isClosed || generation != _generation) return true;
    if (!_hasSession()) {
      _requireSession();
      return true;
    }
    return false;
  }
}
