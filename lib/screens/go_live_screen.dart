import 'package:flutter/material.dart';
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
  bool _isCreatingRoom = false;
  bool _isLoadingRoom = true;
  Map<String, dynamic>? _existingRoom;

  final ApiService _apiService = ApiService();

  // Form State
  final TextEditingController _titleController = TextEditingController();
  String _selectedTag = 'Chat';
  // int _selectedMode = 1; // Always Party now

  @override
  void initState() {
    super.initState();
    _checkExistingRoom();
  }

  Future<void> _checkExistingRoom() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    if (currentUser == null) return;

    try {
      final result = await _apiService.getMyRoom(currentUser.id);
      if (mounted) {
        setState(() {
          if (result['success'] == true && result['room'] != null) {
            _existingRoom = result['room'];
            _titleController.text = _existingRoom!['title'];
            // _selectedTag = _existingRoom!['tags']; // Optional: restore tag
          }
          _isLoadingRoom = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking room: $e');
      if (mounted) setState(() => _isLoadingRoom = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // Camera logic removed

  // Create Room and Navigate
  Future<void> _createRoomAndGoLive() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.currentUser == null) {
      await userProvider.loginMock();
      if (!mounted) return;
    }
    final currentUser = userProvider.currentUser;
    final int hostId = currentUser?.id ?? 1;

    // If existing room found, just navigate to it
    if (_existingRoom != null) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ChatPartyScreen(
                roomTitle: _existingRoom!['title'],
                roomId: int.parse(_existingRoom!['id'].toString()),
                isHost: true,
                userId: hostId.toString(),
                userName: currentUser?.username ?? 'User',
              ),
        ),
      );
      return;
    }

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

                if (_isLoadingRoom)
                  const CircularProgressIndicator(color: Color(0xFFE65E8B))
                else if (_existingRoom != null)
                  // Existing Room UI
                  Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(w(20)),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(
                              0xFFE65E8B,
                            ).withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.meeting_room,
                              color: Colors.white,
                              size: 40,
                            ),
                            SizedBox(height: h(10)),
                            const Text(
                              "Zaten aktif bir odanız var!",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: h(5)),
                            Text(
                              _existingRoom!['title'],
                              style: const TextStyle(
                                color: Color(0xFFE65E8B),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  // Create Room UI
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
                if (_existingRoom == null)
                  Text(
                    "Starting Audio Room",
                    style: TextStyle(color: Colors.white54, fontSize: w(12)),
                  ),

                SizedBox(height: h(30)),

                // Go Live / Go to Room Button
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
                              : Text(
                                _existingRoom != null
                                    ? 'Odama Git'
                                    : 'Start Party',
                                style: const TextStyle(
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
}
