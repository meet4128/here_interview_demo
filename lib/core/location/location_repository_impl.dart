import 'dart:async';

import 'package:dartz/dartz.dart';

import '../error/failures.dart';
import 'device_position.dart';
import 'location_data_source.dart';
import 'location_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationDataSource _dataSource;

  const LocationRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, DevicePosition>> getCurrentPosition() async {
    try {
      final position = await _dataSource.getCurrentPosition();
      return Right(position);
    } on LocationPermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on TimeoutException {
      return const Left(PermissionFailure('Timed out waiting for a GPS fix.'));
    } catch (e) {
      return Left(PermissionFailure('Unexpected location error: $e'));
    }
  }

  @override
  Future<void> openLocationSettings() {
    return _dataSource.openLocationSettings();
  }
}