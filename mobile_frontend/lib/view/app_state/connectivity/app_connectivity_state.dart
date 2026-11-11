part of 'app_connectivity_cubit.dart';

/// App-wide internet reachability as last observed.
///
/// [status] is the latest known result; [isChecking] is true while an
/// explicit check runs. They are separate so the UI can keep showing the
/// last known status (e.g. the offline banner) while a retry is in flight.
@immutable
final class AppConnectivityState {
  const AppConnectivityState({
    this.status = InternetReachability.unknown,
    this.isChecking = false,
  });

  final InternetReachability status;
  final bool isChecking;

  /// Confirmed offline. A failed or unknown check is not "offline".
  bool get isDisconnected => status == InternetReachability.disconnected;

  AppConnectivityState copyWith({
    InternetReachability? status,
    bool? isChecking,
  }) => AppConnectivityState(
    status: status ?? this.status,
    isChecking: isChecking ?? this.isChecking,
  );
}
