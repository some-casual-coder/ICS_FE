import 'package:flutter_riverpod/flutter_riverpod.dart';

class Movie {
  final int id;
  final String? backdropPath;
  final String? title;
  final String? releaseDate;

  Movie({
    required this.id,
    required this.backdropPath,
    required this.title,
    required this.releaseDate,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    try {
      return Movie(
        id: json['id'],
        backdropPath: json['backdrop_path'],
        title: json['title'],
        releaseDate: json['release_date'],
      );
    } catch (e) {
      print('Error parsing movie: ${json['title']}, Error: $e');
      rethrow;
    }
  }

  int? get year {
    if (releaseDate == null) return null;
    try {
      return DateTime.parse(releaseDate!).year;
    } catch (e) {
      print('Error parsing date: $releaseDate');
      return null;
    }
  }
}

final selectedMoviesProvider =
    StateNotifierProvider<SelectedMoviesNotifier, List<Movie>>((ref) {
  return SelectedMoviesNotifier();
});

class SelectedMoviesNotifier extends StateNotifier<List<Movie>> {
  SelectedMoviesNotifier() : super([]);

  void addMovie(Movie movie) {
    state = [...state, movie];
  }

  void removeMovie(Movie movie) {
    state = state.where((m) => m.id != movie.id).toList();
  }

  bool isSelected(Movie movie) {
    return state.any((m) => m.id == movie.id);
  }
}
