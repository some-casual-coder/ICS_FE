// preferences_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PreferencesState {
  final List<String> movieLength;
  final List<String> preferredEras;
  final String? languagePreference;

  PreferencesState({
    this.movieLength = const [],
    this.preferredEras = const [],
    this.languagePreference,
  });

  PreferencesState copyWith({
    List<String>? movieLength,
    List<String>? preferredEras,
    String? languagePreference,
  }) {
    return PreferencesState(
      movieLength: movieLength ?? this.movieLength,
      preferredEras: preferredEras ?? this.preferredEras,
      languagePreference: languagePreference ?? this.languagePreference,
    );
  }

  Map<String, dynamic> toJson() => {
        'movie_length': movieLength,
        'preferred_eras': preferredEras,
        'language_preference': languagePreference,
      };
}

final preferencesProvider =
    StateNotifierProvider<PreferencesNotifier, PreferencesState>(
        (ref) => PreferencesNotifier());

class PreferencesNotifier extends StateNotifier<PreferencesState> {
  PreferencesNotifier() : super(PreferencesState());

  void toggleMovieLength(String length) {
    final currentLengths = List<String>.from(state.movieLength);
    if (currentLengths.contains(length)) {
      currentLengths.remove(length);
    } else {
      currentLengths.add(length);
    }
    state = state.copyWith(movieLength: currentLengths);
  }

  void togglePreferredEra(String era) {
    final currentEras = List<String>.from(state.preferredEras);
    if (currentEras.contains(era)) {
      currentEras.remove(era);
    } else {
      currentEras.add(era);
    }
    state = state.copyWith(preferredEras: currentEras);
  }

  void setLanguagePreference(String preference) {
    state = state.copyWith(languagePreference: preference);
  }
}
