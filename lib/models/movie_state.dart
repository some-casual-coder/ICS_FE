import 'package:fliccsy/models/movie.dart';
import 'package:flutter/material.dart';

class MovieState {
  final List<Movie> movies;
  final List<String> interestedMovieIds; // Swiped right
  final List<String> notInterestedIds; // Swiped left
  final List<String> watchedMovieIds; // Part of up swipe
  final List<String> likedMovieIds; // Part of up swipe
  final List<String> notSureIds;
  final bool isDragging;
  final Offset position;
  final double angle;
  //Statistics
  final int upSwipes; // Watched and liked
  final int downSwipes; // Not sure
  final int rightSwipes; // Interested
  final int leftSwipes; // Disliked
  final DateTime sessionStartTime;
  final bool isLoading;
  final String? error;

  MovieState(
      {this.movies = const [],
      this.interestedMovieIds = const [],
      this.notInterestedIds = const [],
      this.watchedMovieIds = const [],
      this.likedMovieIds = const [],
      this.notSureIds = const [],
      this.isDragging = false,
      this.position = Offset.zero,
      this.angle = 0,
      this.upSwipes = 0,
      this.downSwipes = 0,
      this.rightSwipes = 0,
      this.leftSwipes = 0,
      DateTime? sessionStartTime,
      this.isLoading = false,
      this.error})
      : sessionStartTime = sessionStartTime ?? DateTime.now();

  MovieState copyWith({
    List<Movie>? movies,
    List<String>? interestedMovieIds,
    List<String>? notInterestedIds,
    List<String>? watchedMovieIds,
    List<String>? likedMovieIds,
    List<String>? notSureIds,
    bool? isDragging,
    Offset? position,
    double? angle,
    int? upSwipes,
    int? rightSwipes,
    int? leftSwipes,
    int? downSwipes,
    DateTime? sessionStartTime,
    bool? isLoading,
    String? error,
  }) {
    return MovieState(
      movies: movies ?? this.movies,
      interestedMovieIds: interestedMovieIds ?? this.interestedMovieIds,
      notInterestedIds: notInterestedIds ?? this.notInterestedIds,
      watchedMovieIds: watchedMovieIds ?? this.watchedMovieIds,
      likedMovieIds: likedMovieIds ?? this.likedMovieIds,
      notSureIds: notSureIds ?? this.notSureIds,
      isDragging: isDragging ?? this.isDragging,
      position: position ?? this.position,
      angle: angle ?? this.angle,
      upSwipes: upSwipes ?? this.upSwipes,
      rightSwipes: rightSwipes ?? this.rightSwipes,
      leftSwipes: leftSwipes ?? this.leftSwipes,
      downSwipes: downSwipes ?? this.downSwipes,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
