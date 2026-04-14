import 'package:equatable/equatable.dart';

import '../../domain/entities/search_result_entity.dart';

class SearchState extends Equatable {
  const SearchState({required this.query, required this.results, required this.isLoaded});

  final String query;
  final List<SearchResultEntity> results;
  final bool isLoaded;

  factory SearchState.initial() => const SearchState(query: '', results: <SearchResultEntity>[], isLoaded: false);

  SearchState copyWith({String? query, List<SearchResultEntity>? results, bool? isLoaded}) {
    return SearchState(query: query ?? this.query, results: results ?? this.results, isLoaded: isLoaded ?? this.isLoaded);
  }

  @override
  List<Object?> get props => [query, results, isLoaded];
}
