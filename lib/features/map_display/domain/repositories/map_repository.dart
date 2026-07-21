import 'package:dartz/dartz.dart';
import 'package:here_sdk/mapview.dart' show HereMapController;

import '../../../../core/entities/geo_point.dart';
import '../../../../core/error/failures.dart';
import '../entities/map_camera_position.dart';

abstract class MapRepository {

  Future<Either<Failure, void>> loadInitialScene({
    required HereMapController controller,
    required MapCameraPosition initialCameraPosition,
  });

  /// Moves the camera on the map
  Either<Failure, void> moveCamera(MapCameraPosition position);

  /// Shows (or moves) a marker at [position]
  Either<Failure, void> showCurrentLocationMarker(MapCameraPosition position);

  /// Draws [polyline] as a route line on the map
  Either<Failure, void> showRoute(List<GeoPoint> polyline);

  /// Removes a previously drawn route
  Either<Failure, void> clearRoute();
}