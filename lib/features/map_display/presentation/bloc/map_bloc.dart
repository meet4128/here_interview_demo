import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/location/location_repository.dart';
import '../../domain/entities/map_camera_position.dart';
import '../../domain/repositories/map_repository.dart';
import 'map_event.dart';
import 'map_state.dart';

const _defaultCameraPosition = MapCameraPosition(
  latitude: 52.530932,
  longitude: 13.384915,
);

class MapBloc extends Bloc<MapEvent, MapState> {
  final MapRepository _mapRepository;
  final LocationRepository _locationRepository;

  MapCameraPosition _resolvedInitialPosition = _defaultCameraPosition;
  MapCameraPosition get deviceLocation => _resolvedInitialPosition;

  MapBloc({
    required MapRepository mapRepository,
    required LocationRepository locationRepository,
  })  : _mapRepository = mapRepository,
        _locationRepository = locationRepository,
        super(const MapInitial()) {
    on<MapLocationRequested>(_onMapLocationRequested);
    on<MapLocationSettingsRequested>(_onMapLocationSettingsRequested);
    on<MapStarted>(_onMapStarted);
    on<MapCameraMoveRequested>(_onMapCameraMoveRequested);
    on<MapRouteDrawRequested>(_onMapRouteDrawRequested);
    on<MapRouteCleared>(_onMapRouteCleared);
  }

  Future<void> _onMapLocationRequested(
      MapLocationRequested event,
      Emitter<MapState> emit,
      ) async {
    emit(const MapLocationLoading());

    final result = await _locationRepository.getCurrentPosition();

    result.fold(
          (failure) {
        if (failure is LocationServicesDisabledFailure) {
          emit(const MapLocationServiceDisabled());
          return;
        }
        debugPrint('MapBloc: location resolution failed — ${failure.message}');
        _resolvedInitialPosition = _defaultCameraPosition;
        emit(MapLocationReady(_resolvedInitialPosition));
      },
          (devicePosition) {
        _resolvedInitialPosition = MapCameraPosition(
          latitude: devicePosition.latitude,
          longitude: devicePosition.longitude,
        );
        emit(MapLocationReady(_resolvedInitialPosition));
      },
    );
  }

  Future<void> _onMapLocationSettingsRequested(
      MapLocationSettingsRequested event,
      Emitter<MapState> emit,
      ) async {
    await _locationRepository.openLocationSettings();
  }

  Future<void> _onMapStarted(MapStarted event, Emitter<MapState> emit) async {
    emit(const MapSceneLoading());

    final result = await _mapRepository.loadInitialScene(
      controller: event.controller,
      initialCameraPosition: _resolvedInitialPosition,
    );

    result.fold(
          (failure) => emit(MapError(failure.message)),
          (_) {
        _mapRepository.showCurrentLocationMarker(_resolvedInitialPosition);
        emit(MapReady(_resolvedInitialPosition));
      },
    );
  }

  void _onMapCameraMoveRequested(
      MapCameraMoveRequested event,
      Emitter<MapState> emit,
      ) {
    final result = _mapRepository.moveCamera(event.position);

    result.fold(
          (failure) => emit(MapError(failure.message)),
          (_) => emit(MapReady(event.position)),
    );
  }

  void _onMapRouteDrawRequested(
      MapRouteDrawRequested event,
      Emitter<MapState> emit,
      ) {
    final result = _mapRepository.showRoute(event.polyline);
    result.fold(
          (failure) =>
          debugPrint('MapBloc: failed to draw route — ${failure.message}'),
          (_) {},
    );
  }

  void _onMapRouteCleared(MapRouteCleared event, Emitter<MapState> emit) {
    final result = _mapRepository.clearRoute();
    result.fold(
          (failure) =>
          debugPrint('MapBloc: failed to clear route — ${failure.message}'),
          (_) {},
    );
  }
}