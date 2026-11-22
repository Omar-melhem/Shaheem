// State management for the account-deletion flow in Settings (D-A78).

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/domain/use_cases/captain_account.dart';

/// Where the deletion flow is. Every value after [notSent] is the answer to
/// one confirmed submission; none of them is assumed.
enum AccountDeletionFlow {
  /// Nothing was sent (the start state, and after Cancel).
  notSent,

  /// The confirmed request is being sent; repeated submissions are ignored.
  submitting,

  /// No deletion backend is connected; nothing was sent or deleted.
  notConfigured,

  /// Offline; nothing was sent. Retry is allowed.
  noInternet,

  /// The server failed; nothing is assumed deleted. Retry is allowed.
  failure,

  /// No answer in time (R04): the request may have reached the server.
  /// Not deleted, not "not sent"; no further submission from this screen
  /// (a new visit to Settings starts a new flow).
  unconfirmed,

  /// The server asks for a fresh sign-in first.
  reauthenticationRequired,

  /// Accepted and being processed: **not** deleted yet.
  pending,

  /// The server confirmed the deletion; the session is being ended.
  completed,
}

/// Runs the deletion request only after the captain confirmed it, once.
///
/// On a server-confirmed completion it calls [onCompleted], which the
/// route wires to `AppSessionCubit.endSession()`: that clears the stored
/// credentials and the in-memory user, the router redirects to Login (no
/// protected Back path remains), and every per-user scope (the shell's
/// Cubits, the active-order owner) is closed or reset. A pending answer
/// keeps the session: when access ends is the server contract's decision
/// (D-P39), not this app's. [onReauthenticate] (the same session end)
/// leads to the real Login flow.
class AccountDeletionCubit extends Cubit<AccountDeletionFlow> {
  AccountDeletionCubit(
    this._requestDeletion, {
    required this.onCompleted,
    required this.onReauthenticate,
  }) : super(AccountDeletionFlow.notSent);

  final RequestAccountDeletion _requestDeletion;

  /// Ends the session after a confirmed deletion.
  final Future<void> Function() onCompleted;

  /// Ends the session so the captain can sign in again.
  final Future<void> Function() onReauthenticate;

  /// Whether a new confirmed submission may start now.
  bool get canSubmit => switch (state) {
    AccountDeletionFlow.notSent ||
    AccountDeletionFlow.noInternet ||
    AccountDeletionFlow.failure => true,
    _ => false,
  };

  /// Sends the request. Call only after the captain's explicit
  /// confirmation; ignored while sending, after a pending or completed
  /// answer, and when no backend exists.
  Future<void> submitConfirmed() async {
    if (!canSubmit) return;
    emit(AccountDeletionFlow.submitting);
    final result = await _requestDeletion();
    if (isClosed) return;
    switch (result) {
      case AccountDeletionPending():
        emit(AccountDeletionFlow.pending);
      case AccountDeletionCompleted():
        emit(AccountDeletionFlow.completed);
        await onCompleted();
      case AccountDeletionNotConfigured():
        emit(AccountDeletionFlow.notConfigured);
      case AccountDeletionNoInternet():
        emit(AccountDeletionFlow.noInternet);
      case AccountDeletionFailure():
        emit(AccountDeletionFlow.failure);
      case AccountDeletionUnconfirmed():
        emit(AccountDeletionFlow.unconfirmed);
      case AccountDeletionReauthenticationRequired():
        emit(AccountDeletionFlow.reauthenticationRequired);
    }
  }

  /// Starts the real sign-in flow again (after "reauthentication required").
  Future<void> reauthenticate() async {
    if (state != AccountDeletionFlow.reauthenticationRequired) return;
    await onReauthenticate();
  }
}
