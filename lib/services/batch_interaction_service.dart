import 'dart:convert';
import 'dart:io';

import 'package:fliccsy/models/batch_interaction.dart';
import 'package:fliccsy/models/batch_swipe.dart';
import 'package:fliccsy/models/movie_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class InteractionService {
  final String _baseUrl =
      Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
  static const String _roomCodeKey = 'current_room_code';

  // Store room code
  Future<void> storeRoomCode(String roomCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roomCodeKey, roomCode);
  }

  // Get stored room code
  Future<String?> _getRoomCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roomCodeKey);
  }

  // Record batch of swipes from movie state
  Future<bool> recordBatchSwipesFromState({
    required String userId,
    required MovieState state,
  }) async {
    try {
      final roomCode = await _getRoomCode();
      final List<BatchSwipe> batchSwipes = [];

      // Add interested swipes
      for (final movieId in state.interestedMovieIds) {
        batchSwipes.add(BatchSwipe(
          movieId: movieId,
          action: SwipeAction.interested,
        ));
      }

      // Add not interested swipes
      for (final movieId in state.notInterestedIds) {
        batchSwipes.add(BatchSwipe(
          movieId: movieId,
          action: SwipeAction.not_interested,
        ));
      }

      // Add watched and liked swipes
      // We use likedMovieIds since these will match with watchedMovieIds for up swipes
      for (final movieId in state.likedMovieIds) {
        batchSwipes.add(BatchSwipe(
          movieId: movieId,
          action: SwipeAction.watched_liked,
        ));
      }

      // Add not sure swipes
      for (final movieId in state.notSureIds) {
        batchSwipes.add(BatchSwipe(
          movieId: movieId,
          action: SwipeAction.not_sure,
        ));
      }

      // Create batch interaction object
      final batchInteraction = BatchInteraction(
        userId: userId,
        roomId: roomCode,
        swipes: batchSwipes,
      );

      // Send to API
      final response = await http.post(
        Uri.parse('$_baseUrl/interactions/batch-record'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(batchInteraction.toJson()),
      );

      if (response.statusCode != 200) {
        print('Failed API call with status ${response.statusCode}');
        print('Request body was: ${jsonEncode(batchInteraction.toJson())}');
        print('Response body: ${response.body}');
        throw Exception('Failed to record batch swipes: ${response.body}');
      }

      print('Successfully recorded ${batchSwipes.length} swipes');

      return true;
    } catch (e) {
      print('Error recording batch swipes: $e');
      return false;
    }
  }

  // Clear stored room code
  Future<void> clearRoomCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roomCodeKey);
  }
}
