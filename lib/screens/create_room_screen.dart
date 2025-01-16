import 'dart:async';

import 'package:fliccsy/models/room_data.dart';
import 'package:fliccsy/screens/lobby_screen.dart';
import 'package:fliccsy/screens/room_details_screen.dart';
import 'package:fliccsy/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateRoomScreen extends ConsumerStatefulWidget {
  final VoidCallback onBackPressed;

  const CreateRoomScreen({
    super.key,
    required this.onBackPressed,
  });

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  final TextEditingController _roomNameController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  void _handleCreateRoom() async {
    final roomName = _roomNameController.text.trim();
    if (roomName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a name for your room'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final wsService = ref.read(webSocketServiceProvider);
      await wsService.createRoom(roomName: roomName);

      // Listen for the room created response
      final roomCreatedCompleter = Completer<RoomData>();
      final subscription = wsService.messageStream.listen((data) {
        if (data['action'] == 'room_created') {
          roomCreatedCompleter.complete(RoomData.fromJson(data['room_data']));
        }
      });

      final roomData = await roomCreatedCompleter.future;
      subscription.cancel();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => RoomDetailsScreen(
              initialRoomData: roomData,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create room'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
            widget.onBackPressed();
          },
        ),
        elevation: 0,
        title: Text(
          "Create Room",
          style: GoogleFonts.fredoka(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              Text(
                'Name Your Watch \nParty',
                style: GoogleFonts.fredoka(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Image.asset(
                'assets/images/create_room_image.png',
                height: 250,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              Text(
                "What's the vibe of this \nmovie session...",
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  color: AppColors.darkAccent,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                cursorColor: AppColors.primary,
                controller: _roomNameController,
                decoration: InputDecoration(
                  hintText: 'Enter a name',
                  filled: false,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 0.2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(
                height: 64,
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleCreateRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Start Flicking',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
