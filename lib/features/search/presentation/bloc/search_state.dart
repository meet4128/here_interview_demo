import 'package:equatable/equatable.dart';

import '../../domain/entities/place_result.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {
  const SearchInitial();
}

class SearchLoading extends SearchState {
  const SearchLoading();
}

class SearchLoaded extends SearchState {
  final List<PlaceResult> results;

  const SearchLoaded(this.results);

  @override
  List<Object?> get props => [results];
}

class SearchEmpty extends SearchState {
  const SearchEmpty();
}

class SearchError extends SearchState {
  final String message;

  const SearchError(this.message);

  @override
  List<Object?> get props => [message];
}