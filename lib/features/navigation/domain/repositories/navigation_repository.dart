import 'package:dartz/dartz.dart';
import 'package:here_sdk/mapview.dart' show HereMapController;

import '../../../../core/error/failures.dart';
import '../entities/navigation_instruction.dart';

abstract class NavigationRepository {
  Future<Either<Failure, Stream<NavigationInstruction>>> startNavigation({
    required HereMapController controller,
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  });

  /// Stops navigation/simulation and releases resources
  void stopNavigation();
}