import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/gift.dart';
import '../models/seat.dart';
import '../models/room.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS/Web
  // For physical device, use your machine's IP address (e.g. 192.168.1.x)
  // static const String baseUrl = 'http://10.0.2.2/viplive/backend';
  static const String baseUrl = 'https://operasyon.milatsoft.com';

  // Login
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'error': 'Server error'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Register
  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    String gender = '',
    String country = '',
    String dob = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
          'gender': gender,
          'country': country,
          'dob': dob,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'error': 'Server error'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Get seats for a room
  Future<List<Seat>> getRoomSeats(int roomId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_room_seats.php?room_id=$roomId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Seat.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load seats');
      }
    } catch (e) {
      throw Exception('Error fetching seats: $e');
    }
  }

  // Get user wallet
  Future<Map<String, dynamic>> getWallet(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_wallet.php?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error'] != null) {
          throw Exception(data['error']);
        }
        return {
          'diamonds': int.tryParse(data['diamonds'].toString()) ?? 0,
          'beans': int.tryParse(data['beans'].toString()) ?? 0,
        };
      } else {
        throw Exception('Failed to load wallet');
      }
    } catch (e) {
      debugPrint('Error getting wallet: $e');
      return {'diamonds': 0, 'beans': 0};
    }
  }

  // Get user profile
  Future<Map<String, dynamic>> getUserProfile(
    int userId, {
    int? currentUserId,
  }) async {
    try {
      String url = '$baseUrl/get_user_profile.php?user_id=$userId';
      if (currentUserId != null) {
        url += '&current_user_id=$currentUserId';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error'] != null) {
          throw Exception(data['error']);
        }
        return data;
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      debugPrint('Error getting profile: $e');
      return {}; // Return empty map or handle error
    }
  }

  // Send chat message
  Future<bool> sendMessage(
    int roomId,
    int userId,
    String content, {
    String type = 'text',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send_message.php'),
        body: json.encode({
          'room_id': roomId,
          'user_id': userId,
          'content': content,
          'type': type,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  // Get chat messages
  Future<List<Map<String, dynamic>>> getMessages(
    int roomId, {
    int afterId = 0,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/get_messages.php?room_id=$roomId&after_id=$afterId',
        ),
      );

      if (response.statusCode == 200) {
        try {
          return List<Map<String, dynamic>>.from(json.decode(response.body));
        } catch (e) {
          debugPrint('JSON Decode Error (getMessages): ${response.body}');
          return [];
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error getting messages: $e');
      return [];
    }
  }

  // Send Gift
  Future<bool> sendGift({
    required int roomId,
    required int senderId,
    required int receiverId,
    required int giftId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send_gift.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'room_id': roomId,
          'sender_id': senderId,
          'receiver_id': receiverId,
          'gift_id': giftId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Error sending gift: $e');
      return false;
    }
  }

  // Get active rooms
  Future<List<Room>> getRooms({String? type}) async {
    try {
      String url = '$baseUrl/get_rooms.php';
      if (type != null) {
        url += '?type=$type';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Room.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load rooms');
      }
    } catch (e) {
      debugPrint('Error getting rooms: $e');
      return [];
    }
  }

  // Create Room
  Future<Map<String, dynamic>> createRoom({
    required int hostId,
    required String title,
    required String type,
    String tag = 'Chat',
    String? coverImage,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create_room.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'host_id': hostId,
          'title': title,
          'type': type,
          'tag': tag,
          'cover_image': coverImage ?? '',
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create room');
      }
    } catch (e) {
      throw Exception('Error creating room: $e');
    }
  }

  // Update Seat
  Future<Map<String, dynamic>> updateSeat({
    required int roomId,
    required int seatIndex,
    required int userId,
    required String action, // 'sit', 'leave', 'lock', 'unlock'
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update_seat.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'room_id': roomId,
          'seat_index': seatIndex,
          'user_id': userId,
          'action': action,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update seat');
      }
    } catch (e) {
      throw Exception('Error updating seat: $e');
    }
  }

  // End Room
  Future<bool> endRoom(int roomId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/end_room.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'room_id': roomId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Error ending room: $e');
      return false;
    }
  }

  // Follow User
  Future<Map<String, dynamic>> followUser({
    required int followerId,
    required int followingId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/follow_user.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'follower_id': followerId,
          'following_id': followingId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to follow user');
      }
    } catch (e) {
      throw Exception('Error following user: $e');
    }
  }

  // Join Room Audience
  Future<void> joinRoomAudience(int roomId, int userId) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/join_room.php'),
        body: json.encode({'room_id': roomId, 'user_id': userId}),
      );
    } catch (e) {
      debugPrint('Error joining audience: $e');
    }
  }

  // Leave Room Audience
  Future<void> leaveRoomAudience(int roomId, int userId) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/leave_room.php'),
        body: json.encode({'room_id': roomId, 'user_id': userId}),
      );
    } catch (e) {
      debugPrint('Error leaving audience: $e');
    }
  }

  // Get Room Audience
  Future<List<Map<String, dynamic>>> getRoomAudience(int roomId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_room_audience.php?room_id=$roomId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching audience: $e');
      return [];
    }
  }

  // Get Gifts
  Future<List<Gift>> getGifts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/get_gifts.php'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Gift.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load gifts');
      }
    } catch (e) {
      debugPrint('Error getting gifts: $e');
      return [];
    }
  }

  // Get Transactions
  Future<List<Map<String, dynamic>>> getTransactions(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_transactions.php?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting transactions: $e');
      return [];
    }
  }

  // Search
  Future<Map<String, dynamic>> search(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search.php?q=$query'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'users': [], 'rooms': []};
    } catch (e) {
      debugPrint('Error searching: $e');
      return {'users': [], 'rooms': []};
    }
  }

  // Send DM
  Future<bool> sendDM(int senderId, int receiverId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send_dm.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'sender_id': senderId,
          'receiver_id': receiverId,
          'content': content,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Error sending DM: $e');
      return false;
    }
  }

  // Get DMs
  Future<List<Map<String, dynamic>>> getDMs(
    int user1Id,
    int user2Id, {
    int afterId = 0,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/get_dms.php?user1_id=$user1Id&user2_id=$user2Id&after_id=$afterId',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting DMs: $e');
      return [];
    }
  }

  // Get Conversations
  Future<List<Map<String, dynamic>>> getConversations(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_conversations.php?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting conversations: $e');
      return [];
    }
  }
}
