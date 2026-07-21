import 'package:equatable/equatable.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

class SearchQueryChanged extends SearchEvent {
  final String query;
  final double areaCenterLatitude;
  final double areaCenterLongitude;

  const SearchQueryChanged({
    required this.query,
    required this.areaCenterLatitude,
    required this.areaCenterLongitude,
  });

  @override
  List<Object?> get props => [query, areaCenterLatitude, areaCenterLongitude];
}