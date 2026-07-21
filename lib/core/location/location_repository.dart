import 'package:dartz/dartz.dart';

import '../error/failures.dart';
import 'device_position.dart';

abstract class LocationRepository {
  Future<Either<Failure, DevicePosition>> getCurrentPosition();
  Future<void> openLocationSettings();
}