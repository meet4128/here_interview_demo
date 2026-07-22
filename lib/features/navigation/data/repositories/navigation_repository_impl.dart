import 'package:dartz/dartz.dart';
import 'package:here_sdk/mapview.dart' show HereMapController;

import '../../../../core/error/failures.dart';
import '../../domain/entities/navigation_instruction.dart';
import '../../domain/repositories/navigation_repository.dart';
import '../datasources/navigation_data_source.dart';

class NavigationRepositoryImpl implements NavigationRepository {
  final NavigationDataSource _dataSource;

  const NavigationRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, Stream<NavigationInstruction>>> startNavigation({
    required HereMapController controller,
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    try {
      final stream = await _dataSource.startNavigation(
        controller: controller,
        originLatitude: originLatitude,
        originLongitude: originLongitude,
        destinationLatitude: destinationLatitude,
        destinationLongitude: destinationLongitude,
      );
      return Right(stream);
    } on NavigationStartException catch (e) {
      return Left(NavigationFailure(e.message));
    } catch (e) {
      return Left(NavigationFailure('Unexpected navigation error: $e'));
    }
  }

  @override
  void stopNavigation() {
    _dataSource.stopNavigation();
  }
}