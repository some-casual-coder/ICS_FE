import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GroupPreferencesRequest {
  final String runtimePreference;
  final Map<String, double> genreWeights;
  final List<String> languagePreference;
  final double minRating;
  final List<int> releaseYearRange;

  GroupPreferencesRequest({
    required this.runtimePreference,
    required this.genreWeights,
    required this.languagePreference,
    required this.minRating,
    required this.releaseYearRange,
  });

  Map<String, dynamic> toJson() => {
        'runtime_preference': runtimePreference,
        'genre_weights': genreWeights,
        'language_preference': languagePreference,
        'min_rating': minRating,
        'release_year_range': releaseYearRange,
      };
}

class RecommendationRequest {
  final List<int> movieIds;
  final List<int> notInterestedIds;
  final GroupPreferencesRequest preferences;

  RecommendationRequest({
    required this.movieIds,
    required this.notInterestedIds,
    required this.preferences,
  });

  Map<String, dynamic> toJson() => {
        'movie_ids': movieIds,
        'not_interested_ids': notInterestedIds,
        'preferences': preferences.toJson(),
      };
}

class RecommendationService {
  final String _baseUrl =
      Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://localhost:8000';

  // Get room preferences
  Future<Map<String, dynamic>> getRoomPreferences(String roomId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/rooms/$roomId/preferences'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get room preferences: ${response.body}');
      }

      return jsonDecode(response.body)['preferences'];
    } catch (e) {
      print('Error getting room preferences: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getRoomStats(String roomId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/interactions/rooms/$roomId/stats'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get room stats: ${response.body}');
      }

      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting room stats: $e');
      rethrow;
    }
  }

  // Get group preferences
  Future<GroupPreferencesRequest> getGroupPreferences({
    required List<String> userIds,
    required String runtime,
    required List<String> languages,
    required double minRating,
    required int startYear,
    required int endYear,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/recommendations/group/preferences'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_ids': userIds,
          'runtime': runtime,
          'languages': languages,
          'min_rating': minRating,
          'start_year': startYear,
          'end_year': endYear,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get group preferences: ${response.body}');
      }

      final data = jsonDecode(response.body);
      return GroupPreferencesRequest(
        runtimePreference: data['runtime_preference'],
        genreWeights: Map<String, double>.from(data['genre_weights']),
        languagePreference: List<String>.from(data['language_preference']),
        minRating: data['min_rating'].toDouble(),
        releaseYearRange: List<int>.from(data['release_year_range']),
      );
    } catch (e) {
      print('Error getting group preferences: $e');
      rethrow;
    }
  }

  // Get recommendations
  Future<List<dynamic>> getRecommendations(
      RecommendationRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/recommendations/group'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get recommendations: ${response.body}');
      }

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      // Access the nested recommendations array
      final recommendations =
          responseData['recommendations']['recommendations'] as List;
      return recommendations;
    } catch (e) {
      print('Error getting recommendations: $e');
      rethrow;
    }
  }

  // Combine all steps to get recommendations for a room
  Future<List<dynamic>> getRecommendationsForRoom({
    required String roomId,
    required String roomCode,
    required List<String> userIds,
  }) async {
    print(userIds);
    // 1. Get room preferences
    final roomPrefs = await getRoomPreferences(roomId);

    // 2. Get group preferences
    final groupPrefs = await getGroupPreferences(
      userIds: userIds,
      runtime: roomPrefs['runtime_preference'],
      languages: List<String>.from(roomPrefs['language_preference']),
      minRating: roomPrefs['min_rating'].toDouble(),
      startYear: roomPrefs['release_year_range'][0],
      endYear: roomPrefs['release_year_range'][1],
    );

    // 3. Get room stats
    final stats = await getRoomStats(roomCode);

    final likedMovieIds = [
      ...List<int>.from(stats['interested_movie_ids'] ?? []),
      ...List<int>.from(stats['watched_movie_ids'] ?? [])
    ];

    print(likedMovieIds);

    // 3. Create recommendation request
    final request = RecommendationRequest(
      movieIds: likedMovieIds,
      notInterestedIds: List<int>.from(stats['not_interested_movie_ids'] ?? []),
      preferences: groupPrefs,
    );

    // 4. Get and return recommendations
    return await getRecommendations(request);
  }
}
