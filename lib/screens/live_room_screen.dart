import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
import '../services/api_service.dart';
import '../widgets/gift_bottom_sheet.dart';

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
  // App ID and App Sign from ZegoCloud Console
  // Replace these with your actual App ID and App Sign
  final int appID = 341179331;
  final String appSign =
      'db22c1ed05e7f778e4624f656d96a252540090fcb20a3b0bec014bf2c1ddc599';

  final TextEditingController _chatController = TextEditingController();
  final List<String> _messages = ['Canlı yayına hoş geldiniz!'];

  bool _showEntranceEffect = false;
  String _enteringUserName = "";

  // Gift Combo State
  int _comboCount = 0;
  Timer? _comboTimer;
  String _lastGiftName = "";
  String _lastSenderName = "";
  bool _showCombo = false;
  bool _showSideBanner = false;

  @override
  void initState() {
    super.initState();
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
    _comboTimer?.cancel();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double designWidth = 414.0;
    final double designHeight = 896.0;

    double w(double width) => width * (screenSize.width / designWidth);
    double h(double height) => height * (screenSize.height / designHeight);

    // Config for Zego
    final config =
        widget.isHost
            ? ZegoUIKitPrebuiltLiveStreamingConfig.host()
            : ZegoUIKitPrebuiltLiveStreamingConfig.audience();

    // Force camera and mic on for host
    if (widget.isHost) {
      config.turnOnCameraWhenJoining = true;
      config.turnOnMicrophoneWhenJoining = true;
      config.useSpeakerWhenJoining = true;
    }

    // Hide default close button
    config.topMenuBar.buttons = [
      ZegoLiveStreamingMenuBarButtonName.switchCameraButton,
      ZegoLiveStreamingMenuBarButtonName.toggleMicrophoneButton,
    ];

    return Scaffold(
      body: Stack(
        children: [
          // Zego Live Streaming Widget
          ZegoUIKitPrebuiltLiveStreaming(
            appID: appID,
            appSign: appSign,
            userID: widget.userId,
            userName: widget.userName,
            liveID: widget.liveID,
            config: config,
          ),

          // Debug Live ID (Remove later)
          Positioned(
            top: h(60),
            left: w(20),
            child: Text(
              "ID: ${widget.liveID}",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                backgroundColor: Colors.black54,
              ),
            ),
          ),

          // Custom Close Button
          Positioned(
            top: h(40),
            right: w(20),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
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
                              onPressed: () => Navigator.of(context).pop(false),
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
                                        widget.liveID.replaceAll('room_', ''),
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

          // Custom Bottom Bar (Gift Button)
          Positioned(
            bottom: h(20),
            right: w(20),
            child: FloatingActionButton(
              backgroundColor: const Color(0xFFE65E8B),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder:
                      (context) => GiftBottomSheet(
                        roomId:
                            int.tryParse(
                              widget.liveID.replaceAll('room_', ''),
                            ) ??
                            0,
                        receiverId: 1, // Default host ID
                        onGiftSent: (msg) {
                          // Extract gift name from message
                          String giftName = "Gift";
                          try {
                            giftName = msg.split(" sent ")[1].split(" x")[0];
                          } catch (_) {}
                          _addGiftMessage(msg, giftName);
                        },
                      ),
                );
              },
              child: const Icon(Icons.card_giftcard, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
