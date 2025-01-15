class User {
  final String id;
  final String name;
  final bool isHost;

  User({
    required this.id,
    required this.name,
    this.isHost = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      isHost: json['is_host'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'is_host': isHost,
      };
}

class Room {
  final String id;
  final String code;
  final String hostId;
  final Map<String, User> users;
  final Map<String, User> pendingUsers;

  Room({
    required this.id,
    required this.code,
    required this.hostId,
    required this.users,
    required this.pendingUsers,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      code: json['code'],
      hostId: json['host_id'],
      users: Map<String, User>.from(
        json['users'].map((key, value) => MapEntry(key, User.fromJson(value))),
      ),
      pendingUsers: Map<String, User>.from(
        json['pending_users']
            .map((key, value) => MapEntry(key, User.fromJson(value))),
      ),
    );
  }
}
