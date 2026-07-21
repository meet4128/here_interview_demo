import 'package:dartz/dartz.dart';
import 'package:here_sdk/search.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/place_result.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_data_source.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchDataSource _dataSource;

  const SearchRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<PlaceResult>>> searchByText({
    required String query,
    required double areaCenterLatitude,
    required double areaCenterLongitude,
  }) async {
    try {
      final places = await _dataSource.searchByText(
        query: query,
        areaCenterLatitude: areaCenterLatitude,
        areaCenterLongitude: areaCenterLongitude,
      );
      return Right(places.map(_toPlaceResult).toList());
    } on SearchQueryException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected search error: $e'));
    }
  }

  PlaceResult _toPlaceResult(Place place) {
    return PlaceResult(
      id: place.id,
      title: place.title,
      addressText: place.address.addressText,
      latitude: place.geoCoordinates?.latitude,
      longitude: place.geoCoordinates?.longitude,
    );
  }
}