import 'dart:async';

import 'package:here_sdk/core.dart';
import 'package:here_sdk/search.dart';

class SearchQueryException implements Exception {
  final String message;

  const SearchQueryException(this.message);

  @override
  String toString() => 'SearchQueryException: $message';
}

class SearchDataSource {
  final SearchEngine _searchEngine;

  const SearchDataSource(this._searchEngine);

  Future<List<Place>> searchByText({
    required String query,
    required double areaCenterLatitude,
    required double areaCenterLongitude,
  }) {
    final completer = Completer<List<Place>>();

    final areaCenter = GeoCoordinates(areaCenterLatitude, areaCenterLongitude);
    final queryArea = TextQueryArea.withCenter(areaCenter);
    final textQuery = TextQuery.withArea(query, queryArea);
    final options = SearchOptions()..maxItems = 20;

    _searchEngine.searchByText(textQuery, options, (
      SearchError? error,
      List<Place>? places,
    ) {
      if (error != null) {
        completer.completeError(
          SearchQueryException('Search failed: ${error.toString()}'),
        );
      } else {
        completer.complete(places ?? const []);
      }
    });

    return completer.future;
  }
}
