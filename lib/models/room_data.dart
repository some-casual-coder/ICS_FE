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
    return RoomData(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      host: json['host'] as String? ?? '',
      users: (json['users'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              UserData.fromJson(value as Map<String, dynamic>),
            ),
          ) ??
          {},
    );
  }
}
