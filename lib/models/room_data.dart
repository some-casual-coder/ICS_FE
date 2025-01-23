import 'package:fliccsy/models/user_data.dart';

class RoomData {
  final String id;
  final String code;
  final String name;
  final String host;
  final Map<String, UserData> users;

  RoomData({
    required this.id,
    required this.code,
    required this.name,
    required this.host,
    required this.users,
  });

  factory RoomData.fromJson(Map<String, dynamic> json) {
    print('RoomData.fromJson received: $json');
    print('Users data received: ${json['users']}');

    final roomData = RoomData(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      host: json['host'] as String? ?? '',
      users: (json['users'] as Map<String, dynamic>?)?.map(
            (key, value) {
              print('Processing user $key with data: $value');
              final userData = UserData.fromJson(value as Map<String, dynamic>);
              print(
                  'Created UserData for $key with progress: ${userData.swipeProgress}/${userData.totalMovies}');
              return MapEntry(key, userData);
            },
          ) ??
          {},
    );

    print('RoomData created with ${roomData.users.length} users');
    roomData.users.forEach((key, user) {
      print(
          'User $key has progress: ${user.swipeProgress}/${user.totalMovies}');
    });

    return roomData;
  }
}
