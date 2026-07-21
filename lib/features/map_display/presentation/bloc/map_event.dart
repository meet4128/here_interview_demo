import 'package:equatable/equatable.dart';
import 'package:here_sdk/mapview.dart' show HereMapController;

import '../../../../core/entities/geo_point.dart';
import '../../domain/entities/map_camera_position.dart';

abstract class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object?> get props => [];
}

class MapLocationRequested extends MapEvent {
  const MapLocationRequested();
}

class MapLocationSettingsRequested extends MapEvent {
  const MapLocationSettingsRequested();
}

class MapStarted extends MapEvent {
  final HereMapController controller;

  const MapStarted(this.controller);

  @override
  List<Object?> get props => [controller];
}

class MapCameraMoveRequested extends MapEvent {
  final MapCameraPosition position;

  const MapCameraMoveRequested(this.position);

  @override
  List<Object?> get props => [position];
}

class MapRouteDrawRequested extends MapEvent {
  final List<GeoPoint> polyline;

  const MapRouteDrawRequested(this.polyline);

  @override
  List<Object?> get props => [polyline];
}

class MapRouteCleared extends MapEvent {
  const MapRouteCleared();
}