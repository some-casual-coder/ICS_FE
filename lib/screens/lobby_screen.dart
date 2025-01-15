// lib/screens/lobby_screen.dart
import 'package:fliccsy/providers/auth_provider.dart';
import 'package:fliccsy/services/websockets/location_service.dart';
import 'package:fliccsy/services/websockets/websocket_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final webSocketServiceProvider = Provider((ref) => WebSocketService());
final locationServiceProvider = Provider((ref) => LocationService());

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

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

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> nearbyRooms = [];
  bool isHost = false;
  String? roomCode;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _setupWebSocket();
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

  Future<void> _scanNearbyRooms() async {
    setState(() {
      isLoading = true;
      nearbyRooms = []; // Clear previous results
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

  void _showLocationError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Location Access Required'),
        content:
            Text('Please enable location services to scan for nearby rooms.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showJoinRequest(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Join Request'),
        content: Text('$userName wants to join the room'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(webSocketServiceProvider).approveUser(userId);
            },
            child: Text('Approve'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Deny'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wsConnection = ref.watch(webSocketConnectionProvider);
    return wsConnection.when(
      data: (wsService) => Scaffold(
        appBar: AppBar(
          title: const Text('Lobby'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (roomCode == null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () =>
                                ref.read(webSocketServiceProvider).createRoom(),
                            child: Text('Create Room'),
                          ),
                          ElevatedButton(
                            onPressed: _scanNearbyRooms,
                            child: Text('Scan Nearby Rooms'),
                          ),
                        ],
                      ),
                      if (isLoading)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      if (nearbyRooms.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: nearbyRooms.length,
                          itemBuilder: (context, index) {
                            final room = nearbyRooms[index];
                            return ListTile(
                              title: Text('Room ${room['code']}'),
                              subtitle: Text(
                                  '${room['user_count']} users | ${room['distance'].toStringAsFixed(1)} km away'),
                              onTap: () => ref
                                  .read(webSocketServiceProvider)
                                  .joinRoom(room['code']),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              if (roomCode != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Room Code: $roomCode'),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Users',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: users.isEmpty
                            ? const Center(
                                child: Text('No users in the room'),
                              )
                            : ListView.builder(
                                itemCount: users.length,
                                itemBuilder: (context, index) {
                                  final user = users[index];
                                  return ListTile(
                                    title: Text(user['name']),
                                    trailing: isHost && !user['is_host']
                                        ? IconButton(
                                            icon: Icon(Icons.remove_circle),
                                            onPressed: () => ref
                                                .read(webSocketServiceProvider)
                                                .removeUser(user['id']),
                                          )
                                        : null,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Error connecting: $error'),
        ),
      ),
    );
  }
}
