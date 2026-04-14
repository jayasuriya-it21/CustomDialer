import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_favorites_usecase.dart';
import 'favorites_event.dart';
import 'favorites_state.dart';

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  FavoritesBloc(this._getFavoritesUseCase) : super(const FavoritesInitial()) {
    on<FavoritesRequested>(_onFavoritesRequested);
  }

  final GetFavoritesUseCase _getFavoritesUseCase;

  Future<void> _onFavoritesRequested(FavoritesRequested event, Emitter<FavoritesState> emit) async {
    emit(const FavoritesLoading());
    try {
      final contacts = await _getFavoritesUseCase(forceRefresh: event.forceRefresh);
      emit(FavoritesLoaded(contacts));
    } catch (_) {
      emit(const FavoritesError('Unable to load favourites'));
    }
  }
}
