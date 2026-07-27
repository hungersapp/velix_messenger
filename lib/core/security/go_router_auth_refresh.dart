import 'dart:async';

import 'package:flutter/foundation.dart';

/// Notifies [GoRouter] when [stream] emits so [redirect] re-runs.
class GoRouterAuthRefresh extends ChangeNotifier {
  GoRouterAuthRefresh(Stream<dynamic> stream) {
    _subscription = stream.listen(
      (_) => notifyListeners(),
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('GoRouterAuthRefresh stream error: $error\n$stackTrace');
      },
      cancelOnError: false,
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
