import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/gift_bottom_sheet.dart';

import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/zego_service.dart';
import '../models/seat.dart';
import '../services/api_service.dart';
import 'profile_screen.dart';

class ChatPartyScreen extends StatefulWidget {
  final String roomTitle;
  final int?
  roomId; // Made optional for backward compatibility, but should be passed

  const ChatPartyScreen({super.key, required this.roomTitle, this.roomId});

  @override
  State<ChatPartyScreen> createState() => _ChatPartyScreenState();
}

class _ChatPartyScreenState extends State<ChatPartyScreen> {
  final ApiService _apiService = ApiService();
  List<Seat> _seats = [];
  bool _isLoadingSeats = false;
  Timer? _pollingTimer;
  Timer? _chatPollingTimer;
  Timer? _audiencePollingTimer;

  List<Map<String, dynamic>> _audience = []; // Real audience data

  // Gift Combo State
  int _comboCount = 0;
  Timer? _comboTimer;
  String _lastGiftName = "";
  String _lastSenderName = "";
  bool _showCombo = false;
  bool _showSideBanner = false;

  final List<dynamic> _messages =
      []; // Changed to dynamic to support both Map and String
  int _lastMessageId = 0;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    if (widget.roomId != null) {
      _fetchSeats();
      _fetchMessages();
      _joinAudience();

      // Start polling for seats and chat
      _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        _fetchSeats(background: true);
      });
      _chatPollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        _fetchMessages(background: true);
      });
      _audiencePollingTimer = Timer.periodic(const Duration(seconds: 5), (
        timer,
      ) {
        _fetchAudience();
      });

      // Join Voice Room
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _joinVoiceRoom();
      });
    }
  }

  Future<void> _joinVoiceRoom() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final zegoService = ZegoService();
    final currentUser = userProvider.currentUser;

    if (currentUser != null && widget.roomId != null) {
      await zegoService.loginRoom(
        widget.roomId.toString(),
        currentUser.id.toString(),
        currentUser.username,
        isHost:
            false, // Party members are not "Host" in video sense, but can publish audio
      );

      // In Party mode, usually we auto-publish audio if seated, or listen if audience
      // Logic handled in _fetchSeats or seat tap
    }
  }

  Future<void> _fetchSeats({bool background = false}) async {
    if (!background) setState(() => _isLoadingSeats = true);
    try {
      final seats = await _apiService.getRoomSeats(widget.roomId!);
      if (mounted) {
        setState(() {
          _seats = seats;
          if (!background) _isLoadingSeats = false;
        });

        // Audio Logic
        // final zegoService = Provider.of<ZegoService>(context, listen: false);
        // final userProvider = Provider.of<UserProvider>(context, listen: false);
        // final currentUser = userProvider.currentUser;
        //
        // if (currentUser != null) {
        //   bool amISeated = seats.any((s) => s.user?.id == currentUser.id);
        //
        //   if (!amISeated) {
        //     // If I am not in any seat, I should be a listener (stop publishing)
        //     zegoService.stopPublishingStream();
        //   } else {
        //     // If I am seated, I should be able to publish.
        //     // We rely on the Mic Toggle button for actual mute/unmute.
        //     // But we need to ensure the stream is published initially if not already.
        //     // For now, let's assume joinRoom started publishing and we just toggle mute.
        //     // If we were a listener and now seated, we might need to start publishing.
        //     // zegoService.startPublishingStream(currentUser.id.toString());
        //   }
        // }
      }
    } catch (e) {
      debugPrint('Error loading seats: $e');
      if (mounted && !background) setState(() => _isLoadingSeats = false);
    }
  }

  Future<void> _joinAudience() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    if (currentUser != null && widget.roomId != null) {
      await _apiService.joinRoomAudience(widget.roomId!, currentUser.id);
      _fetchAudience();
    }
  }

  Future<void> _fetchAudience() async {
    if (widget.roomId == null) return;
    try {
      final audience = await _apiService.getRoomAudience(widget.roomId!);
      if (mounted) {
        setState(() {
          _audience = audience;
        });
      }
    } catch (e) {
      debugPrint('Error fetching audience: $e');
    }
  }

  // Mock Audience removed

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _chatPollingTimer?.cancel();
    _audiencePollingTimer?.cancel();
    _comboTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();

    // Leave audience
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    if (currentUser != null && widget.roomId != null) {
      // Fire and forget, don't await in dispose
      _apiService.leaveRoomAudience(widget.roomId!, currentUser.id);
    }

    // Only destroy if we are leaving the screen entirely, not just pushing a new route
    // But for now, let's keep it simple and leave room on dispose
    final zegoService = ZegoService();
    if (zegoService.isInRoom) {
      zegoService.logoutRoom();
    }
    super.dispose();
  }

  Future<void> _fetchMessages({bool background = false}) async {
    if (widget.roomId == null) return;
    try {
      final messages = await ApiService().getMessages(
        widget.roomId!,
        afterId: _lastMessageId,
      );
      if (messages.isNotEmpty) {
        if (mounted) {
          setState(() {
            _messages.addAll(messages);
            _lastMessageId =
                int.tryParse(messages.last['id'].toString()) ?? _lastMessageId;
          });

          // Check for gift messages to trigger combo
          for (var msg in messages) {
            if (msg['type'] == 'gift') {
              _triggerGiftCombo(msg['content'], msg['username'] ?? 'User');
            }
          }

          // Scroll to bottom
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    }
  }

  void _triggerGiftCombo(String content, String senderName) {
    // Content is like "sent Ferrari"
    String giftName = content.replaceFirst('sent ', '');

    setState(() {
      // Combo Logic
      if (_lastGiftName == giftName &&
          _lastSenderName == senderName &&
          (_showCombo || _showSideBanner)) {
        _comboCount++;
        _comboTimer?.cancel();
      } else {
        _comboCount = 1;
        _lastGiftName = giftName;
        _lastSenderName = senderName;
        _showCombo = true;
        _showSideBanner = false;
      }

      // Show side banner if combo > 5
      if (_comboCount >= 5) {
        _showSideBanner = true;
        _showCombo = false;
      }

      // Hide combo after 3 seconds of inactivity
      _comboTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showCombo = false;
            _showSideBanner = false;
          });
        }
      });
    });
  }

  Future<void> _sendMessage({
    String? customContent,
    String customType = 'text',
  }) async {
    final currentUser =
        Provider.of<UserProvider>(context, listen: false).currentUser;
    if (currentUser == null || widget.roomId == null) return;

    String content = customContent ?? _messageController.text.trim();
    if (content.isEmpty) return;

    if (customContent == null) {
      // Only block UI for manual messages
      if (_isSending) return;
      setState(() => _isSending = true);
      _messageController.clear(); // Optimistic clear
    }

    try {
      final success = await ApiService().sendMessage(
        widget.roomId!,
        currentUser.id,
        content,
        type: customType,
      );

      if (success) {
        _fetchMessages(background: true); // Fetch immediately
      } else if (customContent == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send message')),
          );
          _messageController.text = content; // Restore text
        }
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
    } finally {
      if (customContent == null && mounted) setState(() => _isSending = false);
    }
  }

  // _addGiftMessage removed as it is now handled by backend messages

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double designWidth = 414.0;
    final double designHeight = 896.0;

    double w(double width) => width * (screenSize.width / designWidth);
    double h(double height) => height * (screenSize.height / designHeight);

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1519681393784-d120267933ba?auto=format&fit=crop&w=800&q=80',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Dark Overlay
          Container(color: Colors.black.withValues(alpha: 0.7)),

          // Layer 3: Central Combo Animation
          if (_showCombo)
            Align(
              alignment: Alignment.center,
              child: AnimatedScale(
                scale: 1.0 + (_comboCount % 5) * 0.1, // Pulse effect
                duration: const Duration(milliseconds: 100),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _lastGiftName,
                      style: TextStyle(
                        color: Colors.pinkAccent,
                        fontSize: w(24),
                        fontWeight: FontWeight.bold,
                        shadows: const [
                          Shadow(color: Colors.black, blurRadius: 10),
                        ],
                      ),
                    ),
                    Text(
                      'x$_comboCount',
                      style: TextStyle(
                        color: Colors.yellowAccent,
                        fontSize: w(48),
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        shadows: const [
                          Shadow(color: Colors.red, offset: Offset(2, 2)),
                          Shadow(color: Colors.black, blurRadius: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Layer 4: Side Combo Banner
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            left: _showSideBanner ? 0 : -300,
            top: h(300),
            child: Container(
              padding: EdgeInsets.fromLTRB(w(16), h(8), w(32), h(8)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withValues(alpha: 0.9),
                    Colors.red.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(5, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: w(20),
                    backgroundImage: const NetworkImage(
                      'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
                    ),
                  ),
                  SizedBox(width: w(10)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _lastSenderName,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: w(14),
                        ),
                      ),
                      Text(
                        'Sent $_lastGiftName',
                        style: TextStyle(
                          color: Colors.yellowAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: w(12),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: w(20)),
                  Text(
                    'x$_comboCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: w(32),
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 5),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(w, h),

                SizedBox(height: h(20)),

                // Seats Grid (2 rows of 5)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: w(10)),
                    child:
                        _isLoadingSeats
                            ? const Center(child: CircularProgressIndicator())
                            : GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 5,
                                    crossAxisSpacing: w(10),
                                    mainAxisSpacing: h(20),
                                    childAspectRatio: 0.7,
                                  ),
                              itemCount: 10,
                              itemBuilder: (context, index) {
                                return _buildSeat(index, w);
                              },
                            ),
                  ),
                ),

                // Bottom Section
                Column(
                  children: [
                    // Chat Area
                    Container(
                      height: h(200),
                      padding: EdgeInsets.symmetric(horizontal: w(16)),
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final msg = _messages[index];
                                String content = '';
                                String username = '';
                                String type = 'text';

                                if (msg is String) {
                                  content = msg;
                                  type = 'system';
                                } else if (msg is Map) {
                                  content = msg['content'] ?? '';
                                  username = msg['username'] ?? 'User';
                                  type = msg['type'] ?? 'text';
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          if (username.isNotEmpty)
                                            TextSpan(
                                              text: '$username: ',
                                              style: TextStyle(
                                                color: Colors.yellowAccent,
                                                fontWeight: FontWeight.bold,
                                                fontSize: w(12),
                                              ),
                                            ),
                                          TextSpan(
                                            text: content,
                                            style: TextStyle(
                                              color:
                                                  type == 'gift'
                                                      ? Colors.pinkAccent
                                                      : Colors.white,
                                              fontSize: w(12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: h(10)),
                          // Input Field (Visible to everyone)
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: TextField(
                                    controller: _messageController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'Bir şeyler söyle...',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                        fontSize: w(14),
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: w(16),
                                        vertical: h(10),
                                      ),
                                    ),
                                    onSubmitted: (_) => _sendMessage(),
                                  ),
                                ),
                              ),
                              SizedBox(width: w(10)),
                              GestureDetector(
                                onTap: _sendMessage,
                                child: Container(
                                  padding: EdgeInsets.all(w(10)),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE65E8B),
                                    shape: BoxShape.circle,
                                  ),
                                  child:
                                      _isSending
                                          ? SizedBox(
                                            width: w(20),
                                            height: w(20),
                                            child:
                                                const CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                          )
                                          : Icon(
                                            Icons.send,
                                            color: Colors.white,
                                            size: w(20),
                                          ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Bottom Actions Bar
                    _buildBottomBar(w, h),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(double Function(double) w, double Function(double) h) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w(16), vertical: h(10)),
      child: Row(
        children: [
          // Host Info
          Container(
            padding: EdgeInsets.all(w(4)),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: w(16),
                  backgroundImage: const NetworkImage(
                    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=100&q=80',
                  ),
                ),
                SizedBox(width: w(8)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alexander',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: w(12),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'ID: 123456',
                      style: TextStyle(color: Colors.white70, fontSize: w(10)),
                    ),
                  ],
                ),
                SizedBox(width: w(8)),
                Container(
                  padding: EdgeInsets.all(w(4)),
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add, color: Colors.black, size: w(12)),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Audience List
          SizedBox(
            height: w(32),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: _audience.length,
              itemBuilder: (context, index) {
                final user = _audience[index];
                return Padding(
                  padding: EdgeInsets.only(right: w(4)),
                  child: GestureDetector(
                    onTap: () {
                      // Show profile on tap
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder:
                            (context) => ProfileScreen(
                              userId: int.tryParse(user['id'].toString()) ?? 0,
                            ),
                      );
                    },
                    child: CircleAvatar(
                      radius: w(16),
                      backgroundImage: NetworkImage(
                        user['avatar_url'] ?? 'https://i.pravatar.cc/150',
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(width: w(10)),

          // Close Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(w(6)),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: Colors.white, size: w(18)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSeatTap(int index, Seat? seatData) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    if (currentUser == null || widget.roomId == null) return;

    bool isOccupied = seatData?.user != null;
    bool isLocked = seatData?.isLocked ?? false;
    bool isMe = seatData?.user?.id == currentUser.id;

    if (isMe) {
      // If I'm sitting here, ask to leave
      _showActionDialog('Koltuktan Kalk?', () => _updateSeat(index, 'leave'));
    } else if (isOccupied) {
      // Show user profile bottom sheet
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder:
            (context) => Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(seatData!.user!.avatarUrl),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    seatData.user!.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE65E8B).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE65E8B).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      'Level ${seatData.user!.level}',
                      style: const TextStyle(
                        color: Color(0xFFE65E8B),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close profile sheet
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder:
                              (context) => GiftBottomSheet(
                                onSendGift: (gift) async {
                                  final apiService = ApiService();

                                  // Check if roomId is valid
                                  int roomId = widget.roomId ?? 0;
                                  if (roomId == 0) return;

                                  bool success = await apiService.sendGift(
                                    roomId: roomId,
                                    senderId: currentUser.id,
                                    receiverId: seatData!.user!.id,
                                    giftId: gift['id'],
                                  );

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    if (success) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${seatData.user!.username} kullanıcısına ${gift['name']} gönderildi!',
                                          ),
                                        ),
                                      );
                                      // Send gift message to chat
                                      try {
                                        await apiService.sendMessage(
                                          roomId,
                                          currentUser.id,
                                          "sent ${gift['name']}",
                                        );
                                      } catch (e) {
                                        debugPrint(
                                          'Error sending gift message: $e',
                                        );
                                      }
                                      _fetchMessages(background: true);
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Hediye gönderilemedi (Yetersiz bakiye olabilir)',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFFFFD700,
                        ), // Gold for gift
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Hediye Gönder",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close sheet
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    ProfileScreen(userId: seatData.user!.id),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE65E8B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Profili Görüntüle",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
      );
    } else if (isLocked) {
      // If locked, only host can unlock
      if (currentUser.isHost) {
        _showActionDialog('Kilidi Aç?', () => _updateSeat(index, 'unlock'));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bu koltuk kilitli')));
      }
    } else {
      // Empty seat
      if (currentUser.isHost) {
        // Host can sit or lock
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder:
              (context) => Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Text(
                      'Koltuk Yönetimi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSheetAction(
                      icon: Icons.event_seat,
                      label: 'Otur',
                      color: const Color(0xFFE65E8B),
                      onTap: () {
                        Navigator.pop(context);
                        _updateSeat(index, 'sit');
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSheetAction(
                      icon: Icons.lock_outline,
                      label: 'Kilitle',
                      color: Colors.amber,
                      onTap: () {
                        Navigator.pop(context);
                        _updateSeat(index, 'lock');
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
        );
      } else {
        // Normal user just sits
        _showActionDialog('Otur?', () => _updateSeat(index, 'sit'));
      }
    }
  }

  // ignore: unused_element
  Widget _buildSheetAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateSeat(int index, String action) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You must be logged in')));
      return;
    }

    try {
      final result = await _apiService.updateSeat(
        roomId: widget.roomId!,
        seatIndex: index,
        action: action,
        userId: currentUser.id,
      );

      if (result['success'] == true) {
        // Refresh immediately after action
        _fetchSeats(background: true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${result['error']}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  void _showActionDialog(String title, VoidCallback onConfirm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onConfirm();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFFE65E8B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Confirm',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  Widget _buildSeat(int index, double Function(double) w) {
    // final zegoService = Provider.of<ZegoService>(context); // Removed provider usage
    final currentUser = Provider.of<UserProvider>(context).currentUser;

    // If we have API data, try to find the seat
    Seat? seatData;
    if (_seats.isNotEmpty) {
      try {
        seatData = _seats.firstWhere((s) => s.seatIndex == index);
      } catch (_) {}
    }

    bool isOccupied = seatData?.user != null;
    String label = isOccupied ? (seatData!.user!.username) : 'No.${index + 1}';
    String? avatarUrl = isOccupied ? seatData!.user!.avatarUrl : null;
    bool isLocked = seatData?.isLocked ?? false;

    // Check if this seat is ME
    bool isMe = seatData?.user?.id == currentUser?.id;
    // Show mic status if it's me (since we know local status)
    bool isMicOn = isMe ? ZegoService().isMicOn : false;

    // Mock Talking State (Randomly toggle for effect if mic is on)
    bool isTalking =
        isMicOn && (DateTime.now().millisecondsSinceEpoch % 2000 < 1000);

    return GestureDetector(
      onTap: () => _handleSeatTap(index, seatData),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Wave Animation (Only when talking)
              if (isTalking)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: 1.4),
                  duration: const Duration(milliseconds: 1000),
                  builder: (context, scale, child) {
                    return Container(
                      width: w(50) * scale,
                      height: w(50) * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(
                            0xFF66B4FF,
                          ).withValues(alpha: 1.4 - scale),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),

              Container(
                width: w(50),
                height: w(50),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child:
                    isLocked
                        ? Center(
                          child: Icon(
                            Icons.lock,
                            color: Colors.white.withValues(alpha: 0.5),
                            size: w(24),
                          ),
                        )
                        : isOccupied
                        ? CircleAvatar(
                          backgroundImage: NetworkImage(
                            avatarUrl ?? 'https://i.pravatar.cc/150',
                          ),
                        )
                        : Center(
                          child: Icon(
                            Icons.event_seat, // Sofa icon
                            color: Colors.white.withValues(alpha: 0.5),
                            size: w(24),
                          ),
                        ),
              ),
              // Mic Status Indicator
              if (isOccupied && isMe)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.all(w(2)),
                    decoration: BoxDecoration(
                      color: isMicOn ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                    child: Icon(
                      isMicOn ? Icons.mic : Icons.mic_off,
                      color: Colors.white,
                      size: w(10),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.white, fontSize: w(10)),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(double Function(double) w, double Function(double) h) {
    // final zegoService = Provider.of<ZegoService>(context); // REMOVED

    return Padding(
      padding: EdgeInsets.all(w(16)),
      child: Row(
        children: [
          // Action Buttons
          _buildActionButton(Icons.mail, w),
          SizedBox(width: w(12)),

          // Mic Toggle
          ListenableBuilder(
            listenable: ZegoService(),
            builder: (context, _) {
              bool isMicOn = ZegoService().isMicOn;
              return GestureDetector(
                onTap: () async {
                  await ZegoService().toggleMic();
                },
                child: Container(
                  padding: EdgeInsets.all(w(10)),
                  decoration: BoxDecoration(
                    color:
                        isMicOn
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isMicOn ? Icons.mic : Icons.mic_off,
                    color: isMicOn ? Colors.white : Colors.black,
                    size: w(24),
                  ),
                ),
              );
            },
          ),
          SizedBox(width: w(12)),

          // Gift Button (Highlighted)
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder:
                    (context) => GiftBottomSheet(
                      roomId:
                          widget.roomId ??
                          0, // 0 as fallback or handle properly
                      receiverId: 1, // Default to host (ID: 1) or handle logic
                      onGiftSent: (msg) {
                        // Handled by backend message stream
                      },
                    ),
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
              );
            },
            child: Container(
              padding: EdgeInsets.all(w(10)),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.cyan],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                Icons.card_giftcard,
                color: Colors.white,
                size: w(24),
              ),
            ),
          ),

          SizedBox(width: w(12)),
          _buildActionButton(Icons.emoji_emotions, w),
          SizedBox(width: w(12)),
          _buildActionButton(Icons.more_horiz, w),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, double Function(double) w) {
    return Container(
      padding: EdgeInsets.all(w(10)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: w(24)),
    );
  }
}
