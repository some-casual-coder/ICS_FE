// lib/screens/lobby_screen.dart
import 'package:fliccsy/providers/auth_provider.dart';
import 'package:fliccsy/screens/create_room_screen.dart';
import 'package:fliccsy/services/websockets/location_service.dart';
import 'package:fliccsy/services/websockets/websocket_service.dart';
import 'package:fliccsy/theme/app_colors.dart';
import 'package:fliccsy/widgets/room_list_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

final webSocketServiceProvider = Provider((ref) => WebSocketService());
final locationServiceProvider = Provider((ref) => LocationService());

class LobbyScreen extends ConsumerStatefulWidget {
  final VoidCallback onBackPressed;

  const LobbyScreen({
    super.key,
    required this.onBackPressed,
  });

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

final webSocketConnectionProvider = FutureProvider.autoDispose((ref) async {
  final user = await ref.watch(authStateProvider.future);
  final wsService = ref.read(webSocketServiceProvider);
  final userName = user?.displayName ?? 'NewUser';
  print('Connecting with username: $userName');
  wsService.connect(userName);
  return wsService;
});

class _LobbyScreenState extends ConsumerState<LobbyScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> nearbyRooms = [];
  bool isHost = false;
  String? roomCode;
  bool isLoading = false;
  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;
  TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupWebSocket();
    _rippleController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    _rippleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _setupWebSocket() {
    final wsService = ref.read(webSocketServiceProvider);

    wsService.messageStream.listen((data) {
      switch (data['action']) {
        case 'room_created':
          setState(() {
            roomCode = data['room_code'];
            isHost = true;
            users = [
              {'id': data['user_id'], 'name': 'You (Host)', 'is_host': true}
            ];
          });
          break;

        case 'room_list':
          print('Received room list: ${data['rooms']}');
          setState(() {
            nearbyRooms = List<Map<String, dynamic>>.from(data['rooms']);
            isLoading = false;
          });
          _showFoundRooms();
          break;

        case 'user_joined':
          setState(() {
            final roomData = data['room_data'];
            users =
                roomData['users'].entries.map<Map<String, dynamic>>((entry) {
              return {
                'id': entry.key,
                'name': entry.value['name'],
                'is_host': entry.value['is_host'],
              };
            }).toList();
          });
          break;

        case 'join_request':
          if (isHost) {
            _showJoinRequest(data['user_id'], data['user_name']);
          }
          break;

        default:
          print('Received unknown action: ${data['action']}');
      }
    });
  }

  void _showJoinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Align(
          alignment: Alignment.topCenter,
          child: Text(
            'Join Room',
            style: GoogleFonts.fredoka(
              fontSize: 24,
              color: AppColors.darkAccent,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        content: TextField(
          cursorColor: AppColors.primary,
          controller: _codeController,
          decoration: InputDecoration(
            hintText: 'Enter room code',
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.roboto(fontSize: 17)),
          ),
          ElevatedButton(
            onPressed: () {
              final code = _codeController.text.trim();
              if (code.isNotEmpty) {
                ref.read(webSocketServiceProvider).joinRoom(code);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Join',
              style:
                  GoogleFonts.roboto(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scanNearbyRooms() async {
    setState(() {
      isLoading = true;
      nearbyRooms = [];
    });

    try {
      final locationService = ref.read(locationServiceProvider);
      final location = await locationService.getCurrentLocation();

      if (location == null) {
        _showLocationError();
        setState(() {
          isLoading = false;
        });
        return;
      }

      ref.read(webSocketServiceProvider).scanRooms();
    } catch (e) {
      print('Error scanning rooms: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _showLocationError() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Access Required'),
        content: const Text(
            'Please enable location services to scan for nearby rooms.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final locationService = ref.read(locationServiceProvider);
              final permissionGranted =
                  await locationService.requestPermission();

              if (mounted && permissionGranted) {
                _scanNearbyRooms();
              }
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  void _showFoundRooms() {
    if (nearbyRooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No watch parties found nearby',
            style: GoogleFonts.roboto(color: Colors.black, fontSize: 16),
          ),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          margin: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).size.height - 230,
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => RoomListDialog(
        rooms: nearbyRooms,
        onJoinRoom: (roomCode) async {
          ref.read(webSocketServiceProvider).joinRoom(roomCode);
        },
      ),
    );
  }

  void _showJoinRequest(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Join Request',
              style: GoogleFonts.fredoka(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 100,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
        content: Text(
          '$userName wants to join the room',
          style: GoogleFonts.roboto(
            fontSize: 18,
            color: AppColors.darkAccent,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text(
              'Deny',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(webSocketServiceProvider).approveUser(userId);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
            ),
            child: const Text(
              'Approve',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateRoom() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateRoomScreen(
          onBackPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wsConnection = ref.watch(webSocketConnectionProvider);
    return PopScope(
      onPopInvokedWithResult: (didPop, dynamic) async {
        widget.onBackPressed();
        Future<bool>.value(true);
      },
      child: wsConnection.when(
        data: (wsService) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(
              'Lobby',
              style: GoogleFonts.fredoka(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Spacer(),
                  GestureDetector(
                    onTap: _scanNearbyRooms,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 250,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _rippleAnimation,
                                builder: (context, child) {
                                  return Container(
                                    width: 180 * _rippleAnimation.value,
                                    height: 180 * _rippleAnimation.value,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primary.withOpacity(0.2),
                                    ),
                                  );
                                },
                              ),
                              Container(
                                width: 170,
                                height: 170,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary.withOpacity(0.3),
                                ),
                              ),
                              Image.asset(
                                'assets/images/scan_nearby_room.png',
                                width: 150,
                                height: 150,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Scan for nearby rooms',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: _showJoinDialog,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(
                      'Join with code',
                      style: GoogleFonts.roboto(
                          fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _navigateToCreateRoom,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(
                      'Create Room',
                      style: GoogleFonts.roboto(
                          fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
