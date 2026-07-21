import 'package:dartz/dartz.dart';
import 'package:here_sdk/mapview.dart' show HereMapController;

import '../../../../core/entities/geo_point.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/map_camera_position.dart';
import '../../domain/repositories/map_repository.dart';
import '../datasources/map_data_source.dart';

class MapRepositoryImpl implements MapRepository {
  final MapDataSource _dataSource;

  const MapRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, void>> loadInitialScene({
    required HereMapController controller,
    required MapCameraPosition initialCameraPosition,
  }) async {
    try {
      await _dataSource.loadScene(controller: controller);
      _dataSource.moveCamera(initialCameraPosition);
      return const Right(null);
    } on MapSceneLoadException catch (e) {
      return Left(MapFailure(e.message));
    } catch (e) {
      return Left(MapFailure('Unexpected error loading map scene: $e'));
    }
  }

  @override
  Either<Failure, void> moveCamera(MapCameraPosition position) {
    try {
      _dataSource.moveCamera(position);
      return const Right(null);
    } on MapSceneLoadException catch (e) {
      return Left(MapFailure(e.message));
    } catch (e) {
      return Left(MapFailure('Unexpected error moving camera: $e'));
    }
  }

  @override
  Either<Failure, void> showCurrentLocationMarker(MapCameraPosition position) {
    try {
      _dataSource.showCurrentLocationMarker(position);
      return const Right(null);
    } on MapSceneLoadException catch (e) {
      return Left(MapFailure(e.message));
    } catch (e) {
      return Left(MapFailure('Unexpected error showing location marker: $e'));
    }
  }

  @override
  Either<Failure, void> showRoute(List<GeoPoint> polyline) {
    try {
      _dataSource.showRoute(polyline);
      return const Right(null);
    } on MapSceneLoadException catch (e) {
      return Left(MapFailure(e.message));
    } catch (e) {
      return Left(MapFailure('Unexpected error drawing route: $e'));
    }
  }

  @override
  Either<Failure, void> clearRoute() {
    try {
      _dataSource.clearRoute();
      return const Right(null);
    } on MapSceneLoadException catch (e) {
      return Left(MapFailure(e.message));
    } catch (e) {
      return Left(MapFailure('Unexpected error clearing route: $e'));
    }
  }
}