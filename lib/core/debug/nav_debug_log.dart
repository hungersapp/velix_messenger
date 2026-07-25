import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Debug-only navigation / lifecycle logger. Do not use for production logic.
void navLog(
  String screen,
  String event, [
  Map<String, Object?>? data,
]) {
  final buffer = StringBuffer('[VELIX_NAV][$screen] $event');
  if (data != null && data.isNotEmpty) {
    buffer.write(' | ');
    buffer.write(
      data.entries.map((e) => '${e.key}=${e.value}').join(', '),
    );
  }
  debugPrint(buffer.toString());
}

String goRouterLocationOf(BuildContext context) {
  try {
    return GoRouter.of(context).state.uri.toString();
  } catch (_) {
    return 'unavailable';
  }
}

String routeLabel(Route<dynamic>? route) {
  if (route == null) return 'null';
  final name = route.settings.name;
  if (name != null && name.isNotEmpty) return name;
  return route.settings.toString();
}

/// Logs Navigator stack push/pop/replace/remove operations.
class VelixNavObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    navLog('Navigator', 'didPush', {
      'route': routeLabel(route),
      'previous': routeLabel(previousRoute),
    });
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    navLog('Navigator', 'didPop', {
      'route': routeLabel(route),
      'previous': routeLabel(previousRoute),
    });
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    navLog('Navigator', 'didRemove', {
      'route': routeLabel(route),
      'previous': routeLabel(previousRoute),
    });
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    navLog('Navigator', 'didReplace', {
      'newRoute': routeLabel(newRoute),
      'oldRoute': routeLabel(oldRoute),
    });
  }
}
