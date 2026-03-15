import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'go_live_screen.dart';
import 'chat_party_screen.dart';
import 'profile_screen.dart';
import 'leaderboard_screen.dart';
import 'search_screen.dart';
import 'inbox_screen.dart';
import '../services/api_service.dart';
import '../models/room.dart';
import '../providers/user_provider.dart';
import '../widgets/popular_categories_widget.dart';
import 'explore_screen.dart';

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
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchRooms();

    // Auto-refresh every 5 seconds for dynamic updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchRooms(silent: true);
    });
  }

  Future<void> _fetchRooms({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) setState(() => _isLoading = true);
    try {
      // For now, fetch all rooms. Later we can filter by tab index
      final rooms = await _apiService.getRooms();
      if (mounted) {
        setState(() {
          _rooms = rooms;
          if (!silent) _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading rooms: $e');
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
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
      body:
          _bottomNavIndex == 1
              ? const ExploreScreen()
              : _bottomNavIndex == 3
              ? const InboxScreen()
              : _bottomNavIndex == 4
              ? Consumer<UserProvider>(
                builder: (context, provider, child) {
                  if (provider.currentUser != null) {
                    return ProfileScreen(userId: provider.currentUser!.id);
                  }
                  return const Center(child: Text("Please login"));
                },
              )
              : _buildHomeContent(w, h),

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
              onTap: () async {
                // Check if user has a room
                final userProvider = Provider.of<UserProvider>(
                  context,
                  listen: false,
                );
                final currentUser = userProvider.currentUser;

                if (currentUser != null) {
                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (context) => const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFE65E8B),
                          ),
                        ),
                  );

                  try {
                    final result = await _apiService.getMyRoom(currentUser.id);
                    if (context.mounted) Navigator.pop(context); // Hide loading

                    if (result['success'] == true && result['room'] != null) {
                      // Room exists, go directly to ChatPartyScreen
                      final room = result['room'];
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ChatPartyScreen(
                                  roomTitle: room['title'],
                                  roomId: int.parse(room['id'].toString()),
                                  isHost: true,
                                  userId: currentUser.id.toString(),
                                  userName: currentUser.username,
                                ),
                          ),
                        ).then((_) => _fetchRooms());
                      }
                    } else {
                      // No room, go to GoLiveScreen to create one
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GoLiveScreen(),
                          ),
                        ).then((_) => _fetchRooms());
                      }
                    }
                  } catch (e) {
                    if (context.mounted) Navigator.pop(context); // Hide loading
                    debugPrint("Error checking room: $e");
                    // Fallback to GoLiveScreen on error
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GoLiveScreen(),
                        ),
                      );
                    }
                  }
                } else {
                  // Not logged in, go to GoLiveScreen (which handles login mock)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GoLiveScreen(),
                    ),
                  );
                }
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
                  setState(() => _bottomNavIndex = 4);
                } else {
                  // Prompt login
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/nav_profile.svg',
                    width: w(24),
                    height: w(24),
                    colorFilter: ColorFilter.mode(
                      _bottomNavIndex == 4
                          ? const Color(0xFFE65E8B)
                          : Colors.grey,
                      BlendMode.srcIn,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 10,
                      color:
                          _bottomNavIndex == 4
                              ? const Color(0xFFE65E8B)
                              : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent(Function(double) w, Function(double) h) {
    return SafeArea(
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
                      _buildTab('Yeni', 0),
                      _buildTab('Popüler', 1),
                      _buildTab('Parti', 2),
                    ],
                    onTap: (index) {
                      setState(() {}); // Rebuild to update tab styles
                      _fetchRooms(); // Refresh rooms on tab change (mock logic for now)
                    },
                  ),
                ),

                // Rank Icon
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LeaderboardScreen(),
                      ),
                    );
                  },
                  child: Image.asset(
                    'assets/images/icon_trophy.png',
                    width: w(24),
                    height: w(24),
                  ),
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserGrid(w, h, showFreshHeader: true), // Yeni (Fresher)
                _buildUserGrid(w, h), // Popüler
                _buildPartyList(w, h), // Parti (New List View)
              ],
            ),
          ),
        ],
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

  Widget _buildUserGrid(
    Function(double) w,
    Function(double) h, {
    bool showFreshHeader = false,
  }) {
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

          // Fresh Header Widget (Only for 'Yeni' tab)
          if (showFreshHeader) ...[
            const PopularCategoriesWidget(),
            SizedBox(height: h(10)),
          ],

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
          if (!showFreshHeader) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: h(10)),
              child: Row(
                children: [
                  Icon(Icons.public, color: Colors.black54, size: w(20)),
                  SizedBox(width: w(8)),
                  const Text(
                    "Global",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.filter_list, color: Colors.black54, size: w(20)),
                ],
              ),
            ),
          ],

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

  Widget _buildPartyList(Function(double) w, Function(double) h) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_rooms.isEmpty) {
      return const Center(child: Text("No party rooms yet"));
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: w(16), vertical: h(10)),
      itemCount: _rooms.length,
      itemBuilder: (context, index) {
        final room = _rooms[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        ChatPartyScreen(roomTitle: room.title, roomId: room.id),
              ),
            ).then((_) => _fetchRooms());
          },
          child: Container(
            margin: EdgeInsets.only(bottom: h(10)),
            padding: EdgeInsets.all(w(10)),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5), // Light background
              borderRadius: BorderRadius.circular(12),
              // Optional Gradient background for card like design
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Colors.pink.shade50.withValues(alpha: 0.5),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              children: [
                // Avatar (Square/Rounded)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    room.hostAvatar ??
                        'https://i.pravatar.cc/150?img=${room.id % 70}',
                    width: w(60),
                    height: w(60),
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: w(12)),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Room Name
                      Text(
                        room.title.isNotEmpty ? room.title : "Room Name",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: w(14),
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: h(4)),

                      // Tags Row
                      Row(
                        children: [
                          // Flag
                          Image.network(
                            "https://flagcdn.com/w40/ae.png",
                            width: 16,
                            height: 12,
                            fit: BoxFit.cover,
                          ),
                          SizedBox(width: w(6)),

                          // Tag 1 (e.g., Friends/CP)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange, // Dynamic color later
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.mic,
                                  size: 10,
                                  color: Colors.white,
                                ),
                                SizedBox(width: w(2)),
                                const Text(
                                  "Party", // Dynamic tag text
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: h(4)),

                      // Username
                      Text(
                        room.hostName.isNotEmpty ? room.hostName : "User",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: w(12),
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoomCard(Room room, Function(double) w, Function(double) h) {
    // Determine tags based on some logic (mock for now, or based on room data)
    // For now, let's just mock it based on ID to show variety
    String? badgeText;
    Color? badgeColor;
    // IconData? badgeIcon; // Removed icon usage

    if (room.id % 2 == 0) {
      badgeText = "New";
      badgeColor = const Color(0xFFFF0000); // Red
    } else {
      badgeText = "New";
      badgeColor = const Color(0xFF0000FF); // Blue
    }

    return GestureDetector(
      onTap: () {
        // Navigate to ChatPartyScreen for ALL rooms
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    ChatPartyScreen(roomTitle: room.title, roomId: room.id),
          ),
        ).then((_) => _fetchRooms()); // Refresh on return
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

            // Badge (New) - Top Right
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Top Tags (Party/Live) - Top Left (Removed or Kept based on design preference)
            // Design shows Country flag and name at bottom, no top-left tag in the screenshot provided.
            // But let's keep it minimal if needed. The screenshot shows Badge at Top Right.

            // User Info (Bottom)
            Positioned(
              left: 10,
              bottom: 10,
              right: 10,
              child: Row(
                children: [
                  // Flag (Mock)
                  Container(
                    width: 16,
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      image: const DecorationImage(
                        image: NetworkImage(
                          "https://flagcdn.com/w40/ae.png",
                        ), // UAE Flag as in design
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: w(4)),
                  Expanded(
                    child: Text(
                      room.hostName.isNotEmpty ? room.hostName : "User",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: w(12),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Viewer Count
                  Text(
                    '${(room.id * 100) + 50 / 1000}K', // Mock 1.6K format
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: w(12),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
