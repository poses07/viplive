class Room {
  final int id;
  final String title;
  final String roomType;
  final String hostName;
  final String? hostAvatar;
  final String tag;
  final String? coverImage;
  final DateTime createdAt;

  Room({
    required this.id,
    required this.title,
    required this.roomType,
    required this.hostName,
    this.hostAvatar,
    this.tag = 'Chat',
    this.coverImage,
    required this.createdAt,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? 'Unknown Room',
      roomType: json['room_type'] ?? 'live',
      hostName: json['host_name'] ?? 'Unknown',
      hostAvatar: json['host_avatar'],
      tag: json['tag'] ?? 'Chat',
      coverImage: json['cover_image'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
