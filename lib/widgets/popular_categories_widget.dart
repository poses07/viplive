import 'package:flutter/material.dart';
import '../screens/leaderboard_screen.dart';

class PopularCategoriesWidget extends StatelessWidget {
  const PopularCategoriesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Design dimensions based on Figma (371 width scaled)
    // We use a Row with Expanded children to fit screen width
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            const LeaderboardScreen(initialTabIndex: 0),
                  ),
                );
              },
              child: _buildCategoryCard(
                title: "Famous",
                colors: [const Color(0xFFE94057), const Color(0xFFF27121)],
                icon: Icons.emoji_events,
                iconColor: Colors.yellow,
                badgeIcon: 'assets/images/icon_trophy.png',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            const LeaderboardScreen(initialTabIndex: 2),
                  ),
                );
              },
              child: _buildCategoryCard(
                title: "CP",
                colors: [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
                icon: Icons.favorite,
                iconColor: Colors.pinkAccent,
                badgeIcon: 'assets/images/icon_heart.png',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            const LeaderboardScreen(initialTabIndex: 1),
                  ),
                );
              },
              child: _buildCategoryCard(
                title: "Top Room",
                colors: [const Color(0xFF00c6ff), const Color(0xFF0072ff)],
                icon: Icons.star,
                iconColor: Colors.blueAccent,
                badgeIcon: 'assets/images/icon_star.png',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required List<Color> colors,
    required IconData icon,
    required Color iconColor,
    required String badgeIcon, // Changed to String for asset path
  }) {
    return Container(
      height: 60, // Fixed height from design (approx 59px)
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Icon (Faded)
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.2),
              size: 50,
            ),
          ),

          // Title
          Positioned(
            top: 10,
            left: 12,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                fontFamily: 'Inter',
              ),
            ),
          ),

          // Badge Icon (Top Right)
          if (badgeIcon.isNotEmpty)
            Positioned(
              top: 5,
              right: 5,
              child: Image.asset(
                badgeIcon,
                width: 20,
                height: 20,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),

          // Avatars (Bottom Left)
          Positioned(
            bottom: 8,
            left: 12,
            child: SizedBox(
              width: 60,
              height: 20,
              child: Stack(
                children: [
                  _buildMiniAvatar(0, 'https://i.pravatar.cc/100?img=10'),
                  _buildMiniAvatar(14, 'https://i.pravatar.cc/100?img=20'),
                  _buildMiniAvatar(28, 'https://i.pravatar.cc/100?img=30'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniAvatar(double left, String url) {
    return Positioned(
      left: left,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
          image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
        ),
      ),
    );
  }
}
