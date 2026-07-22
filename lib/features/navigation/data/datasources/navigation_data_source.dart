import 'dart:async';

import 'package:here_sdk/core.dart';
import 'package:here_sdk/location.dart';
import 'package:here_sdk/mapview.dart' show HereMapController;
import 'package:here_sdk/navigation.dart';
import 'package:here_sdk/routing.dart' as here_routing;

import '../../domain/entities/navigation_instruction.dart';

class NavigationStartException implements Exception {
  final String message;
  const NavigationStartException(this.message);

  @override
  String toString() => 'NavigationStartException: $message';
}

class NavigationDataSource {
  final here_routing.RoutingEngine _routingEngine;
  final LocationEngine _locationEngine;

  VisualNavigator? _visualNavigator;
  StreamController<NavigationInstruction>? _instructionStreamController;

  NavigationDataSource(this._routingEngine, this._locationEngine);

  Future<Stream<NavigationInstruction>> startNavigation({
    required HereMapController controller,
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    stopNavigation();

    final route = await _calculateRoute(
      originLatitude: originLatitude,
      originLongitude: originLongitude,
      destinationLatitude: destinationLatitude,
      destinationLongitude: destinationLongitude,
    );

    final visualNavigator = VisualNavigator();
    visualNavigator.startRendering(controller);

    final streamController =
    StreamController<NavigationInstruction>.broadcast();
    _instructionStreamController = streamController;

    visualNavigator.routeProgressListener = RouteProgressListener(
          (RouteProgress routeProgress) {
        final maneuverList = routeProgress.maneuverProgress;
        if (maneuverList.isEmpty) return;

        final nextManeuverProgress = maneuverList.first;
        final maneuver =
        visualNavigator.getManeuver(nextManeuverProgress.maneuverIndex);
        if (maneuver == null) return;

        streamController.add(
          NavigationInstruction(
            instructionText: maneuver.text,
            action: maneuver.action,
            distanceToNextManeuverInMeters:
            nextManeuverProgress.remainingDistanceInMeters,
            roadName:
            maneuver.roadTexts.names.getDefaultValue() ?? 'unnamed road',
          ),
        );
      },
    );

    visualNavigator.destinationReachedListener = DestinationReachedListener(
          () {
        streamController.add(
          const NavigationInstruction(
            instructionText: 'You have arrived at your destination.',
            action: here_routing.ManeuverAction.arrive,
            distanceToNextManeuverInMeters: 0,
            roadName: '',
            isArrival: true,
          ),
        );
      },
    );

    // Setting the route leaves tracking mode and starts turn-by-turn guidance
    visualNavigator.route = route;

    _locationEngine.confirmHEREPrivacyNoticeInclusion();
    _locationEngine.addLocationListener(visualNavigator);

    final startStatus =
    _locationEngine.startWithLocationAccuracy(LocationAccuracy.navigation);

    if (startStatus != LocationEngineStatus.engineStarted &&
        startStatus != LocationEngineStatus.alreadyStarted &&
        startStatus != LocationEngineStatus.ok) {
      _locationEngine.removeLocationListener(visualNavigator);
      visualNavigator.stopRendering();
      throw NavigationStartException(
        'Failed to start live location updates for navigation: $startStatus',
      );
    }

    _visualNavigator = visualNavigator;

    return streamController.stream;
  }

  void stopNavigation() {
    final visualNavigator = _visualNavigator;
    if (visualNavigator != null) {
      _locationEngine.removeLocationListener(visualNavigator);
    }
    _locationEngine.stop();

    _visualNavigator?.stopRendering();
    _visualNavigator = null;

    _instructionStreamController?.close();
    _instructionStreamController = null;
  }

  Future<here_routing.Route> _calculateRoute({
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
        if (error != null || routeList == null || routeList.isEmpty) {
          completer.completeError(
            NavigationStartException(
              'Could not calculate a route to navigate: $error',
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