import 'dart:convert';
import 'dart:io';

import 'package:fliccsy/models/movie_state.dart';
import 'package:fliccsy/models/room_data.dart';
import 'package:fliccsy/models/user_data.dart';
import 'package:fliccsy/providers/auth_provider.dart';
import 'package:fliccsy/providers/movie_notifier.dart';
import 'package:fliccsy/screens/lobby_screen.dart';
import 'package:fliccsy/screens/room_settings_screen.dart';
import 'package:fliccsy/screens/swipe_screen.dart';
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

  @override
  void initState() {
    super.initState();
    roomData = widget.initialRoomData;
    _setupWebSocketListener();
    _fetchRoomDetails();
  }

  void _setupWebSocketListener() {
    ref.read(webSocketServiceProvider).messageStream.listen((data) {
      if (data['action'] == 'room_details') {
        setState(() {
          roomData = RoomData.fromJson(data['room_data']);
          print(roomData);
        });
      } else if (data['action'] == 'user_removed') {
        setState(() {
          roomData = RoomData.fromJson(data['room_data']);
        });
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
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: roomData.users.length,
                  separatorBuilder: (context, index) => Column(
                    children: [
                      const SizedBox(height: 8),
                      CustomDottedDivider(color: AppColors.primary),
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
              ],
            ),
          ),
          const Spacer(),
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
                    borderRadius: BorderRadius.circular(20),
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
