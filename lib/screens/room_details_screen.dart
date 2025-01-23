import 'dart:convert';
import 'dart:io';

import 'package:fliccsy/models/movie_state.dart';
import 'package:fliccsy/models/room_data.dart';
import 'package:fliccsy/providers/auth_provider.dart';
import 'package:fliccsy/providers/movie_notifier.dart';
import 'package:fliccsy/screens/lobby_screen.dart';
import 'package:fliccsy/screens/room_settings_screen.dart';
import 'package:fliccsy/screens/swipe_screen.dart';
import 'package:fliccsy/services/batch_interaction_service.dart';
import 'package:fliccsy/services/recommendations_service.dart';
import 'package:fliccsy/theme/app_colors.dart';
import 'package:fliccsy/widgets/progress_tracker.dart';
import 'package:fliccsy/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class RoomDetailsScreen extends ConsumerStatefulWidget {
  final RoomData initialRoomData;

  const RoomDetailsScreen({
    Key? key,
    required this.initialRoomData,
  }) : super(key: key);

  @override
  ConsumerState<RoomDetailsScreen> createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends ConsumerState<RoomDetailsScreen> {
  late RoomData roomData;
  final _recommendationService = RecommendationService();
  List<dynamic>? recommendations;
  bool isLoadingRecommendations = false;

  bool get allUsersCompleted {
    return roomData.users.values.every((user) => user.status == 'completed');
  }

  @override
  void initState() {
    super.initState();
    roomData = widget.initialRoomData;
    _setupWebSocketListener();
    _fetchRoomDetails();
  }

  void _setupWebSocketListener() {
    print("Reading webscoket");
    ref.read(webSocketServiceProvider).messageStream.listen((data) {
      if (data['action'] == 'room_details' ||
          data['action'] == 'user_removed' ||
          data['action'] == 'status_updated' ||
          data['action'] == 'progress_updated' ||
          data['action'] == 'user_joined') {
        try {
          final newRoomData = RoomData.fromJson(data['room_data']);
          setState(() {
            roomData = newRoomData;
            print('Room data updated: ${data['action']}');
          });

          // Log the changes
          if (data['action'] == 'status_updated') {
            final oldStatus = roomData.users[data['user_id']]?.status;
            print(
                'RoomDetails: User ${data['user_id']} status changed from $oldStatus to ${data['status']}');
          } else if (data['action'] == 'progress_updated') {
            final oldProgress = roomData.users[data['user_id']]?.swipeProgress;
            print(
                'RoomDetails: User ${data['user_id']} progress updated from $oldProgress to ${data['progress']}/${data['total']}');
          } else if (data['action'] == 'user_joined') {
            print('RoomDetails: User joined - updated user list');
          }
        } catch (e) {
          print("Error parsing room data: $e");
        }
      }
    });
  }

  Future<void> _fetchRoomDetails() async {
    ref.read(webSocketServiceProvider).getRoomDetails(roomData.code);
  }

  void _removeUser(String userId) {
    ref.read(webSocketServiceProvider).removeUser(userId);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    int? selectedMovieIndex;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          roomData.name,
          style: GoogleFonts.fredoka(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_outline),
                    const SizedBox(width: 6),
                    Text('${roomData.users.length}'),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('CODE',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        )),
                    Text(
                      '${roomData.code}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w300, fontSize: 20),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoomSettingsPage(
                          roomId: roomData.id,
                          roomName: roomData.name,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const CustomDottedDivider(color: AppColors.primary),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                ),
                BoxShadow(
                  color: Colors.white,
                  spreadRadius: -2.0,
                  blurRadius: 5.0,
                ),
              ],
            ),
            child: Column(
              children: [
                // Headers
                const Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Username',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Status',
                        style: TextStyle(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Progress',
                        style: TextStyle(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const CustomDottedDivider(color: AppColors.primary),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: roomData.users.length,
                    separatorBuilder: (context, index) => Column(
                      children: [
                        const SizedBox(height: 8),
                        CustomDottedDivider(color: Colors.grey),
                        const SizedBox(height: 8),
                      ],
                    ),
                    itemBuilder: (context, index) {
                      final user = roomData.users.entries.elementAt(index);
                      final isHost = user.value.isHost;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Text(
                              isHost ? 'You (Host)' : user.value.name,
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: StatusBadge(
                                status: user.value.status,
                              ),
                            ),
                          ),
                          ProgressTracker(user: user)
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SizedBox(
              width: 350,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    // Show loading
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    // Get recommendations
                    final recommendations =
                        await _recommendationService.getRecommendationsForRoom(
                      roomId: roomData.id,
                      roomCode: roomData.code,
                      userIds: roomData.users.keys.toList(),
                    );

                    // Hide loading
                    if (context.mounted) {
                      Navigator.pop(context);

                      // Show recommendations in a dialog
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => StatefulBuilder(
                          builder: (context, setState) {
                            int? selectedMovieIndex;

                            return AlertDialog(
                              title: Column(
                                children: [
                                  const Text(
                                    'Group Recommendations',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    'Choose the movie you prefer',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                              content: Container(
                                width: MediaQuery.of(context).size.width * 0.8,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Divider(thickness: 1),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      height:
                                          280, // Fixed height for scrollable area
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: recommendations.length,
                                        itemBuilder: (context, index) {
                                          final movie = recommendations[index];

                                          return Container(
                                            width:
                                                180, // Fixed width for each movie card
                                            margin: EdgeInsets.symmetric(
                                                horizontal: 8),
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  selectedMovieIndex = index;
                                                });
                                              },
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    height:
                                                        180, // Fixed height for poster
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      image: DecorationImage(
                                                        image: NetworkImage(
                                                          'https://image.tmdb.org/t/p/original${movie['poster_path']}',
                                                        ),
                                                        fit: BoxFit.cover,
                                                      ),
                                                      border:
                                                          selectedMovieIndex ==
                                                                  index
                                                              ? Border.all(
                                                                  color: AppColors
                                                                      .primary,
                                                                  width: 2)
                                                              : null,
                                                      boxShadow:
                                                          selectedMovieIndex ==
                                                                  index
                                                              ? [
                                                                  BoxShadow(
                                                                    color: AppColors
                                                                        .primary
                                                                        .withOpacity(
                                                                            0.3),
                                                                    blurRadius:
                                                                        8,
                                                                    spreadRadius:
                                                                        2,
                                                                  )
                                                                ]
                                                              : null,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Container(
                                                    height: 40,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 4),
                                                    child: Text(
                                                      movie['title'],
                                                      textAlign:
                                                          TextAlign.center,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.star_rounded,
                                                        color: Colors.orange,
                                                        size: 20,
                                                      ),
                                                      Text(
                                                        ' ${movie['vote_average']}/10',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              Colors.grey[800],
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Match: ${(movie['final_score'] * 100).toStringAsFixed(0)}%',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Skip'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {},
                                      // onPressed: selectedMovieIndex != null
                                      //     ? () {
                                      //         final selectedMovie =
                                      //             recommendations[
                                      //                 selectedMovieIndex!];
                                      //         ref
                                      //             .read(
                                      //                 webSocketServiceProvider)
                                      //             .sendMessage({
                                      //           'action': 'movie_selected',
                                      //           'room_code': roomData.code,
                                      //           'movie_id':
                                      //               selectedMovie['movie_id'],
                                      //         });
                                      //         Navigator.pop(context);
                                      //       }
                                      // : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 12),
                                      ),
                                      child: const Text(
                                        'Choose This',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      );
                    }
                  } catch (e) {
                    // Hide loading if showing
                    if (context.mounted) {
                      Navigator.pop(context);

                      // Show error
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Error getting recommendations: $e')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Get Recommendations',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 70),
            child: SizedBox(
              width: 350,
              child: ElevatedButton(
                onPressed: () async {
                  if (user?.uid != null) {
                    try {
                      // Check if room preferences exist
                      final url = Platform.isAndroid
                          ? 'http://10.0.2.2:8000/rooms/${roomData.id}/preferences'
                          : 'http://localhost:8000/rooms/${roomData.id}/preferences';

                      final response = await http.get(Uri.parse(url));
                      final data = json.decode(response.body);

                      if (data['preferences'] == null) {
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Room Settings Required'),
                              content: Text(
                                  'Please set up room preferences before starting to swipe.'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context); // Close dialog
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RoomSettingsPage(
                                          roomId: roomData.id,
                                          roomName: roomData.name,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text('Go to Settings'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Cancel'),
                                ),
                              ],
                            ),
                          );
                        }
                        return;
                      }

                      // If preferences exist, proceed to swipe screen
                      final movieProvider =
                          StateNotifierProvider<MovieNotifier, MovieState>(
                              (ref) {
                        return MovieNotifier(
                          roomId: roomData.id,
                          userId: user!.uid,
                        );
                      });
                      final interactionService = InteractionService();
                      await interactionService.storeRoomCode(roomData.code);

                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SwipeScreen(
                              movieProvider: movieProvider,
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Error checking room settings: ${e.toString()}')),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Start Swiping',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomDottedDivider extends StatelessWidget {
  final Color color;

  const CustomDottedDivider({
    Key? key,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = 350;
        final double dashWidth = 4.0;
        final double dashSpace = 4.0;
        final int dashCount = (width / (dashWidth + dashSpace)).floor();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
            (index) => Container(
              width: dashWidth,
              height: 1,
              color: color,
            ),
          ),
        );
      },
    );
  }
}
