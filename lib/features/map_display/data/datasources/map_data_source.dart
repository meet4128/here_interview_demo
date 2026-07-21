import 'dart:async';
import 'dart:ui' as ui;

import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';

import '../../../../core/entities/geo_point.dart';
import '../../domain/entities/map_camera_position.dart';

class MapSceneLoadException implements Exception {
  final String message;
  const MapSceneLoadException(this.message);

  @override
  String toString() => 'MapSceneLoadException: $message';
}

class MapDataSource {
  HereMapController? _controller;
  LocationIndicator? _locationIndicator;
  MapPolyline? _routePolyline;

  Future<void> loadScene({
    required HereMapController controller,
    MapScheme scheme = MapScheme.normalDay,
  }) {
    _controller = controller;
    final completer = Completer<void>();

    controller.mapScene.loadSceneForMapScheme(scheme, (MapError? error) {
      if (error != null) {
        completer.completeError(
          MapSceneLoadException('Map scene not loaded: ${error.toString()}'),
        );
      } else {
        completer.complete();
      }
    });

    return completer.future;
  }

  /// Moves the camera to [position]
  void moveCamera(MapCameraPosition position) {
    final controller = _requireController();
    final geoCoordinates = GeoCoordinates(position.latitude, position.longitude);
    final mapMeasure = MapMeasure(
      MapMeasureKind.distanceInMeters,
      position.distanceToEarthInMeters,
    );
    controller.camera.lookAtPointWithMeasure(geoCoordinates, mapMeasure);
  }

  /// Shows (or moves) a marker at [position] representing the device's current location
  void showCurrentLocationMarker(MapCameraPosition position) {
    final controller = _requireController();

    final indicator = _locationIndicator ??= LocationIndicator();
    indicator.enable(controller);

    final geoCoordinates = GeoCoordinates(position.latitude, position.longitude);
    indicator.updateLocation(Location.withCoordinates(geoCoordinates));
  }

  /// Draws [polyline] as a route line on the map
  void showRoute(List<GeoPoint> polyline) {
    final controller = _requireController();

    _removeExistingRoutePolyline(controller);

    final geoCoordinates = polyline
        .map((point) => GeoCoordinates(point.latitude, point.longitude))
        .toList();
    final geoPolyline = GeoPolyline(geoCoordinates);

    final representation = MapPolylineSolidRepresentation(
      MapMeasureDependentRenderSize.withSingleSize(RenderSizeUnit.pixels, 12),
      const ui.Color(0xFF1F8A82), // route-teal, matches the guide's own accent
      LineCap.round,
    );

    final mapPolyline = MapPolyline.withRepresentation(geoPolyline, representation);
    controller.mapScene.addMapPolyline(mapPolyline);
    _routePolyline = mapPolyline;
  }

  /// Removes a previously drawn route
  void clearRoute() {
    final controller = _requireController();
    _removeExistingRoutePolyline(controller);
  }

  void _removeExistingRoutePolyline(HereMapController controller) {
    final existing = _routePolyline;
    if (existing != null) {
      controller.mapScene.removeMapPolyline(existing);
      _routePolyline = null;
    }
  }

  HereMapController _requireController() {
    final controller = _controller;
    if (controller == null) {
      throw const MapSceneLoadException(
        'Called before loadScene completed — no controller attached.',
      );
    }
    return controller;
  }
}