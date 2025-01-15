import 'dart:convert';
import 'dart:io';

import 'package:fliccsy/models/genre.dart';
import 'package:fliccsy/providers/genre_provider.dart';
import 'package:fliccsy/providers/movie_provider.dart';
import 'package:fliccsy/providers/preferences_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

enum SubmissionStep { genres, movies, preferences, completed }

class SubmissionState {
  final bool isLoading;
  final SubmissionStep currentStep;
  final String? error;

  SubmissionState({
    this.isLoading = false,
    this.currentStep = SubmissionStep.genres,
    this.error,
  });
}

final submissionProvider =
    StateNotifierProvider<SubmissionNotifier, SubmissionState>(
        (ref) => SubmissionNotifier(ref));

class SubmissionNotifier extends StateNotifier<SubmissionState> {
  final Ref ref;

  SubmissionNotifier(this.ref) : super(SubmissionState());

  Future<bool> validateAndSubmit(String userId) async {
    final prefs = ref.read(preferencesProvider);
    final selectedGenres = ref.read(genreProvider);
    final selectedMovies = ref.read(selectedMoviesProvider);

    // Validation
    if (selectedGenres.isEmpty) {
      state = SubmissionState(error: "Please select some genres");
      return false;
    }
    if (selectedMovies.isEmpty) {
      state = SubmissionState(error: "Please select some movies");
      return false;
    }
    if (prefs.languagePreference == null ||
        prefs.movieLength.isEmpty ||
        prefs.preferredEras.isEmpty) {
      state = SubmissionState(error: "Please complete all preferences");
      return false;
    }

    state = SubmissionState(isLoading: true);

    try {
      // Submit genres
      state =
          SubmissionState(isLoading: true, currentStep: SubmissionStep.genres);
      await _submitGenres(userId, selectedGenres);

      // Submit movies
      state =
          SubmissionState(isLoading: true, currentStep: SubmissionStep.movies);
      await _submitMovies(userId, selectedMovies);

      // Submit preferences
      state = SubmissionState(
          isLoading: true, currentStep: SubmissionStep.preferences);
      await _submitPreferences(userId, prefs);

      state = SubmissionState(
          isLoading: false, currentStep: SubmissionStep.completed);
      return true;
    } catch (e) {
      state = SubmissionState(error: "Error submitting data: $e");
      return false;
    }
  }

  // Future<void> _submitGenres(String userId, List<Genre> genres) async {
  //   final url = Platform.isAndroid
  //       ? 'http://10.0.2.2:8000/genres/preferences'
  //       : 'http://localhost:8000/genres/preferences';

  //   final response = await http.post(
  //     Uri.parse(url),
  //     headers: {'Content-Type': 'application/json'},
  //     body: json.encode({
  //       'user_id': userId,
  //       'selected_genres': genres.map((g) => {'id': g.id}).toList(),
  //     }),
  //   );

  //   if (response.statusCode != 200) throw Exception('Failed to submit genres');
  // }

  // Future<void> _submitMovies(String userId, List<Movie> movies) async {
  //   final url = Platform.isAndroid
  //       ? 'http://10.0.2.2:8000/movies/preferences'
  //       : 'http://localhost:8000/movies/preferences';

  //   final response = await http.post(
  //     Uri.parse(url),
  //     headers: {'Content-Type': 'application/json'},
  //     body: json.encode(
  //       movies
  //           .map((movie) => {
  //                 'user_id': userId,
  //                 'movie_id': movie.id,
  //                 'rating': 1,
  //               })
  //           .toList(),
  //     ),
  //   );

  //   if (response.statusCode != 200) throw Exception('Failed to submit movies');
  // }

  // Future<void> _submitPreferences(String userId, PreferencesState prefs) async {
  //   final url = Platform.isAndroid
  //       ? 'http://10.0.2.2:8000/user/settings'
  //       : 'http://localhost:8000/user/settings';

  //   final response = await http.post(
  //     Uri.parse(url),
  //     headers: {'Content-Type': 'application/json'},
  //     body: json.encode({
  //       'user_id': userId,
  //       ...prefs.toJson(),
  //     }),
  //   );

  //   if (response.statusCode != 200)
  //     throw Exception('Failed to submit preferences');
  // }

  Future<void> _submitGenres(String userId, List<Genre> genres) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));
    // In real implementation, remove this log
    print('Submitting genres: ${json.encode({
          'user_id': userId,
          'selected_genres': genres.map((g) => {'id': g.id}).toList(),
        })}');
  }

  Future<void> _submitMovies(String userId, List<Movie> movies) async {
    await Future.delayed(const Duration(seconds: 1));
    print('Submitting movies: ${json.encode(
      movies
          .map((movie) => {
                'user_id': userId,
                'movie_id': movie.id,
                'rating': 1,
              })
          .toList(),
    )}');
  }

  Future<void> _submitPreferences(String userId, PreferencesState prefs) async {
    await Future.delayed(const Duration(seconds: 1));
    print('Submitting preferences: ${json.encode({
          'user_id': userId,
          ...prefs.toJson(),
        })}');
  }
}
