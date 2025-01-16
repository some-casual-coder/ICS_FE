import 'dart:convert';
import 'dart:io';

import 'package:fliccsy/models/movie.dart';
import 'package:fliccsy/models/movie_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class MovieNotifier extends StateNotifier<MovieState> {
  final String roomId;
  final String userId;
  int currentPage = 1;

  MovieNotifier({required this.roomId, required this.userId})
      : super(MovieState()) {
    loadInitialMovies();
  }

  Future<void> loadInitialMovies() async {
    try {
      state = state.copyWith(isLoading: true);

      // 1. Fetch all preferences in parallel
      final preferences = await Future.wait([
        _fetchUserSettings(),
        _fetchLikedMovies(),
        _fetchUserGenres(),
        _fetchRoomPreferences(),
      ]);

      // 2. Extract data from responses
      final userSettings = preferences[0] as Map<String, dynamic>;
      final likedMovies = preferences[1] as Map<String, dynamic>;
      final userGenres = preferences[2] as Map<String, dynamic>;
      final roomPrefs = preferences[3] as Map<String, dynamic>;

      // 3. Build discovery query parameters
      final queryParams = _buildQueryParams(
        userSettings: userSettings,
        likedMovies: likedMovies,
        userGenres: userGenres,
        roomPreferences: roomPrefs,
      );

      // 4. Fetch movies
      final movies = await _fetchMovies(queryParams);

      // 5. Transform API response to Movie objects
      final transformedMovies = _transformMovieResponse(movies);

      state = state.copyWith(
        movies: transformedMovies,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<Map<String, dynamic>> _fetchUserSettings() async {
    final url = Platform.isAndroid
        ? 'http://10.0.2.2:8000/user/$userId/settings'
        : 'http://localhost:8000/user/$userId/settings';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200)
      throw Exception('Failed to fetch user settings');
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> _fetchLikedMovies() async {
    final url = Platform.isAndroid
        ? 'http://10.0.2.2:8000/user/$userId/liked-movies'
        : 'http://localhost:8000/user/$userId/liked-movies';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200)
      throw Exception('Failed to fetch liked movies');
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> _fetchUserGenres() async {
    final url = Platform.isAndroid
        ? 'http://10.0.2.2:8000/user/$userId/genres'
        : 'http://localhost:8000/user/$userId/genres';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200)
      throw Exception('Failed to fetch user genres');
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> _fetchRoomPreferences() async {
    final url = Platform.isAndroid
        ? 'http://10.0.2.2:8000/rooms/$roomId/preferences'
        : 'http://localhost:8000/rooms/$roomId/preferences';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200)
      throw Exception('Failed to fetch room preferences');
    return json.decode(response.body);
  }

  String _buildQueryParams({
    required Map<String, dynamic> userSettings,
    required Map<String, dynamic> likedMovies,
    required Map<String, dynamic> userGenres,
    required Map<String, dynamic> roomPreferences,
  }) {
    final prefs = roomPreferences['preferences'];
    final watchedMovieIds = likedMovies['movies']?.keys.toList() ?? [];
    final genreIds = userGenres['genres']?.map((g) => g['id'].toString()) ?? [];

    final queryParameters = {
      'runtime': prefs['runtime_preference'],
      'languages': prefs['language_preference'].join(','),
      'min_rating': prefs['min_rating'].toString(),
      'start_year': prefs['release_year_range'][0].toString(),
      'end_year': prefs['release_year_range'][1].toString(),
      'exclude_watched': 'true',
      'page': currentPage.toString(),
      'per_page': '15',
    };

    final queryList = queryParameters.entries.map((entry) {
      return '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}';
    }).toList();

    for (final genreId in genreIds) {
      queryList.add('genres=${Uri.encodeComponent(genreId)}');
    }

    for (final movieId in watchedMovieIds) {
      queryList.add('watched_movies=${Uri.encodeComponent(movieId)}');
    }

    return queryList.join('&');
  }

  Future<Map<String, dynamic>> _fetchMovies(String queryParams) async {
    final baseUrl =
        Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://localhost:8000';

    final url = '$baseUrl/discover/movies?$queryParams';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) throw Exception('Failed to fetch movies');
    return json.decode(response.body);
  }

  List<Movie> _transformMovieResponse(Map<String, dynamic> moviesData) {
    return (moviesData['results'] as List)
        .map((movie) => Movie(
              id: movie['id'].toString(),
              title: movie['title'],
              imageUrl:
                  'https://image.tmdb.org/t/p/original${movie['poster_path']}',
              description: movie['keywords'] ?? '',
              releaseDate: movie['release_date']?.substring(0, 4) ?? '',
              rating: movie['vote_average']?.toDouble() ?? 0.0,
            ))
        .toList();
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
