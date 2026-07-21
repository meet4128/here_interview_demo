import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/search_repository.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchRepository _searchRepository;

  static const _debounceDuration = Duration(milliseconds: 400);

  SearchBloc({required SearchRepository searchRepository})
      : _searchRepository = searchRepository,
        super(const SearchInitial()) {
    on<SearchQueryChanged>(_onSearchQueryChanged, transformer: restartable());
  }

  Future<void> _onSearchQueryChanged(
      SearchQueryChanged event,
      Emitter<SearchState> emit,
      ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(const SearchInitial());
      return;
    }

    emit(const SearchLoading());
    await Future.delayed(_debounceDuration);

    final result = await _searchRepository.searchByText(
      query: query,
      areaCenterLatitude: event.areaCenterLatitude,
      areaCenterLongitude: event.areaCenterLongitude,
    );

    result.fold(
          (failure) => emit(SearchError(failure.message)),
          (results) => emit(
        results.isEmpty ? const SearchEmpty() : SearchLoaded(results),
      ),
    );
  }
}