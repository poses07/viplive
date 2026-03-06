import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'go_live_screen.dart';
import 'live_room_screen.dart';
import 'chat_party_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import '../services/api_service.dart';
import '../models/room.dart';
import '../providers/user_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _bottomNavIndex = 0;
  final ApiService _apiService = ApiService();
  List<Room> _rooms = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchRooms();
  }

  Future<void> _fetchRooms() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // For now, fetch all rooms. Later we can filter by tab index
      final rooms = await _apiService.getRooms();
      if (mounted) {
        setState(() {
          _rooms = rooms;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading rooms: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double designWidth = 414.0;
    final double designHeight = 896.0;

    double w(double width) => width * (screenSize.width / designWidth);
    double h(double height) => height * (screenSize.height / designHeight);

    return Scaffold(
      backgroundColor: Colors.white, // As per Figma fills: Secondary/White/100%
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar (Search + Tabs + Actions)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w(16), vertical: h(10)),
              child: Row(
                children: [
                  // Search Icon
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SearchScreen(),
                        ),
                      );
                    },
                    child: SvgPicture.asset(
                      'assets/images/icon_search.svg',
                      width: w(24),
                      height: w(24),
                      colorFilter: const ColorFilter.mode(
                        Colors.black,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  SizedBox(width: w(20)),

                  // Tabs (Popular, Freshers, Party)
                  Expanded(
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicatorColor: Colors.transparent, // No underline
                      dividerColor: Colors.transparent,
                      labelPadding: EdgeInsets.symmetric(horizontal: w(12)),
                      tabs: [
                        _buildTab('Popüler', 0),
                        _buildTab('Yeni', 1),
                        _buildTab('Parti', 2),
                      ],
                      onTap: (index) {
                        setState(() {}); // Rebuild to update tab styles
                        _fetchRooms(); // Refresh rooms on tab change (mock logic for now)
                      },
                    ),
                  ),

                  // Profile Icon (Replaces notification/chat placeholder)
                  GestureDetector(
                    onTap: () {
                      // Navigate to Profile or Inbox if needed, or keep as visual balance
                      // For now, let's keep it as a profile shortcut or remove it if unwanted
                      // Based on the image, there's a user icon on the right.
                      final currentUser =
                          Provider.of<UserProvider>(
                            context,
                            listen: false,
                          ).currentUser;
                      if (currentUser != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    ProfileScreen(userId: currentUser.id),
                          ),
                        );
                      }
                    },
                    child: const Icon(Icons.person, color: Colors.black),
                  ),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildUserGrid(w, h), // Popular
                  _buildUserGrid(w, h), // Freshers (Reusing grid for now)
                  _buildUserGrid(w, h), // Party (Reusing grid for now)
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: Container(
        height: h(80),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, 'assets/images/nav_home.svg', 'Home', w),
            _buildNavItem(1, 'assets/images/nav_explore.svg', 'Explore', w),

            // Center "Live" Button
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GoLiveScreen()),
                );
              },
              child: Container(
                width: w(60),
                height: w(60),
                margin: EdgeInsets.only(bottom: h(20)), // Floating effect
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF4B9AEA),
                      Color(0xFF305FF2),
                    ], // From Figma fill_HNV6QI
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF305FF2).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(w(15)),
                child: SvgPicture.asset(
                  'assets/images/nav_live_icon.svg',
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),

            _buildNavItem(3, 'assets/images/nav_chat.svg', 'Chat', w),
            GestureDetector(
              onTap: () {
                final user =
                    Provider.of<UserProvider>(
                      context,
                      listen: false,
                    ).currentUser;
                if (user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(userId: user.id),
                    ),
                  );
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/nav_profile.svg',
                    width: w(24),
                    height: w(24),
                    colorFilter: ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Profile',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String text, int index) {
    bool isSelected = _tabController.index == index;
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: isSelected ? 18 : 16,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.black : Colors.grey,
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    String iconPath,
    String label,
    Function(double) w,
  ) {
    bool isSelected = _bottomNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _bottomNavIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            iconPath,
            width: w(24),
            height: w(24),
            colorFilter: ColorFilter.mode(
              isSelected ? const Color(0xFFE65E8B) : Colors.grey,
              BlendMode.srcIn,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? const Color(0xFFE65E8B) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserGrid(Function(double) w, Function(double) h) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.live_tv_outlined, size: w(64), color: Colors.grey),
            SizedBox(height: h(16)),
            Text(
              "No live rooms yet",
              style: TextStyle(color: Colors.grey, fontSize: w(16)),
            ),
            TextButton(onPressed: _fetchRooms, child: const Text("Refresh")),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: w(16)),
      child: Column(
        children: [
          SizedBox(height: h(10)),
          // Banner
          Container(
            width: double.infinity,
            height: h(105),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: const DecorationImage(
                image: AssetImage('assets/images/home_banner.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: h(20)),

          // Grid of Rooms
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: w(15),
              mainAxisSpacing: h(15),
              childAspectRatio: 0.8, // Adjust for card height
            ),
            itemCount: _rooms.length,
            itemBuilder: (context, index) {
              return _buildRoomCard(_rooms[index], w, h);
            },
          ),
          SizedBox(height: h(100)), // Bottom padding for nav bar
        ],
      ),
    );
  }

  Widget _buildRoomCard(Room room, Function(double) w, Function(double) h) {
    return GestureDetector(
      onTap: () {
        final currentUser =
            Provider.of<UserProvider>(context, listen: false).currentUser;

        // Navigate to Room based on type
        if (room.roomType == 'live') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => LiveRoomScreen(
                    roomTitle: room.title,
                    roomTag: room.roomType,
                    isHost: false, // Viewer
                    userId: currentUser?.id.toString() ?? 'guest',
                    userName: currentUser?.username ?? 'Guest',
                    liveID: 'room_${room.id}',
                  ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      ChatPartyScreen(roomTitle: room.title, roomId: room.id),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          image: DecorationImage(
            image: NetworkImage(
              room.hostAvatar ??
                  'https://i.pravatar.cc/150?img=${room.id % 70}',
            ),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),

            // Top Tags (Yalla Style)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.pink.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      room.roomType == 'party' ? Icons.mic : Icons.videocam,
                      color: Colors.white,
                      size: 10,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      room.roomType.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // User Info
            Positioned(
              left: 10,
              bottom: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.title.isNotEmpty ? room.title : room.hostName,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: w(14),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: h(4)),
                  Row(
                    children: [
                      // Flag (Mock)
                      Container(
                        width: 12,
                        height: 8,
                        color: Colors.green, // Mock flag
                      ),
                      SizedBox(width: w(4)),
                      Icon(Icons.person, color: Colors.white70, size: w(12)),
                      SizedBox(width: w(2)),
                      Text(
                        '${(room.id * 100) + 50}', // Mock viewer count
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: w(10),
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
