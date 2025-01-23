class UserData {
  final String name;
  final bool isHost;
  final String status;
  final int? swipeProgress;
  final int? totalMovies;

  UserData({
    required this.name,
    required this.isHost,
    required this.status,
    this.swipeProgress = 0,
    this.totalMovies = 0,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    print('UserData.fromJson received: $json');
    final userData = UserData(
      name: json['name'] as String? ?? '',
      isHost: json['is_host'] as bool? ?? false,
      status: json['status'] as String? ?? '',
      swipeProgress: json['swipe_progress'] as int?,
      totalMovies: json['total_movies'] as int?,
    );
    print(
        'UserData created with progress: ${userData.swipeProgress}/${userData.totalMovies}');
    return userData;
  }
}
