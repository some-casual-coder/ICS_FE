import 'dart:async';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'location_service.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final LocationService _locationService = LocationService();
  String? _userName;

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  bool _isConnected = false;
  Timer? _reconnectTimer;

  void connect(String userName) {
    _userName = userName; // Store username for reconnection
    _attemptConnection();
  }

  void _attemptConnection() {
    String wsUrl;
    if (Platform.isAndroid) {
      wsUrl = 'ws://10.0.2.2:8000/ws/$_userName';
    } else if (Platform.isIOS) {
      wsUrl = 'ws://localhost:8000/ws/$_userName';
    } else {
      wsUrl = 'ws://localhost:8000/ws/$_userName';
    }

    print('Attempting WebSocket connection to: $wsUrl');

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _listen();
    } catch (e) {
      print('Connection error: $e');
      _scheduleReconnect();
    }
  }

  void _listen() {
    print("listening for data");
    _channel?.stream.listen(
      (message) {
        print("got data");
        _isConnected = true;
        final data = jsonDecode(message);
        _messageController.add(data);
      },
      onError: (error) {
        print('WebSocket Error: $error');
        _isConnected = false;
        _scheduleReconnect();
      },
      onDone: () {
        print('WebSocket Connection Closed');
        _isConnected = false;
        _scheduleReconnect();
      },
    );
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), _attemptConnection);
  }

  Future<void> createRoom({String? roomName}) async {
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      _send({
        'action': 'create_room',
        'room_name': roomName,
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
    } else {
      _send({
        'action': 'create_room',
        'room_name': roomName,
      }); // Fallback without location
    }
  }

  Future<void> scanRooms({double maxDistance = 50.0}) async {
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      print("scanning location sending");
      _send({
        'action': 'scan_rooms',
        'latitude': position.latitude,
        'longitude': position.longitude,
        'max_distance': maxDistance,
      });
    } else {
      _send({'action': 'scan_rooms'}); // Fallback without location
    }
  }

  Future<void> getRoomDetails(String roomCode) async {
    _send({
      'action': 'get_room_details',
      'room_code': roomCode,
    });
  }

  void joinRoom(String roomCode) {
    _send({
      'action': 'join_room',
      'room_code': roomCode,
    });
  }

  void approveUser(String userId) {
    _send({
      'action': 'approve_user',
      'user_id': userId,
    });
  }

  void removeUser(String userId) {
    _send({
      'action': 'remove_user',
      'user_id': userId,
    });
  }

  void _send(Map<String, dynamic> data) {
    print('Sending WebSocket message: $data');
    _channel?.sink.add(jsonEncode(data));
  }

  void updateStatus(String status) {
    if (!_isConnected) return;
    _send({
      'action': 'update_status',
      'status': status,
    });
  }

  void updateProgress(int currentCount, int totalCount) {
    if (!_isConnected) return;
    _send({
      'action': 'update_progress',
      'current_count': currentCount,
      'total_count': totalCount,
    });
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _messageController.close();
  }
}
