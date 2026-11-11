// Bridges Cubit streams to go_router's refresh mechanism.

import 'dart:async';

import 'package:flutter/foundation.dart';

/// Notifies listeners whenever any of [streams] emits.
///
/// Passed to `GoRouter.refreshListenable` so redirects re-run when startup
/// or session state changes. The owner must call [dispose].
class StreamRefreshListenable extends ChangeNotifier {
  StreamRefreshListenable(List<Stream<Object?>> streams) {
    _subscriptions = [
      for (final stream in streams) stream.listen((_) => notifyListeners()),
    ];
  }

  late final List<StreamSubscription<Object?>> _subscriptions;

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
