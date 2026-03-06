class User {
  final int id;
  final String username;
  final String avatarUrl;
  final int level;
  final int diamonds;
  final int beans;
  final bool isHost;

  User({
    required this.id,
    required this.username,
    required this.avatarUrl,
    required this.level,
    required this.diamonds,
    this.beans = 0,
    required this.isHost,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.parse(json['id'].toString()),
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String? ?? '',
      level: int.parse(json['level'].toString()),
      diamonds: int.parse(json['diamonds'].toString()),
      beans: json['beans'] != null ? int.parse(json['beans'].toString()) : 0,
      isHost: (json['is_host'] == '1' || json['is_host'] == 1 || json['is_host'] == true),
    );
  }
}
