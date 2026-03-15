import 'package:flutter/material.dart';
import '../models/post.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final List<Post> _allPosts = mockPosts;
  // Mock followers posts (subset of all posts for demo)
  late List<Post> _followersPosts;
  int _selectedTab = 0; // 0: Explore, 1: Followers

  @override
  void initState() {
    super.initState();
    // Create some dummy follower posts
    _followersPosts = [
      _allPosts[0], // Alexander
      Post(
        id: '4',
        userId: '104',
        username: 'Followed User',
        avatarUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d',
        userLevel: 3,
        text:
            "This is a post from someone you follow! Only visible in Followers tab.",
        imageUrl:
            'https://images.unsplash.com/photo-1507525428034-b723cf961d3e',
        timeAgo: '5 min ago',
        likes: 10,
        comments: 2,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double designWidth = 414.0;
    // final double designHeight = 896.0;

    double w(double width) => width * (screenSize.width / designWidth);
    // double h(double height) => height * (screenSize.height / designHeight);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w(16), vertical: w(10)),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Text(
                      'Explore',
                      style: TextStyle(
                        fontSize: w(24),
                        fontWeight:
                            _selectedTab == 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                        color:
                            _selectedTab == 0
                                ? Colors.black
                                : Colors.grey.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  SizedBox(width: w(16)),
                  GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Text(
                      'Followers',
                      style: TextStyle(
                        fontSize: w(24),
                        fontWeight:
                            _selectedTab == 1
                                ? FontWeight.bold
                                : FontWeight.normal,
                        color:
                            _selectedTab == 1
                                ? Colors.black
                                : Colors.grey.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      // Search logic
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
                  SizedBox(width: w(16)),
                  GestureDetector(
                    onTap: () {
                      // Rank logic
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

            // Feed
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount:
                    _selectedTab == 0
                        ? _allPosts.length
                        : _followersPosts.length,
                itemBuilder: (context, index) {
                  final post =
                      _selectedTab == 0
                          ? _allPosts[index]
                          : _followersPosts[index];
                  return _buildPostItem(post, w);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostItem(Post post, double Function(double) w) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w(16), vertical: w(12)),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: User Info + Follow Button
          Row(
            children: [
              CircleAvatar(
                radius: w(20),
                backgroundImage: NetworkImage(post.avatarUrl),
              ),
              SizedBox(width: w(12)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.username,
                    style: TextStyle(
                      fontSize: w(16),
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: w(2)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: w(6),
                      vertical: w(2),
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.orange, Colors.red],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.white, size: w(10)),
                        SizedBox(width: w(2)),
                        Text(
                          "Lv${post.userLevel}",
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
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: w(16),
                  vertical: w(6),
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Follow',
                  style: TextStyle(
                    color: const Color(0xFF305FF2), // Blue like in design
                    fontWeight: FontWeight.bold,
                    fontSize: w(12),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: w(12)),

          // Text Content
          Text(
            post.text,
            style: TextStyle(
              fontSize: w(14),
              color: Colors.black87,
              height: 1.4,
            ),
          ),

          SizedBox(height: w(12)),

          // Image Content
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              post.imageUrl,
              width: double.infinity,
              height: w(
                250,
              ), // Aspect ratio from design looks like ~4:3 or square
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: w(200),
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: w(12)),

          // Time Ago
          Text(
            post.timeAgo,
            style: TextStyle(color: Colors.grey, fontSize: w(12)),
          ),

          SizedBox(height: w(12)),

          // Action Buttons
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    post.isLiked = !post.isLiked;
                  });
                },
                child: Icon(
                  post.isLiked ? Icons.favorite : Icons.favorite_border,
                  color: post.isLiked ? Colors.red : Colors.black54,
                  size: w(24),
                ),
              ),
              SizedBox(width: w(20)),
              Icon(
                Icons.chat_bubble_outline,
                color: Colors.black54,
                size: w(24),
              ),
              const Spacer(),
              Icon(Icons.more_horiz, color: Colors.black54, size: w(24)),
            ],
          ),
        ],
      ),
    );
  }
}
