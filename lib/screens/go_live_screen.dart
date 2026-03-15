import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'live_room_screen.dart';
import 'chat_party_screen.dart';
import '../services/api_service.dart';

import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class GoLiveScreen extends StatefulWidget {
  const GoLiveScreen({super.key});

  @override
  State<GoLiveScreen> createState() => _GoLiveScreenState();
}

class _GoLiveScreenState extends State<GoLiveScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  int _selectedCameraIndex = 0;
  bool _isCreatingRoom = false;

  final ApiService _apiService = ApiService();

  // Form State
  final TextEditingController _titleController = TextEditingController();
  String _selectedTag = 'Chat';
  int _selectedMode = 1; // 0: Live, 1: Chat Party (Default to Chat Party)

  @override
  void initState() {
    super.initState();
    // No camera initialization needed for Chat Party
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // Camera logic removed

  // Create Room and Navigate
  Future<void> _createRoomAndGoLive() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a room title')),
      );
      return;
    }

    setState(() {
      _isCreatingRoom = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.currentUser == null) {
        await userProvider.loginMock();
      }

      final currentUser = userProvider.currentUser;
      final int hostId = currentUser?.id ?? 1;

      // Always create 'party' type since live is removed
      final result = await _apiService.createRoom(
        hostId: hostId,
        title: _titleController.text,
        type: 'party',
        tag: _selectedTag,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final roomId = result['room_id'];

        if (!mounted) return;

        // Chat Party Mode Only
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatPartyScreen(
                  roomTitle: _titleController.text,
                  roomId: roomId,
                  isHost: true,
                  userId: hostId.toString(),
                  userName: currentUser?.username ?? 'User',
                ),
          ),
        );
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
        ).showSnackBar(SnackBar(content: Text('Failed to create room: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingRoom = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double designWidth = 414.0;
    final double designHeight = 896.0;

    double w(double width) => width * (screenSize.width / designWidth);
    double h(double height) => height * (screenSize.height / designHeight);

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Layer 1: Background
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFF1A1A1A),
            child: Center(
              child: Icon(
                Icons.mic,
                color: Colors.white.withValues(alpha: 0.1),
                size: w(120),
              ),
            ),
          ),

          // Layer 2: Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.6),
                ],
                stops: const [0.0, 0.3, 0.6, 1.0],
              ),
            ),
          ),

          // Layer 3: UI Components
          SafeArea(
            child: Column(
              children: [
                // Top Bar (Close Button & User Info)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: w(16),
                    vertical: h(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Info Card
                      Container(
                        padding: EdgeInsets.all(w(8)),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: w(18),
                              backgroundImage: const NetworkImage(
                                'https://i.pravatar.cc/150?img=3',
                              ),
                            ),
                            SizedBox(width: w(10)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Provider.of<UserProvider>(
                                        context,
                                      ).currentUser?.username ??
                                      'User',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: w(14),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "ID: ${Provider.of<UserProvider>(context).currentUser?.id ?? '0'}",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: w(10),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: w(10)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Room Title Input
                Container(
                  margin: EdgeInsets.symmetric(horizontal: w(20)),
                  padding: EdgeInsets.all(w(20)),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _titleController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          hintText: 'Add a title to chat...',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                      ),
                      SizedBox(height: h(20)),
                      // Tags
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children:
                              ['Chat', 'Music', 'Game', 'Party'].map((tag) {
                                final isSelected = _selectedTag == tag;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedTag = tag;
                                    });
                                  },
                                  child: Container(
                                    margin: EdgeInsets.only(right: w(10)),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: w(16),
                                      vertical: h(8),
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? const Color(0xFFE65E8B)
                                              : Colors.white.withValues(
                                                alpha: 0.1,
                                              ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      tag,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: h(30)),

                // Only Chat Party Mode is available now
                Text(
                  "Starting Audio Room",
                  style: TextStyle(color: Colors.white54, fontSize: w(12)),
                ),

                SizedBox(height: h(30)),

                // Go Live Button
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: w(40),
                    vertical: h(20),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: h(56),
                    child: ElevatedButton(
                      onPressed: _isCreatingRoom ? null : _createRoomAndGoLive,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE65E8B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child:
                          _isCreatingRoom
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                'Start Party',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(
    String text,
    double Function(double) w,
    double Function(double) h,
  ) {
    bool isSelected = _selectedTag == text;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTag = text;
        });
      },
      child: Container(
        margin: EdgeInsets.only(right: w(12)),
        padding: EdgeInsets.symmetric(horizontal: w(20), vertical: h(8)),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: w(12),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildControlItem(
    IconData icon,
    String label,
    double Function(double) w, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: w(32)),
          SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.white, fontSize: w(10))),
        ],
      ),
    );
  }

  Widget _buildModeItem(
    int index,
    IconData icon,
    String label,
    double Function(double) w,
  ) {
    bool isSelected = _selectedMode == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = index;
        });
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(w(12)),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? Colors.yellow
                      : Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.black : Colors.white,
              size: w(24),
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.yellow : Colors.white70,
              fontSize: w(12),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
