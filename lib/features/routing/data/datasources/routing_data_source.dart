import 'dart:async';

import 'package:here_sdk/core.dart';
import 'package:here_sdk/routing.dart' as here_routing;

class RoutingQueryException implements Exception {
  final String message;
  const RoutingQueryException(this.message);

  @override
  String toString() => 'RoutingQueryException: $message';
}

class RoutingNoRouteFoundException implements Exception {
  final String message;
  const RoutingNoRouteFoundException(this.message);

  @override
  String toString() => 'RoutingNoRouteFoundException: $message';
}

class RoutingDataSource {
  final here_routing.RoutingEngine _routingEngine;

  const RoutingDataSource(this._routingEngine);

  Future<here_routing.Route> calculateCarRoute({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) {
    final completer = Completer<here_routing.Route>();

    final waypoints = [
      here_routing.Waypoint(GeoCoordinates(originLatitude, originLongitude)),
      here_routing.Waypoint(
        GeoCoordinates(destinationLatitude, destinationLongitude),
      ),
    ];

    _routingEngine.calculateRouteWithRoutingOptions(
      waypoints,
      here_routing.RoutingOptions(),
          (here_routing.RoutingError? error, List<here_routing.Route>? routeList) {
        if (error == here_routing.RoutingError.noRouteFound) {
          completer.completeError(
            const RoutingNoRouteFoundException(
              'No route could be found between these two points.',
            ),
          );
          return;
        }
        if (error != null) {
          completer.completeError(
            RoutingQueryException('Route calculation failed: $error'),
          );
          return;
        }
        if (routeList == null || routeList.isEmpty) {
          completer.completeError(
            const RoutingNoRouteFoundException(
              'No route could be found between these two points.',
            ),
          );
          return;
        }
        completer.complete(routeList.first);
      },
    );

    return completer.future;
  }
}