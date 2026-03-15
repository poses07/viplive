import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
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

      if (mounted) {
        setState(() {
          _userProfile = profileData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFE65E8B)),
        ),
      );
    }

    if (_userProfile == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(child: Text("User not found")),
      );
    }

    final currentUser = Provider.of<UserProvider>(context).currentUser;
    final bool isMe = currentUser?.id == widget.userId;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFDEBF3), // Light pinkish top
              Color(0xFFF4F6F9), // Light greyish bottom
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 1. Profile Card
                _buildProfileCard(isMe),
                const SizedBox(height: 16),

                // 2. Quick Actions Card
                _buildQuickActionsCard(),
                const SizedBox(height: 16),

                // 3. List Group 1 (VIP, Bags, etc.)
                _buildMenuCard([
                  _MenuItem(
                    icon: Icons.emoji_events,
                    color: Colors.orange,
                    label: "VIP",
                  ),
                  _MenuItem(
                    icon: Icons.local_mall,
                    color: Colors.brown,
                    label: "My Bags",
                  ),
                  _MenuItem(
                    icon: Icons.verified,
                    color: Colors.amber,
                    label: "Badge",
                  ),
                  _MenuItem(
                    icon: Icons.card_giftcard,
                    color: Colors.pink,
                    label: "Gift",
                  ),
                ]),
                const SizedBox(height: 16),

                // 4. List Group 2 (Family, CP)
                _buildMenuCard([
                  _MenuItem(
                    icon: Icons.group,
                    color: Colors.cyan,
                    label: "Family",
                  ),
                  _MenuItem(
                    icon: Icons.favorite,
                    color: Colors.red,
                    label: "CP",
                  ),
                ]),
                const SizedBox(height: 16),

                // 5. List Group 3 (Centers, Settings)
                _buildMenuCard([
                  _MenuItem(
                    icon: Icons.mic,
                    color: Colors.purple,
                    label: "Host Center",
                  ),
                  _MenuItem(
                    icon: Icons.business,
                    color: Colors.green,
                    label: "Agency Center",
                  ),
                  _MenuItem(
                    icon: Icons.chat_bubble,
                    color: Colors.blue,
                    label: "BD Center",
                  ),
                  _MenuItem(
                    icon: Icons.person_add,
                    color: Colors.indigo,
                    label: "Invite Friends",
                  ),
                  if (isMe)
                    _MenuItem(
                      icon: Icons.settings,
                      color: Colors.grey,
                      label: "Settings",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                ]),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(bool isMe) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Profile",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 35,
                  backgroundImage: NetworkImage(
                    _userProfile!['avatar_url'] ?? 'https://i.pravatar.cc/150',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userProfile!['username'] ?? "Unknown",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "ID: ${_userProfile!['id']}",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Arrow
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 30),
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem("0", "Visitors"),
              _buildDivider(),
              _buildStatItem("0", "Following"),
              _buildDivider(),
              _buildStatItem("0", "Fans"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 20, width: 1, color: Colors.grey[300]);
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickAction(Icons.store, "Store", Colors.orangeAccent),
          _buildQuickAction(Icons.star, "Aristocracy", Colors.amberAccent),
          _buildQuickAction(Icons.diamond, "Level", Colors.blueAccent),
          _buildQuickAction(
            Icons.account_balance_wallet,
            "Wallet",
            Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WalletScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    IconData icon,
    String label,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children:
            items.map((item) {
              return InkWell(
                onTap: item.onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Icon(item.icon, color: item.color, size: 24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;

  _MenuItem({
    required this.icon,
    required this.color,
    required this.label,
    this.onTap,
  });
}
