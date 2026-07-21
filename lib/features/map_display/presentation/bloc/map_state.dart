import 'package:equatable/equatable.dart';

import '../../domain/entities/map_camera_position.dart';

abstract class MapState extends Equatable {
  const MapState();

  @override
  List<Object?> get props => [];
}

class MapInitial extends MapState {
  const MapInitial();
}

/// Requesting location permission
class MapLocationLoading extends MapState {
  const MapLocationLoading();
}

class MapLocationReady extends MapState {
  final MapCameraPosition initialCameraPosition;

  const MapLocationReady(this.initialCameraPosition);

  @override
  List<Object?> get props => [initialCameraPosition];
}

class MapLocationServiceDisabled extends MapState {
  const MapLocationServiceDisabled();
}

class MapSceneLoading extends MapState {
  const MapSceneLoading();
}

class MapReady extends MapState {
  final MapCameraPosition currentPosition;

  const MapReady(this.currentPosition);

  @override
  List<Object?> get props => [currentPosition];
}

class MapError extends MapState {
  final String message;

  const MapError(this.message);

  @override
  List<Object?> get props => [message];
}