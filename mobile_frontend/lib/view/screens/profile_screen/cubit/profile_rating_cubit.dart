// State management for the Profile rating card (D-A77).

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/domain/entities/captain_account.dart';
import 'package:mobile_frontend/domain/use_cases/captain_account.dart';

/// What the rating card can show.
enum ProfileRatingStatus {
  initial,
  loading,

  /// No signed-in captain (debug preview): nothing is read.
  noSession,

  /// No rating backend is connected; nothing was read («غير متوفر»).
  notConfigured,
  noInternet,
  failure,

  /// The server answered; [ProfileRatingState.rating] may still say "no
  /// ratings yet".
  loaded,
}

/// The rating card's state: the server's last answer, never a stand-in.
class ProfileRatingState {
  const ProfileRatingState({
    this.status = ProfileRatingStatus.initial,
    this.rating,
  });

  final ProfileRatingStatus status;

  /// Only when [status] is loaded.
  final CaptainRating? rating;

  /// Whether a Retry makes sense.
  bool get canRetry =>
      status == ProfileRatingStatus.noInternet ||
      status == ProfileRatingStatus.failure;
}

/// Reads the captain's rating for the «حسابي» tab. Scoped to the Profile
/// branch (closed on sign-out); late answers after a newer load, a
/// sign-out ([hasSession] false) or [close] are dropped. Name and phone are
/// not here: they come from `AppSessionCubit` (no second user store).
class ProfileRatingCubit extends Cubit<ProfileRatingState> {
  ProfileRatingCubit(this._getRating, this._hasSession)
    : super(const ProfileRatingState());

  final GetCaptainRating _getRating;

  /// Whether a real captain session exists right now.
  final bool Function() _hasSession;

  int _generation = 0;

  /// Reads the rating. Ignored while a read is running.
  Future<void> load() async {
    if (state.status == ProfileRatingStatus.loading) return;
    if (!_hasSession()) {
      _generation++;
      emit(const ProfileRatingState(status: ProfileRatingStatus.noSession));
      return;
    }
    final generation = ++_generation;
    emit(const ProfileRatingState(status: ProfileRatingStatus.loading));
    final result = await _getRating();
    if (isClosed || generation != _generation) return;
    if (!_hasSession()) {
      emit(const ProfileRatingState(status: ProfileRatingStatus.noSession));
      return;
    }
    emit(switch (result) {
      RatingLoaded(:final rating) => ProfileRatingState(
        status: ProfileRatingStatus.loaded,
        rating: rating,
      ),
      RatingNotConfigured() => const ProfileRatingState(
        status: ProfileRatingStatus.notConfigured,
      ),
      RatingNoInternet() => const ProfileRatingState(
        status: ProfileRatingStatus.noInternet,
      ),
      RatingFailure() => const ProfileRatingState(
        status: ProfileRatingStatus.failure,
      ),
    });
  }
}
