import 'dart:async';

import 'package:flutter/foundation.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscriptions = [stream.asBroadcastStream().listen(_onEvent)];
  }

  GoRouterRefreshStream.multiple(Iterable<Stream<dynamic>> streams) {
    _subscriptions = [
      for (final stream in streams)
        stream.asBroadcastStream().listen(_onEvent),
    ];
  }

  late final List<StreamSubscription<dynamic>> _subscriptions;

  void _onEvent(dynamic _) {
    notifyListeners();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
