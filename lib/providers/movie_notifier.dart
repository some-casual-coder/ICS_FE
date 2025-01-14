import 'package:fliccsy/models/movie.dart';
import 'package:fliccsy/models/movie_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final movieStateProvider =
    StateNotifierProvider<MovieNotifier, MovieState>((ref) {
  return MovieNotifier();
});

class MovieNotifier extends StateNotifier<MovieState> {
  MovieNotifier() : super(MovieState()) {
    loadInitialMovies();
  }

  void loadInitialMovies() {
    final movies = [
      const Movie(
        id: '1',
        title: 'Inception',
        imageUrl:
            'https://m.media-amazon.com/images/I/81dae9nZFBS._AC_SL1500_.jpg',
        description:
            'A thief who steals corporate secrets through dream-sharing technology.',
        releaseDate: '2010',
        rating: 8.8,
      ),
      const Movie(
        id: '2',
        title: 'Inception',
        imageUrl:
            'https://www.tallengestore.com/cdn/shop/products/Joker_-_Put_On_A_Happy_Face_-_Joaquin_Phoenix_-_Hollywood_English_Movie_Poster_3_0e557717-f9ae-4d45-82c3-27e08c2a9eeb.jpg?v=1579504984',
        description:
            'A thief who steals corporate secrets through dream-sharing technology.',
        releaseDate: '2010',
        rating: 8.8,
      ),
      const Movie(
        id: '3',
        title: 'Inception',
        imageUrl:
            'https://m.media-amazon.com/images/I/71ZJ8am0mKL._AC_SL1340_.jpg',
        description:
            'A thief who steals corporate secrets through dream-sharing technology.',
        releaseDate: '2010',
        rating: 8.8,
      ),
      const Movie(
        id: '4',
        title: 'Inception',
        imageUrl:
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS71Tr4Fx-4ovgyP5w6XkBZbZBNv7hA_Zr0Yg&s',
        description:
            'A thief who steals corporate secrets through dream-sharing technology.',
        releaseDate: '2010',
        rating: 8.8,
      ),
      // Add more movies...
    ];

    state = state.copyWith(movies: movies);
  }

  void startDragging(DragStartDetails details) {
    state = state.copyWith(isDragging: true);
  }

  void updatePosition(DragUpdateDetails details, Size screenSize) {
    final newPosition = state.position + details.delta;
    final x = newPosition.dx;
    final newAngle = 45 * x / screenSize.width;

    state = state.copyWith(
      position: newPosition,
      angle: newAngle,
    );
  }

  void endDragging(Size screenSize) {
    final status = _getStatus(screenSize);
    final currentMovie = state.movies.isEmpty ? null : state.movies.last;

    if (currentMovie == null) return;

    switch (status) {
      case SwipeStatus.interested:
        _handleInterested(currentMovie);
        break;
      case SwipeStatus.notInterested:
        _handleNotInterested(currentMovie);
        break;
      case SwipeStatus.watchedAndLiked:
        _handleWatchedAndLiked(currentMovie);
        break;
      case SwipeStatus.notSure:
        _handleNotSure(currentMovie);
        break;
      case SwipeStatus.none:
        _resetPosition();
        break;
    }
  }

  void _handleWatchedAndLiked(Movie movie) {
    state = state.copyWith(
      likedMovieIds: [...state.likedMovieIds, movie.id],
      watchedMovieIds: [...state.watchedMovieIds, movie.id],
      upSwipes: state.upSwipes + 1,
      angle: 0,
      position: state.position - const Offset(0, 2000),
    );
    _removeCurrentMovie();
  }

  void _handleNotSure(Movie movie) {
    state = state.copyWith(
      notSureIds: [...state.notSureIds, movie.id],
      downSwipes: state.downSwipes + 1,
      angle: 0,
      position: state.position + const Offset(0, 2000),
    );
    _removeCurrentMovie();
  }

  void _handleInterested(Movie movie) {
    state = state.copyWith(
      interestedMovieIds: [...state.interestedMovieIds, movie.id],
      rightSwipes: state.rightSwipes + 1,
      angle: 20,
      position: state.position + const Offset(2000, 0),
    );
    _removeCurrentMovie();
  }

  void _handleNotInterested(Movie movie) {
    state = state.copyWith(
      notInterestedIds: [...state.notInterestedIds, movie.id],
      leftSwipes: state.leftSwipes + 1,
      angle: -20,
      position: state.position - const Offset(2000, 0),
    );
    _removeCurrentMovie();
  }

  Map<String, dynamic> getSessionStats() {
    final sessionDuration = DateTime.now().difference(state.sessionStartTime);
    return {
      'totalSwipes': state.upSwipes + state.rightSwipes + state.leftSwipes,
      'upSwipes': state.upSwipes,
      'rightSwipes': state.rightSwipes,
      'leftSwipes': state.leftSwipes,
      'sessionDuration': sessionDuration,
      'likedMovies': state.likedMovieIds.length,
      'interestedMovies': state.interestedMovieIds.length,
      'watchedMovies': state.watchedMovieIds.length,
    };
  }

  Future<void> _removeCurrentMovie() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    final newMovies = List<Movie>.from(state.movies)..removeLast();
    state = state.copyWith(
      movies: newMovies,
      position: Offset.zero,
      angle: 0,
      isDragging: false,
    );
  }

  void _resetPosition() {
    state = state.copyWith(
      position: Offset.zero,
      angle: 0,
      isDragging: false,
    );
  }

  SwipeStatus _getStatus(Size screenSize) {
    final x = state.position.dx;
    final y = state.position.dy;
    const delta = 100;

    if (y <= -delta) return SwipeStatus.watchedAndLiked;
    if (y >= delta) return SwipeStatus.notSure; // Swipe down for not sure
    if (x >= delta) return SwipeStatus.interested; // Swipe right for interested
    if (x <= -delta) {
      return SwipeStatus.notInterested; // Swipe left for not interested
    }
    return SwipeStatus.none;
  }

  void reset() {
    loadInitialMovies();
    state = state.copyWith(
      position: Offset.zero,
      angle: 0,
      isDragging: false,
    );
  }
}

enum SwipeStatus { interested, notInterested, watchedAndLiked, notSure, none }
