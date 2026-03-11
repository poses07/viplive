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
  int _selectedMode = 0; // 0: Live, 1: Chat Party

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    // Request permissions
    Map<Permission, PermissionStatus> statuses =
        await [Permission.camera, Permission.microphone].request();

    if (statuses[Permission.camera]!.isGranted &&
        statuses[Permission.microphone]!.isGranted) {
      try {
        _cameras = await availableCameras();
        if (_cameras != null && _cameras!.isNotEmpty) {
          // Find front camera first
          int frontCameraIndex = _cameras!.indexWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
          );
          _selectedCameraIndex = frontCameraIndex != -1 ? frontCameraIndex : 0;

          await _initController(_cameras![_selectedCameraIndex]);
        }
      } catch (e) {
        debugPrint('Error initializing camera: $e');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera and Microphone permissions are required'),
          ),
        );
      }
    }
  }

  Future<void> _initController(CameraDescription cameraDescription) async {
    final CameraController controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: true,
    );

    _controller = controller;

    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    setState(() {
      _isCameraInitialized = false;
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    });

    await _controller?.dispose();
    await _initController(_cameras![_selectedCameraIndex]);
  }

  // Create Room and Navigate
  Future<void> _createRoomAndGoLive() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a room title')),
      );
      return;
    }

    if (_selectedMode == 0 &&
        (_controller == null || !_controller!.value.isInitialized)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Camera not ready')));
      return;
    }

    setState(() {
      _isCreatingRoom = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      // Ensure we have a user (in real app, user should be logged in)
      // For now, if no user, we trigger the mock login
      if (userProvider.currentUser == null) {
        await userProvider.loginMock();
      }

      final currentUser = userProvider.currentUser;
      final int hostId = currentUser?.id ?? 1; // Fallback to 1 if mock fails

      final type = _selectedMode == 0 ? 'live' : 'party';
      final result = await _apiService.createRoom(
        hostId: hostId,
        title: _titleController.text,
        type: type,
        tag: _selectedTag,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final roomId = result['room_id'];

        if (_selectedMode == 0) {
          // Live Mode
          // Release camera before navigating as Zego will take over
          await _controller?.dispose();

          if (!mounted) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => LiveRoomScreen(
                    roomTitle: _titleController.text,
                    roomTag: _selectedTag,
                    isHost: true,
                    userId: hostId.toString(),
                    userName: currentUser?.username ?? 'User',
                    liveID: 'room_$roomId',
                  ),
            ),
          ).then((_) {
            if (mounted) _initializeCamera();
          });
        } else {
          // Chat Party Mode
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ChatPartyScreen(
                    roomTitle: _titleController.text,
                    roomId: roomId,
                    isHost: true,
                  ),
            ),
          );
        }
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
          // Layer 1: Camera Preview
          if (_isCameraInitialized && _controller != null)
            SizedBox.expand(child: CameraPreview(_controller!))
          else
            Container(
              width: double.infinity,
              height: double.infinity,
              color: const Color(0xFF1A1A1A),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_cameras == null)
                      const CircularProgressIndicator(color: Color(0xFF66B4FF))
                    else
                      Icon(
                        Icons.videocam_off,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: w(64),
                      ),
                  ],
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
                            Stack(
                              children: [
                                Container(
                                  width: w(60),
                                  height: w(60),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    image: const DecorationImage(
                                      image: NetworkImage(
                                        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=100&q=80',
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: h(2),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.6,
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(10),
                                        bottomRight: Radius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      'Change Avatar',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: w(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: w(10)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: w(12),
                                    ),
                                    SizedBox(width: w(4)),
                                    Text(
                                      'Hide',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: w(12),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(width: w(20)),
                            // Social Icons
                            Icon(
                              Icons.facebook,
                              color: Colors.white,
                              size: w(20),
                            ),
                            SizedBox(width: w(10)),
                            // Twitter icon (mock with circle)
                            Container(
                              padding: EdgeInsets.all(w(2)),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.flutter_dash,
                                color: Colors.blue,
                                size: w(16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Close Button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: w(24),
                        ),
                      ),
                    ],
                  ),
                ),

                // Room Tags
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: w(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Input Field
                      Container(
                        padding: EdgeInsets.all(w(10)),
                        margin: EdgeInsets.only(bottom: h(20)),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: _titleController,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: w(16),
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Add a title to chat...',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),

                      Text(
                        'Oda Etiketi',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: w(12),
                        ),
                      ),
                      SizedBox(height: h(10)),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildTag('Chat', w, h),
                            _buildTag('Music', w, h),
                            _buildTag('Friends', w, h),
                            _buildTag('CP', w, h),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Middle Controls
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: w(40)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildControlItem(
                        Icons.cameraswitch,
                        'Switch Camera',
                        w,
                        onTap: _switchCamera,
                      ),
                      _buildControlItem(Icons.face, 'Beauty', w),
                      _buildControlItem(Icons.speed, 'Connection Speed', w),
                    ],
                  ),
                ),

                SizedBox(height: h(30)),

                // Go Live Button
                GestureDetector(
                  onTap: _isCreatingRoom ? null : _createRoomAndGoLive,
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: w(30)),
                    width: double.infinity,
                    height: h(54),
                    decoration: BoxDecoration(
                      color:
                          _isCreatingRoom
                              ? Colors.grey
                              : const Color(0xFF66B4FF),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF66B4FF).withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child:
                        _isCreatingRoom
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : Text(
                              'Yayını Başlat',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: w(18),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                              ),
                            ),
                  ),
                ),

                SizedBox(height: h(30)),

                // Bottom Mode Switcher
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: w(60)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildModeItem(0, Icons.videocam, 'Live', w),
                      _buildModeItem(1, Icons.headset_mic, 'Chat Party', w),
                    ],
                  ),
                ),

                SizedBox(height: h(20)),

                Text(
                  'Apply to be an Official Talent',
                  style: TextStyle(color: Colors.white70, fontSize: w(12)),
                ),
                SizedBox(height: h(10)),
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
