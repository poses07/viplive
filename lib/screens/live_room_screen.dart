import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import '../services/api_service.dart';
import '../services/zego_service.dart';
import '../widgets/gift_bottom_sheet.dart';
import '../models/seat.dart';

class LiveRoomScreen extends StatefulWidget {
  final String roomTitle;
  final String roomTag;
  final bool isHost;
  final String userId;
  final String userName;
  final String liveID;

  const LiveRoomScreen({
    super.key,
    required this.roomTitle,
    required this.roomTag,
    this.isHost = false,
    this.userId = 'user_123', // Mock ID for now
    this.userName = 'User',
    this.liveID = 'room_1', // Should be unique per room
  });

  @override
  State<LiveRoomScreen> createState() => _LiveRoomScreenState();
}

class _LiveRoomScreenState extends State<LiveRoomScreen> {
  // App ID and App Sign removed (Zego Removed)

  final TextEditingController _chatController = TextEditingController();
  final List<dynamic> _messages = ['Canlı yayına hoş geldiniz!'];
  bool _isSending = false;
  int _lastMessageId = 0;

  // Seats
  List<Seat> _seats = [];
  Timer? _pollingTimer;

  bool _showEntranceEffect = false;
  String _enteringUserName = "";

  // Gift Combo Logic
  int _comboCount = 0;
  Timer? _comboTimer;
  String _lastGiftName = "";
  String _lastSenderName = "";
  bool _showCombo = false;
  bool _showSideBanner = false;

  @override
  void initState() {
    super.initState();
    // Listen to ZegoService updates
    ZegoService().addListener(_onZegoUpdate);

    // Initialize Zego Service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initZego();
    });

    _fetchSeats();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchSeats();
      _fetchMessages();
    });

    // Simulate entrance effect
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _enteringUserName = "VIP King";
          _showEntranceEffect = true;
          _messages.add("VIP King odaya katıldı");
        });
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) {
            setState(() {
              _showEntranceEffect = false;
            });
          }
        });
      }
    });
  }

  void _onZegoUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _initZego() async {
    final zegoService = ZegoService();
    // Login to room
    await zegoService.loginRoom(
      widget.liveID.replaceAll('room_', ''), // Using numeric ID for room
      widget.userId,
      widget.userName,
      isHost: widget.isHost,
    );

    // Auto-sit if host
    if (widget.isHost) {
      int roomId = int.tryParse(widget.liveID.replaceAll('room_', '')) ?? 0;
      int userId = int.tryParse(widget.userId) ?? 0;
      if (roomId > 0 && userId > 0) {
        await ApiService().updateSeat(
          roomId: roomId,
          seatIndex: 0,
          userId: userId,
          action: 'sit',
        );
        _fetchSeats(); // Refresh seats immediately
      }
    }

    setState(() {}); // Refresh to show video/audio status
  }

  void _addGiftMessage(String message, String giftName) {
    setState(() {
      // Extract sender name
      String senderName = "User";
      try {
        senderName = message.split(" sent ")[0];
      } catch (_) {}

      // Update existing message if it's the same gift/sender
      bool updated = false;
      if (_messages.isNotEmpty) {
        String lastMsg = _messages[0];
        if (lastMsg.startsWith("$senderName sent $giftName")) {
          // Check if it already has a multiplier
          if (lastMsg.contains(" x")) {
            try {
              int count = int.parse(lastMsg.split(" x")[1]);
              _messages[0] = "$senderName sent $giftName x${count + 1}";
              updated = true;
            } catch (_) {}
          } else {
            // First multiplier
            _messages[0] = "$senderName sent $giftName x2";
            updated = true;
          }
        }
      }

      if (!updated) {
        _messages.insert(0, "$senderName sent $giftName x1");
      }

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
        _showCombo = false; // Hide center combo, show side banner instead
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

  @override
  void dispose() {
    ZegoService().removeListener(_onZegoUpdate);
    _pollingTimer?.cancel();
    _comboTimer?.cancel();
    _chatController.dispose();
    ZegoService().logoutRoom(); // Logout when leaving screen
    super.dispose();
  }

  Future<void> _fetchSeats() async {
    try {
      int roomId = int.tryParse(widget.liveID.replaceAll('room_', '')) ?? 0;
      if (roomId == 0) return;

      final seats = await ApiService().getRoomSeats(roomId);
      if (mounted) {
        setState(() {
          _seats = seats;
        });
      }
    } catch (e) {
      debugPrint("Error fetching seats: $e");
    }
  }

  Future<void> _fetchMessages() async {
    try {
      int roomId = int.tryParse(widget.liveID.replaceAll('room_', '')) ?? 0;
      if (roomId == 0) return;

      final messages = await ApiService().getMessages(
        roomId,
        afterId: _lastMessageId,
      );

      if (messages.isNotEmpty) {
        if (mounted) {
          setState(() {
            _messages.addAll(messages);
            _lastMessageId = messages.last['id'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching messages: $e");
    }
  }

  Future<void> _sendMessage() async {
    if (_chatController.text.trim().isEmpty) return;

    if (_isSending) return;
    setState(() => _isSending = true);

    try {
      int roomId = int.tryParse(widget.liveID.replaceAll('room_', '')) ?? 0;
      int userId = int.tryParse(widget.userId) ?? 0;

      bool success = await ApiService().sendMessage(
        roomId,
        userId,
        _chatController.text.trim(),
      );

      if (success) {
        _chatController.clear();
        _fetchMessages(); // Refresh immediately
      }
    } catch (e) {
      debugPrint("Error sending message: $e");
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double designWidth = 414.0;
    final double designHeight = 896.0;

    double w(double width) => width * (screenSize.width / designWidth);
    double h(double height) => height * (screenSize.height / designHeight);

    // Config for Zego REMOVED

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image (Always visible)
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

          // 2. Dark Overlay
          Container(color: Colors.black.withValues(alpha: 0.6)),

          // 3. Zego Video Layer (Custom SDK Implementation)
          // Only show video layer when we are successfully logged into the room
          if (widget.roomTag == 'live' && ZegoService().isInRoom)
            FutureBuilder<Widget?>(
              future: ZegoExpressEngine.instance.createCanvasView((viewID) {
                if (widget.isHost) {
                  ZegoService().startPreview(viewID);
                } else {
                  // Audience plays host stream
                  // Stream ID convention: roomID_host
                  ZegoService().startPlayingStream(
                    "${widget.liveID.replaceAll('room_', '')}_host",
                    viewID,
                  );
                }
              }),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return snapshot.data!;
                }
                return Center(child: CircularProgressIndicator());
              },
            ),

          // 4. Custom Top Bar (Profile Info & Close Button)
          Positioned(
            top: h(50), // Adjust for safe area
            left: w(20),
            right: w(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Host Info (Mock)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: w(8),
                    vertical: h(4),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: w(16),
                        backgroundImage: NetworkImage(
                          "https://i.pravatar.cc/150?u=${widget.userId}",
                        ), // Host Avatar
                      ),
                      SizedBox(width: w(8)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.userName, // Use actual username
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: w(12),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "ID: ${widget.liveID.replaceAll('room_', '')}",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: w(10),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: w(8)),
                      Container(
                        padding: EdgeInsets.all(w(4)),
                        decoration: const BoxDecoration(
                          color: Colors.yellow,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 12,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                // Close Button
                IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(w(6)),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  onPressed: () async {
                    // If Audience, just leave
                    if (!widget.isHost) {
                      Navigator.of(context).pop();
                      return;
                    }

                    // If Host, ask confirmation to end room
                    bool shouldEnd =
                        await showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              backgroundColor: const Color(0xFF1E1E1E),
                              title: const Text(
                                "Yayını Sonlandır",
                                style: TextStyle(color: Colors.white),
                              ),
                              content: const Text(
                                "Yayını bitirmek ve odayı kapatmak istediğinize emin misiniz?",
                                style: TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(false),
                                  child: const Text(
                                    "İptal",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    // Call API to end room
                                    try {
                                      int roomId =
                                          int.tryParse(
                                            widget.liveID.replaceAll(
                                              'room_',
                                              '',
                                            ),
                                          ) ??
                                          0;
                                      if (roomId > 0) {
                                        await ApiService().endRoom(roomId);
                                      }
                                    } catch (e) {
                                      debugPrint("Error ending room: $e");
                                    }
                                    if (context.mounted) {
                                      Navigator.of(context).pop(true);
                                    }
                                  },
                                  child: const Text(
                                    "Bitir",
                                    style: TextStyle(color: Color(0xFFE65E8B)),
                                  ),
                                ),
                              ],
                            );
                          },
                        ) ??
                        false;

                    if (shouldEnd && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
          ),

          // SEAT GRID (Same for Host and Audience)
          Positioned(
            top: h(130), // Lowered to avoid overlap with top bar
            left: w(20),
            right: w(20),
            child: SizedBox(
              height: h(240), // Increased height to fit 2 rows (5x2)
              child: GridView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: w(10),
                  mainAxisSpacing: h(20), // Increased spacing between rows
                  childAspectRatio: 0.7, // Taller aspect ratio for seat+name
                ),
                itemCount: _seats.length, // Should be 10 seats from backend
                itemBuilder: (context, index) {
                  final seat = _seats[index];
                  return GestureDetector(
                    onTap: () async {
                      // Seat Tap Logic (Sit/Leave)
                      int roomId =
                          int.tryParse(widget.liveID.replaceAll('room_', '')) ??
                          0;
                      int userId = int.tryParse(widget.userId) ?? 0;

                      if (seat.user == null) {
                        // Empty seat -> Sit
                        // Note: Real apps might require 'Request to Join' here
                        await ApiService().updateSeat(
                          roomId: roomId,
                          seatIndex: seat.seatIndex,
                          userId: userId,
                          action: 'sit',
                        );
                      } else if (seat.user?.id == userId) {
                        // My seat -> Leave
                        await ApiService().updateSeat(
                          roomId: roomId,
                          seatIndex: seat.seatIndex,
                          userId: userId,
                          action: 'leave',
                        );
                      }
                      _fetchSeats(); // Refresh immediately
                    },
                    child: Column(
                      children: [
                        Container(
                          width: w(40),
                          height: w(40),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  seat.user != null
                                      ? const Color(0xFFE65E8B)
                                      : Colors.white24,
                              width: 1,
                            ),
                          ),
                          child:
                              seat.user != null
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(w(20)),
                                    child: Image.network(
                                      seat.user?.avatarUrl ??
                                          "https://via.placeholder.com/150",
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) => const Icon(
                                            Icons.person,
                                            color: Colors.white,
                                          ),
                                    ),
                                  )
                                  : const Icon(
                                    Icons.add,
                                    color: Colors.white54,
                                    size: 20,
                                  ),
                        ),
                        SizedBox(height: h(4)),
                        Text(
                          seat.user?.username ?? "${seat.seatIndex + 1}",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: w(10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Custom Overlay (Gifts, Entrance, etc.)
          // Note: Zego has its own UI, but we can overlay our custom effects

          // Layer 3: Entrance Effect
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            left: _showEntranceEffect ? 0 : -screenSize.width,
            top: h(150),
            child: Container(
              width: screenSize.width * 0.8,
              padding: EdgeInsets.symmetric(horizontal: w(16), vertical: h(8)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withValues(alpha: 0.8),
                    Colors.blue.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.yellow),
                  SizedBox(width: w(10)),
                  Text(
                    "$_enteringUserName katıldı!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: w(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Layer 5: Combo Animation
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

          // Layer 6: Side Combo Banner
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
                      'https://images.unsplash.com/photo-1534528741775-53994a69daeb', // Mock user avatar
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
                        "$_lastSenderName gönderdi: $_lastGiftName x$_comboCount",
                        style: TextStyle(
                          color: Colors.yellowAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: w(16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Chat Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [_buildChatList(w, h), _buildBottomInput(w, h)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(double Function(double) w, double Function(double) h) {
    return Container(
      height: h(200),
      padding: EdgeInsets.symmetric(horizontal: w(16)),
      child: ListView.builder(
        reverse: true,
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final msgIndex = _messages.length - 1 - index;
          final msg = _messages[msgIndex];
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

          return Container(
            margin: EdgeInsets.symmetric(vertical: h(4)),
            padding: EdgeInsets.symmetric(horizontal: w(8), vertical: h(4)),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
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
                      color: type == 'gift' ? Colors.pinkAccent : Colors.white,
                      fontSize: w(12),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomInput(
    double Function(double) w,
    double Function(double) h,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w(16), vertical: h(10)),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: h(40),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _chatController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Bir şeyler yaz...',
                  hintStyle: TextStyle(color: Colors.white54, fontSize: w(14)),
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
              padding: EdgeInsets.all(w(8)),
              decoration: const BoxDecoration(
                color: Color(0xFFE65E8B),
                shape: BoxShape.circle,
              ),
              child:
                  _isSending
                      ? SizedBox(
                        width: w(24),
                        height: w(24),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Icon(Icons.send, color: Colors.white, size: w(24)),
            ),
          ),
          SizedBox(width: w(10)),
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder:
                    (context) => GiftBottomSheet(
                      onSendGift: (gift) async {
                        final apiService = ApiService();
                        int roomId =
                            int.tryParse(
                              widget.liveID.replaceAll('room_', ''),
                            ) ??
                            0;

                        if (roomId == 0) return;
                        int hostId = 1;

                        bool success = await apiService.sendGift(
                          roomId: roomId,
                          senderId: int.parse(widget.userId),
                          receiverId: hostId,
                          giftId: gift['id'],
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          if (success) {
                            _sendMessage();
                            _addGiftMessage(
                              "sent ${gift['name']}",
                              gift['name'],
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Hediye gönderilemedi'),
                              ),
                            );
                          }
                        }
                      },
                    ),
              );
            },
            child: Container(
              padding: EdgeInsets.all(w(8)),
              decoration: const BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.card_giftcard,
                color: Colors.white,
                size: w(24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
