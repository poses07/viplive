import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lottie/lottie.dart';

import '../widgets/gift_bottom_sheet.dart';
import '../providers/user_provider.dart';
import '../services/zego_service.dart';
import '../models/seat.dart';
import '../services/api_service.dart';
import 'profile_screen.dart';

class ChatPartyScreen extends StatefulWidget {
  final String roomTitle;
  final int? roomId;
  final bool isHost;
  final String userId;
  final String userName;

  const ChatPartyScreen({
    super.key,
    required this.roomTitle,
    this.roomId,
    this.isHost = false,
    this.userId = '0',
    this.userName = 'User',
  });

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
  bool _isHost = false;
  int _hostId = 0; // Added host ID
  String _hostName = "";
  String _hostAvatar = "";

  List<Map<String, dynamic>> _audience = []; // Real audience data

  // Gift Combo State
  int _comboCount = 0;
  Timer? _comboTimer;
  String _lastGiftName = "";
  String _lastSenderName = "";
  bool _showCombo = false;
  bool _showSideBanner = false;

  // Lottie Animation State
  String? _currentGiftAnimationUrl;
  bool _showGiftAnimation = false;
  Timer? _giftAnimationTimer;

  // Gift Name -> Lottie URL Mapping
  final Map<String, String> _giftAnimationMap = {
    'Rose': 'https://assets10.lottiefiles.com/packages/lf20_jbrw3hcz.json',
    'Car': 'https://assets9.lottiefiles.com/packages/lf20_g3qplx2z.json',
    'Rocket': 'https://assets1.lottiefiles.com/packages/lf20_myejiggj.json',
    'Heart': 'https://assets8.lottiefiles.com/packages/lf20_b6cz19m8.json',
  };
  // Fallback animation
  final String _defaultGiftAnimation =
      'https://assets10.lottiefiles.com/packages/lf20_u4yrau.json';

  final List<dynamic> _messages =
      []; // Changed to dynamic to support both Map and String
  int _lastMessageId = 0;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  int _roomLevel = 1;
  int _roomPoints = 0;

  bool _isFollowing = false; // Local state for follow button

  @override
  void initState() {
    super.initState();
    // Initialize local host state from widget param first
    _isHost = widget.isHost;

    _requestPermissions(); // Request permissions early
    if (widget.roomId != null) {
      _fetchSeats();
      _fetchRoomDetails();
      _fetchMessages(); // Fetch history once
      _joinAudience();

      // Listen to ZIM Messages
      ZegoService().onReceiveRoomMessage = (senderID, message) {
        if (!mounted) return;

        if (message == "ROOM_ENDED") {
          _onRoomEnded();
          return;
        }

        setState(() {
          // Use 'content' instead of 'message' to match the key used in build method
          _messages.add({'username': senderID, 'content': message});

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
        });
      };

      // Listen to ZIM Commands (Signals)
      ZegoService().onReceiveCommand = (senderID, command) {
        if (!mounted) return;

        // Protocol: GIFT:SenderName:GiftName:Quantity:RoomPoints:RoomLevel
        if (command.startsWith("GIFT:")) {
          final parts = command.split(':');
          if (parts.length >= 3) {
            String senderName = parts[1];
            String giftName = parts[2];
            int quantity = parts.length > 3 ? int.tryParse(parts[3]) ?? 1 : 1;

            // Extract Room Stats if available
            if (parts.length >= 6) {
              int? newPoints = int.tryParse(parts[4]);
              int? newLevel = int.tryParse(parts[5]);
              if (newPoints != null && newLevel != null) {
                setState(() {
                  _roomPoints = newPoints;
                  _roomLevel = newLevel;
                });
              }
            }

            String content =
                "sent $giftName${quantity > 1 ? " x$quantity" : ""}";

            // Trigger Animation
            _triggerGiftCombo(giftName, senderName, quantity);
            _playGiftAnimation(giftName);

            // Add to chat list as a system/gift message
            setState(() {
              _messages.add({
                'username': senderName,
                'content': content,
                'type': 'gift',
              });

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
            });
          }
        }
      };

      // Start polling for seats only
      _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        _fetchSeats(background: true);
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

  Future<void> _toggleFollow() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    if (currentUser == null || widget.roomId == null || _hostId == 0) return;

    try {
      final result = await _apiService.followUser(
        followerId: currentUser.id,
        followingId: _hostId,
      );

      if (result['success'] == true) {
        setState(() {
          _isFollowing = result['is_following'];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: _isFollowing ? Colors.green : Colors.grey,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error toggling follow: $e');
    }
  }

  Future<void> _fetchRoomDetails() async {
    if (widget.roomId == null) return;
    try {
      final details = await _apiService.getRoomDetails(widget.roomId!);
      if (mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final currentUser = userProvider.currentUser;

        int fetchedHostId = int.tryParse(details['host_id'].toString()) ?? 0;

        setState(() {
          _roomLevel = int.tryParse(details['level'].toString()) ?? 1;
          _roomPoints = int.tryParse(details['points'].toString()) ?? 0;
          _hostId = fetchedHostId;
          _hostName = details['host_name'] ?? widget.roomTitle;
          _hostAvatar = details['host_avatar'] ?? '';

          if (currentUser != null &&
              fetchedHostId.toString() == currentUser.id.toString()) {
            _isHost = true;
          } else {
            _isHost = widget.isHost; // Fallback to widget param
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading room details: $e');
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
        isHost: false, // Force false to avoid auto-video publishing
      );

      // Auto-publish if already seated (e.g. Host created room)
      // We need to fetch seats to know if we are seated.
      await _fetchSeats(background: true);

      // Check if seated after fetch
      bool isSeated = _seats.any((s) => s.user?.id == currentUser.id);
      if (isSeated) {
        // If seated, unmute mic and start publishing audio only
        await zegoService.startPublishingStream(
          currentUser.id.toString(),
          video: false,
        );
      }
    }
  }

  bool _isRoomEnded = false;

  void _onRoomEnded() {
    if (_isRoomEnded || !mounted) return;
    setState(() => _isRoomEnded = true);

    _pollingTimer?.cancel();
    _chatPollingTimer?.cancel();
    _audiencePollingTimer?.cancel();

    // Stop Zego
    ZegoService().logoutRoom();

    // Show Ended Overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => PopScope(
            canPop: false,
            child: Scaffold(
              backgroundColor: Colors.black.withValues(alpha: 0.9),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.mic_off, size: 80, color: Colors.white54),
                    const SizedBox(height: 20),
                    const Text(
                      "Parti Sona Erdi",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Host odayı kapattı.",
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 30),
                    const CircularProgressIndicator(color: Color(0xFFE65E8B)),
                  ],
                ),
              ),
            ),
          ),
    );

    // Navigate back after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop(); // Close Dialog
        Navigator.of(context).pop(); // Close Screen
      }
    });
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
      Permission.bluetoothConnect,
    ].request();
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
      }
    } catch (e) {
      if (e is RoomEndedException) {
        _onRoomEnded();
      } else {
        debugPrint('Error loading seats: $e');
        if (mounted && !background) setState(() => _isLoadingSeats = false);
      }
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

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _chatPollingTimer?.cancel();
    _audiencePollingTimer?.cancel();
    _comboTimer?.cancel();
    _giftAnimationTimer?.cancel();
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

  Future<void> _fetchMessages() async {
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

  void _triggerGiftCombo(String giftName, String senderName, int quantity) {
    setState(() {
      // Combo Logic
      if (_lastGiftName == giftName &&
          _lastSenderName == senderName &&
          (_showCombo || _showSideBanner)) {
        _comboCount += quantity;
        _comboTimer?.cancel();
      } else {
        _comboCount = quantity;
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

  void _playGiftAnimation(String giftName) {
    // Determine animation URL
    String animationUrl = _giftAnimationMap[giftName] ?? _defaultGiftAnimation;

    // Reset timer if already playing
    _giftAnimationTimer?.cancel();

    setState(() {
      _currentGiftAnimationUrl = animationUrl;
      _showGiftAnimation = true;
    });

    // Hide after 4 seconds (adjust based on animation length)
    _giftAnimationTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showGiftAnimation = false;
          _currentGiftAnimationUrl = null;
        });
      }
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
      // Send via ZIM
      await ZegoService().sendRoomMessage(widget.roomId.toString(), content);

      // Add to local list immediately
      setState(() {
        _messages.add({'username': currentUser.username, 'content': content});
        _messageController.clear();
      });

      // Also save to DB for history
      if (customContent == null) {
        ApiService().sendMessage(
          widget.roomId!,
          currentUser.id,
          content,
          type: customType,
        );
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
    } finally {
      if (customContent == null && mounted) setState(() => _isSending = false);
    }
  }

  Widget _buildBottomSection(
    double Function(double) w,
    double Function(double) h,
  ) {
    return Expanded(
      child: Column(
        children: [
          // Chat Area
          Expanded(
            child: Container(
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
                              color: Colors.black.withValues(alpha: 0.3),
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
                  const SizedBox.shrink(),
                ],
              ),
            ),
          ),

          // Bottom Actions Bar
          _buildBottomBar(w, h),
        ],
      ),
    );
  }

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

          // Layer 2.5: Full Screen Lottie Animation
          if (_showGiftAnimation && _currentGiftAnimationUrl != null)
            Positioned.fill(
              child: IgnorePointer(
                child: Lottie.network(
                  _currentGiftAnimationUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),

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

                // Seats Grid (Dynamic)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: w(10)),
                    child:
                        _isLoadingSeats
                            ? const Center(child: CircularProgressIndicator())
                            : GridView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 5,
                                    crossAxisSpacing: w(10),
                                    mainAxisSpacing: h(20),
                                    childAspectRatio: 0.7,
                                  ),
                              itemCount: _seats.length,
                              itemBuilder: (context, index) {
                                if (index >= _seats.length) {
                                  return const SizedBox.shrink();
                                }
                                return _buildSeat(index, w);
                              },
                            ),
                  ),
                ),

                // Bottom Section
                _buildBottomSection(w, h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(double Function(double) w, double Function(double) h) {
    String hostName = _hostName.isNotEmpty ? _hostName : widget.roomTitle;
    String roomIdDisplay =
        widget.roomId != null ? widget.roomId.toString() : "Unknown";

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w(16), vertical: h(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: Host Card + Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Host Card
              GestureDetector(
                onTap: () {
                  if (_hostId != 0) {
                    _showAudienceUserProfile({
                      'user_id': _hostId,
                      'username': hostName,
                      'avatar_url': _hostAvatar,
                    });
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(w(4)),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: w(18),
                        backgroundImage: NetworkImage(
                          _hostAvatar.isNotEmpty
                              ? _hostAvatar
                              : 'https://i.pravatar.cc/150?img=1',
                        ),
                      ),
                      SizedBox(width: w(8)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hostName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: w(12),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'ID: $roomIdDisplay',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: w(10),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: w(12)),
                      // Follow Button (Hide if Host)
                      if (!_isHost)
                        GestureDetector(
                          onTap: _toggleFollow,
                          child: Container(
                            padding: EdgeInsets.all(w(4)),
                            decoration: BoxDecoration(
                              color:
                                  _isFollowing
                                      ? Colors.transparent
                                      : const Color(0xFFFFD700),
                              shape: BoxShape.circle,
                              border:
                                  _isFollowing
                                      ? Border.all(color: Colors.white70)
                                      : null,
                            ),
                            child: Icon(
                              _isFollowing ? Icons.check : Icons.add,
                              color:
                                  _isFollowing ? Colors.white70 : Colors.black,
                              size: w(14),
                            ),
                          ),
                        ),
                      SizedBox(width: w(4)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: h(8)),
              // Stats Row (Trophy, Diamonds, Level)
              Row(
                children: [
                  // Diamonds Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: w(8),
                      vertical: w(2),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.diamond, color: Colors.cyan, size: w(12)),
                        SizedBox(width: w(4)),
                        Text(
                          "$_roomPoints", // Dynamic Points
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: w(10),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: w(6)),
                  // Level Badge (Blue Gradient)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: w(8),
                      vertical: w(2),
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: w(12)),
                        SizedBox(width: w(4)),
                        Text(
                          "Lv.$_roomLevel", // Dynamic Level
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: w(10),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // Right Side: Controls & Audience
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Top Controls (Share, Settings, Close)
              Row(
                children: [
                  // Share Button
                  Container(
                    width: w(32),
                    height: w(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.share, color: Colors.white, size: w(18)),
                  ),
                  SizedBox(width: w(10)),
                  // Settings Button (Host Only)
                  if (_isHost) ...[
                    GestureDetector(
                      onTap: () => _showRoomSettings(),
                      child: Container(
                        width: w(32),
                        height: w(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: w(18),
                        ),
                      ),
                    ),
                    SizedBox(width: w(10)),
                  ],
                  // Close Button
                  GestureDetector(
                    onTap: () async {
                      if (!_isHost) {
                        Navigator.pop(context);
                        return;
                      }

                      // Show confirmation dialog for Host
                      bool shouldLeave =
                          await showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                backgroundColor: const Color(0xFF1E1E1E),
                                title: const Text(
                                  "Partiden Ayrıl",
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: const Text(
                                  "Oda açık kalmaya devam edecek. Çıkmak istediğinize emin misiniz?",
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
                                    onPressed: () {
                                      Navigator.of(context).pop(true);
                                    },
                                    child: const Text(
                                      "Ayrıl",
                                      style: TextStyle(
                                        color: Color(0xFFE65E8B),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ) ??
                          false;

                      if (shouldLeave && mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      width: w(32),
                      height: w(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: w(18),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: h(12)),
              // Audience List (Horizontal Avatars)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_audience.isNotEmpty)
                    SizedBox(
                      height: w(32),
                      width: w(100),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        itemCount: _audience.length > 3 ? 3 : _audience.length,
                        itemBuilder: (context, index) {
                          final user = _audience[index];
                          return GestureDetector(
                            onTap: () => _showAudienceUserProfile(user),
                            child: Padding(
                              padding: EdgeInsets.only(left: w(4)),
                              child: CircleAvatar(
                                radius: w(16),
                                backgroundImage: NetworkImage(
                                  (user['avatar_url']?.toString().isNotEmpty ??
                                          false)
                                      ? user['avatar_url'].toString()
                                      : 'https://i.pravatar.cc/150',
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  SizedBox(width: w(8)),
                  // Audience Count Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: w(8),
                      vertical: w(6),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.person, color: Colors.white, size: w(12)),
                        Text(
                          "${_audience.length}",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: w(10),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRoomSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
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
                "Oda Ayarları",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Koltuk Sayısı",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:
                    [5, 10, 20].map((count) {
                      bool isSelected = _seats.length == count;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            Navigator.pop(context);
                            bool success = await _apiService.updateRoomLayout(
                              widget.roomId!,
                              count,
                            );

                            if (!context.mounted) return;

                            if (success) {
                              _fetchSeats(); // Refresh UI
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Oda düzeni güncellendi"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Güncelleme başarısız (Koltuklar dolu olabilir)",
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? const Color(0xFFE65E8B)
                                      : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? Colors.transparent
                                        : Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "$count Koltuk",
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  void _showAudienceUserProfile(Map<String, dynamic> user) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    if (currentUser == null) return;

    int userId = int.tryParse(user['user_id'].toString()) ?? 0;
    String username = user['username'] ?? 'User';
    String avatarUrl = user['avatar_url'] ?? '';

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
                  backgroundImage: NetworkImage(
                    avatarUrl.isNotEmpty
                        ? avatarUrl
                        : 'https://i.pravatar.cc/150',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder:
                            (context) => GiftBottomSheet(
                              receiver: {'name': username, 'avatar': avatarUrl},
                              onSendGift: (gift) async {
                                final apiService = ApiService();
                                int roomId = widget.roomId ?? 0;
                                if (roomId == 0) return;

                                int quantity = gift['quantity'] ?? 1;

                                final result = await apiService.sendGift(
                                  roomId: roomId,
                                  senderId: currentUser.id,
                                  receiverId: userId,
                                  giftId: gift['id'],
                                  quantity: quantity,
                                );

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  if (result['success'] == true) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '$username kullanıcısına ${gift['name']}${quantity > 1 ? ' x$quantity' : ''} gönderildi!',
                                        ),
                                      ),
                                    );

                                    if (result['room_points'] != null) {
                                      setState(() {
                                        _roomPoints =
                                            int.tryParse(
                                              result['room_points'].toString(),
                                            ) ??
                                            _roomPoints;
                                        _roomLevel =
                                            int.tryParse(
                                              result['room_level'].toString(),
                                            ) ??
                                            _roomLevel;
                                      });
                                    }

                                    try {
                                      String command =
                                          "GIFT:${currentUser.username}:${gift['name']}:$quantity:$_roomPoints:$_roomLevel";
                                      await ZegoService().sendRoomCommand(
                                        roomId.toString(),
                                        command,
                                      );

                                      String giftMsg =
                                          "sent ${gift['name']}${quantity > 1 ? " x$quantity" : ""}";
                                      setState(() {
                                        _messages.add({
                                          'username': currentUser.username,
                                          'content': giftMsg,
                                          'type': 'gift',
                                        });
                                        _triggerGiftCombo(
                                          gift['name'],
                                          currentUser.username,
                                          quantity,
                                        );
                                        _playGiftAnimation(gift['name']);
                                      });
                                    } catch (e) {
                                      debugPrint(
                                        'Error sending gift message: $e',
                                      );
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Hediye gönderilemedi: ${result['error'] ?? 'Bilinmeyen hata'}',
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
                      backgroundColor: const Color(0xFFFFD700),
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
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(userId: userId),
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
  }

  Future<void> _handleSeatTap(int index, Seat? seatData) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    if (currentUser == null || widget.roomId == null) return;

    bool isOccupied = seatData?.user != null;
    bool isLocked = seatData?.isLocked ?? false;
    bool isMe = seatData?.user?.id == currentUser.id;

    if (isMe) {
      _showActionDialog('Koltuktan Kalk?', () => _updateSeat(index, 'leave'));
      return;
    }

    if (isOccupied) {
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
                    backgroundImage: NetworkImage(
                      (seatData!.user!.avatarUrl.toString().isNotEmpty)
                          ? seatData.user!.avatarUrl.toString()
                          : 'https://i.pravatar.cc/150',
                    ),
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
                  // If I am Host, I can kick/lock
                  if (_isHost) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _updateSeat(index, 'leave');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Koltuktan Kaldır",
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
                                receiver: {
                                  'name': seatData.user!.username,
                                  'avatar': seatData.user!.avatarUrl,
                                },
                                onSendGift: (gift) async {
                                  final apiService = ApiService();
                                  int roomId = widget.roomId ?? 0;
                                  if (roomId == 0) return;

                                  int quantity = gift['quantity'] ?? 1;

                                  final result = await apiService.sendGift(
                                    roomId: roomId,
                                    senderId: currentUser.id,
                                    receiverId: seatData.user!.id,
                                    giftId: gift['id'],
                                    quantity: quantity,
                                  );

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    if (result['success'] == true) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${seatData.user!.username} kullanıcısına ${gift['name']}${quantity > 1 ? ' x$quantity' : ''} gönderildi!',
                                          ),
                                        ),
                                      );

                                      // Update local room stats
                                      if (result['room_points'] != null) {
                                        setState(() {
                                          _roomPoints =
                                              int.tryParse(
                                                result['room_points']
                                                    .toString(),
                                              ) ??
                                              _roomPoints;
                                          _roomLevel =
                                              int.tryParse(
                                                result['room_level'].toString(),
                                              ) ??
                                              _roomLevel;
                                        });
                                      }

                                      // Send gift message to chat via ZIM with Room Stats
                                      try {
                                        String command =
                                            "GIFT:${currentUser.username}:${gift['name']}:$quantity:$_roomPoints:$_roomLevel";
                                        await ZegoService().sendRoomCommand(
                                          roomId.toString(),
                                          command,
                                        );

                                        // Local update
                                        String giftMsg =
                                            "sent ${gift['name']}${quantity > 1 ? " x$quantity" : ""}";
                                        setState(() {
                                          _messages.add({
                                            'username': currentUser.username,
                                            'content': giftMsg,
                                            'type': 'gift',
                                          });
                                          _triggerGiftCombo(
                                            gift['name'],
                                            currentUser.username,
                                            quantity,
                                          );
                                          _playGiftAnimation(gift['name']);
                                        });
                                      } catch (e) {
                                        debugPrint(
                                          'Error sending gift message: $e',
                                        );
                                      }
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Hediye gönderilemedi: ${result['error'] ?? 'Bilinmeyen hata'}',
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
                        backgroundColor: const Color(0xFFFFD700),
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
                        Navigator.pop(context);
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
      return;
    }

    // Empty Seat Logic
    if (_isHost) {
      // Host: Lock/Unlock or Sit
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
                  if (!isLocked)
                    _buildSheetAction(
                      icon: Icons.event_seat,
                      label: 'Koltuğa Otur',
                      color: const Color(0xFFE65E8B),
                      onTap: () {
                        Navigator.pop(context);
                        _updateSeat(index, 'sit');
                      },
                    ),
                  const SizedBox(height: 12),
                  _buildSheetAction(
                    icon: isLocked ? Icons.lock_open : Icons.lock_outline,
                    label: isLocked ? 'Kilidi Aç' : 'Koltuğu Kilitle',
                    color: Colors.amber,
                    onTap: () {
                      Navigator.pop(context);
                      _updateSeat(index, isLocked ? 'unlock' : 'lock');
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
      );
    } else {
      // Guest
      if (isLocked) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bu koltuk kilitli')));
      } else {
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
        // Zego Stream Management based on action
        final zegoService = ZegoService();
        if (action == 'sit') {
          // Start publishing audio only
          await zegoService.startPublishingStream(
            currentUser.id.toString(),
            video: false,
          );
          if (!zegoService.isMicOn) {
            await zegoService.toggleMic();
          }
        } else if (action == 'leave') {
          await zegoService.stopPublishingStream();
        }

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
    return ListenableBuilder(
      listenable: ZegoService(),
      builder: (context, _) {
        final currentUser = Provider.of<UserProvider>(context).currentUser;

        Seat? seatData;
        if (_seats.isNotEmpty) {
          try {
            seatData = _seats.firstWhere((s) => s.seatIndex == index);
          } catch (_) {}
        }

        bool isOccupied = seatData?.user != null;
        String label =
            isOccupied ? (seatData!.user!.username) : 'No.${index + 1}';
        String? avatarUrl = isOccupied ? seatData!.user!.avatarUrl : null;
        bool isLocked = seatData?.isLocked ?? false;
        bool isMe = seatData?.user?.id == currentUser?.id;
        bool isMicOn = isMe ? ZegoService().isMicOn : false;

        double soundLevel = 0.0;
        if (isOccupied) {
          String userIdStr = seatData!.user!.id.toString();
          soundLevel = ZegoService().soundLevels[userIdStr] ?? 0.0;
        }

        bool isTalking = soundLevel > 10.0;
        Color waveColor = const Color(0xFFE65E8B);
        if (isOccupied) {
          if (seatData!.user!.gender == 'male') {
            waveColor = const Color(0xFF00BFFF);
          } else if (seatData.user!.gender == 'female') {
            waveColor = const Color(0xFFFF69B4);
          }
        }

        return GestureDetector(
          onTap: () => _handleSeatTap(index, seatData),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  if (isTalking)
                    TweenAnimationBuilder<double>(
                      key: ValueKey(isTalking),
                      tween: Tween(begin: 1.0, end: 1.4),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOut,
                      builder: (context, scale, child) {
                        return Container(
                          width: w(50) * scale,
                          height: w(50) * scale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: waveColor.withValues(alpha: 1.4 - scale),
                              width: 2,
                            ),
                          ),
                        );
                      },
                    ),

                  if (isTalking)
                    TweenAnimationBuilder<double>(
                      key: ValueKey('wave2_$index'),
                      tween: Tween(begin: 1.0, end: 1.6),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOut,
                      builder: (context, scale, child) {
                        return Container(
                          width: w(50) * scale,
                          height: w(50) * scale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: waveColor.withValues(
                                alpha: (1.6 - scale) * 0.5,
                              ),
                              width: 1,
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
                        color:
                            isTalking
                                ? waveColor
                                : Colors.white.withValues(alpha: 0.2),
                        width: isTalking ? 2 : 1,
                      ),
                      boxShadow:
                          isTalking
                              ? [
                                BoxShadow(
                                  color: waveColor.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ]
                              : [],
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
                                Icons.event_seat,
                                color: Colors.white.withValues(alpha: 0.5),
                                size: w(24),
                              ),
                            ),
                  ),
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
      },
    );
  }

  Widget _buildBottomBar(double Function(double) w, double Function(double) h) {
    final currentUser = Provider.of<UserProvider>(context).currentUser;
    bool isSeated = false;
    if (currentUser != null) {
      isSeated = _seats.any((seat) => seat.user?.id == currentUser.id);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w(16), vertical: h(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Input Field (Left)
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: w(12), vertical: h(8)),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Bir şeyler söyle...',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(width: w(12)),

          // Actions (Right)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Send Button (Pink)
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: w(40),
                  height: w(40),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE65E8B),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: w(20),
                  ),
                ),
              ),

              SizedBox(width: w(12)),

              // Gift Button (Blue Gradient)
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder:
                        (context) => GiftBottomSheet(
                          receiver: {'name': "Host", 'avatar': ""},
                          onSendGift: (gift) async {
                            // Use _hostId if available, otherwise fallback to 1 (which might be wrong but was default)
                            int receiverId = _hostId > 0 ? _hostId : 1;
                            int roomId = widget.roomId ?? 0;
                            if (roomId == 0) return;

                            final apiService = ApiService();
                            if (currentUser == null) return;

                            bool success = false;
                            Map<String, dynamic> result = {};

                            try {
                              result = await apiService.sendGift(
                                roomId: roomId,
                                senderId: currentUser.id,
                                receiverId: receiverId,
                                giftId: gift['id'],
                              );
                              success = result['success'] == true;
                            } catch (e) {
                              success = false;
                            }

                            if (context.mounted) {
                              Navigator.pop(context);
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Oda sahibine ${gift['name']} gönderildi!',
                                    ),
                                  ),
                                );

                                if (result['room_points'] != null) {
                                  setState(() {
                                    _roomPoints =
                                        int.tryParse(
                                          result['room_points'].toString(),
                                        ) ??
                                        _roomPoints;
                                    _roomLevel =
                                        int.tryParse(
                                          result['room_level'].toString(),
                                        ) ??
                                        _roomLevel;
                                  });
                                }

                                try {
                                  String command =
                                      "GIFT:${currentUser.username}:${gift['name']}:1:$_roomPoints:$_roomLevel";
                                  await ZegoService().sendRoomCommand(
                                    roomId.toString(),
                                    command,
                                  );
                                } catch (e) {
                                  debugPrint("ZIM Error: $e");
                                }

                                _playGiftAnimation(gift['name']);
                                _triggerGiftCombo(
                                  gift['name'],
                                  currentUser.username,
                                  1,
                                );

                                _sendMessage(
                                  customContent: "sent ${gift['name']} to Host",
                                  customType: 'gift',
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Hediye gönderilemedi: ${result['error'] ?? 'Bilinmeyen hata'}',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                  );
                },
                child: Container(
                  width: w(40),
                  height: w(40),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.card_giftcard,
                    color: Colors.white,
                    size: w(20),
                  ),
                ),
              ),

              // Mic Toggle (Only if seated)
              if (isSeated) ...[
                SizedBox(width: w(12)),
                ListenableBuilder(
                  listenable: ZegoService(),
                  builder: (context, _) {
                    bool isMicOn = ZegoService().isMicOn;
                    return GestureDetector(
                      onTap: () async {
                        await ZegoService().toggleMic();
                      },
                      child: Container(
                        width: w(40),
                        height: w(40),
                        decoration: BoxDecoration(
                          color:
                              isMicOn
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.red.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isMicOn ? Icons.mic : Icons.mic_off,
                          color: Colors.white,
                          size: w(20),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
