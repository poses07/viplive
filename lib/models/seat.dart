import 'user.dart';

class Seat {
  final int seatIndex;
  final bool isLocked;
  final User? user;

  Seat({
    required this.seatIndex,
    required this.isLocked,
    this.user,
  });

  factory Seat.fromJson(Map<String, dynamic> json) {
    User? user;
    if (json['user_id'] != null) {
      user = User(
        id: int.parse(json['user_id'].toString()),
        username: json['username'] ?? 'Unknown',
        avatarUrl: json['avatar_url'] ?? '',
        level: 0, // Not returned by this specific API, optional
        diamonds: 0,
        isHost: false, // Can be inferred if seatIndex == 0
      );
    }

    return Seat(
      seatIndex: int.parse(json['seat_index'].toString()),
      isLocked: (json['is_locked'] == '1' || json['is_locked'] == 1 || json['is_locked'] == true),
      user: user,
    );
  }
}
