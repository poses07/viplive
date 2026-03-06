import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import 'dm_screen.dart';
import 'settings_screen.dart';
import 'wallet_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final currentUser =
        Provider.of<UserProvider>(context, listen: false).currentUser;
    try {
      final profileData = await _apiService.getUserProfile(
        widget.userId,
        currentUserId: currentUser?.id,
      );

      if (mounted && profileData.isNotEmpty) {
        setState(() {
          _userProfile = profileData;
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false); // Handle not found
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final currentUser =
        Provider.of<UserProvider>(context, listen: false).currentUser;
    if (currentUser == null) return;

    try {
      final result = await _apiService.followUser(
        followerId: currentUser.id,
        followingId: widget.userId,
      );

      if (mounted && result['success'] == true) {
        setState(() {
          _userProfile!['is_following'] = result['is_following'];
          // Optimistically update counts
          int followers =
              int.tryParse(_userProfile!['followers_count'].toString()) ?? 0;
          if (result['is_following']) {
            followers++;
          } else {
            followers--;
          }
          _userProfile!['followers_count'] = followers;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_userProfile == null) {
      return const Scaffold(body: Center(child: Text("User not found")));
    }

    final currentUser = Provider.of<UserProvider>(context).currentUser;
    final bool isMe = currentUser?.id == widget.userId;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header (Cover + Avatar + Actions)
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Cover Image
                Container(
                  height: h(200),
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1504805572947-34fad45aed93?auto=format&fit=crop&w=800&q=80',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Back Button
                Positioned(
                  top: h(40),
                  left: w(16),
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.3),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                // Settings Button (Only if Me)
                if (isMe)
                  Positioned(
                    top: h(40),
                    right: w(110),
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.3),
                      child: IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            ),
                      ),
                    ),
                  ),
                // Wallet Button (Only if Me)
                if (isMe)
                  Positioned(
                    top: h(40),
                    right: w(16),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WalletScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: w(12),
                          vertical: h(6),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              color: Colors.white,
                              size: w(16),
                            ),
                            SizedBox(width: w(4)),
                            Text(
                              "Wallet",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: w(12),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Avatar
                Positioned(
                  bottom: -h(40),
                  left: w(20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: w(40),
                      backgroundImage: NetworkImage(
                        _userProfile!['avatar_url'],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: h(50)), // Space for avatar overlap
            // User Info
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userProfile!['username'],
                            style: TextStyle(
                              fontSize: w(24),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: w(6),
                                  vertical: h(2),
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.purple, Colors.blue],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Lv.${_userProfile!['level']}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: w(10),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: w(8)),
                              Text(
                                "ID: ${_userProfile!['id']}",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: w(12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Follow/Edit Button
                      if (!isMe)
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: _toggleFollow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _userProfile!['is_following']
                                        ? Colors.grey
                                        : const Color(0xFFE65E8B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: w(24),
                                ),
                              ),
                              child: Text(
                                _userProfile!['is_following']
                                    ? "Takip Ediliyor"
                                    : "Takip Et",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            // Chat Button
                            Padding(
                              padding: EdgeInsets.only(left: w(8)),
                              child: ElevatedButton(
                                onPressed: () {
                                  // Navigate to DM
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => DMScreen(
                                            otherUserId: widget.userId,
                                            otherUsername:
                                                _userProfile!['username'],
                                            otherAvatar:
                                                _userProfile!['avatar_url'],
                                          ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  shape: const CircleBorder(),
                                  padding: EdgeInsets.all(w(10)),
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_outline,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  SizedBox(height: h(16)),
                  Text(
                    _userProfile!['bio'],
                    style: TextStyle(fontSize: w(14), color: Colors.black87),
                  ),

                  SizedBox(height: h(24)),

                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        "Takipçi",
                        _userProfile!['followers_count'].toString(),
                        w,
                      ),
                      _buildStatItem(
                        "Takip",
                        _userProfile!['following_count'].toString(),
                        w,
                      ),
                      _buildStatItem("Beğeni", "5.2K", w),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WalletScreen(),
                            ),
                          );
                        },
                        child: _buildStatItem("Cüzdan", "Bakiye", w),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: h(24)),

            // Posts Grid
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Posts",
                    style: TextStyle(
                      fontSize: w(18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: h(12)),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: w(4),
                      mainAxisSpacing: w(4),
                      childAspectRatio: 1,
                    ),
                    itemCount: (_userProfile!['posts'] as List).length,
                    itemBuilder: (context, index) {
                      final post = (_userProfile!['posts'] as List)[index];
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(post['image_url']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: h(40)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Function(double) w) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: w(18), fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: w(12), color: Colors.grey)),
      ],
    );
  }
}
