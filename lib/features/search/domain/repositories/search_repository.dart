import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/place_result.dart';

abstract class SearchRepository {
  Future<Either<Failure, List<PlaceResult>>> searchByText({
    required String query,
    required double areaCenterLatitude,
    required double areaCenterLongitude,
  });
}