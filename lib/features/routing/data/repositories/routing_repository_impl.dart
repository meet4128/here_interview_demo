import 'package:dartz/dartz.dart';
import 'package:here_sdk/routing.dart' as here_routing;

import '../../../../core/entities/geo_point.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/route_info.dart';
import '../../domain/repositories/routing_repository.dart';
import '../datasources/routing_data_source.dart';

class RoutingRepositoryImpl implements RoutingRepository {
  final RoutingDataSource _dataSource;

  const RoutingRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, RouteInfo>> calculateCarRoute({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    try {
      final route = await _dataSource.calculateCarRoute(
        originLatitude: originLatitude,
        originLongitude: originLongitude,
        destinationLatitude: destinationLatitude,
        destinationLongitude: destinationLongitude,
      );
      return Right(_toRouteInfo(route));
    } on RoutingNoRouteFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RoutingQueryException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected routing error: $e'));
    }
  }

  RouteInfo _toRouteInfo(here_routing.Route route) {
    return RouteInfo(
      polyline: route.geometry.vertices
          .map((c) => GeoPoint(latitude: c.latitude, longitude: c.longitude))
          .toList(),
      lengthInMeters: route.lengthInMeters,
      duration: route.duration,
    );
  }
}