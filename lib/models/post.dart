class Post {
  final String id;
  final String userId;
  final String username;
  final String avatarUrl;
  final int userLevel;
  final String text;
  final String imageUrl;
  final String timeAgo;
  final int likes;
  final int comments;
  bool isLiked;

  Post({
    required this.id,
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.userLevel,
    required this.text,
    required this.imageUrl,
    required this.timeAgo,
    required this.likes,
    required this.comments,
    this.isLiked = false,
  });
}

// Mock Data
final List<Post> mockPosts = [
  Post(
    id: '1',
    userId: '101',
    username: 'Alexander',
    avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
    userLevel: 1,
    text:
        "First of all it's illegal. It's called software piracy, and it's the same as stealing. If you are caught, it may lead to years of imprisonment in many countries.",
    imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
    timeAgo: '7 hour(s) ago',
    likes: 120,
    comments: 45,
  ),
  Post(
    id: '2',
    userId: '102',
    username: 'Henry',
    avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
    userLevel: 1,
    text:
        "Nature is not a place to visit. It is home. Check out this amazing view from my last trip!",
    imageUrl: 'https://images.unsplash.com/photo-1469474932796-b494551f53f4',
    timeAgo: '1 day(s) ago',
    likes: 85,
    comments: 12,
  ),
  Post(
    id: '3',
    userId: '103',
    username: 'Sophia',
    avatarUrl: 'https://images.unsplash.com/photo-1531123897727-8f129e1688ce',
    userLevel: 5,
    text: "Just finished recording a new song! Can't wait to share it with you all. 🎤🎶",
    imageUrl: 'https://images.unsplash.com/photo-1516280440614-6697288d5d38',
    timeAgo: '2 hour(s) ago',
    likes: 340,
    comments: 98,
  ),
];
