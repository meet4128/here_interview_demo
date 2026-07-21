import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/route_info.dart';

abstract class RoutingRepository {
  /// Calculates a car route between the origin and destination points.
  Future<Either<Failure, RouteInfo>> calculateCarRoute({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  });
}