import 'package:fliccsy/models/genre.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final genreProvider =
    StateNotifierProvider<GenreNotifier, List<Genre>>((ref) => GenreNotifier());

class GenreNotifier extends StateNotifier<List<Genre>> {
  GenreNotifier() : super([]);

  void addGenre(Genre genre) {
    state = [...state, genre];
  }

  void removeGenre(Genre genre) {
    state = state.where((g) => g.id != genre.id).toList();
  }
}
