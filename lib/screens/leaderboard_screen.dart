import 'package:flutter/material.dart';

class LeaderboardScreen extends StatefulWidget {
  final int initialTabIndex;

  const LeaderboardScreen({super.key, this.initialTabIndex = 0});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedSubTab = 0; // 0: Wealth, 1: Charm
  int _selectedTimePeriod = 0; // 0: Daily, 1: Weekly, 2: Monthly

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Mock Data
  final List<Map<String, dynamic>> _mockUsers = List.generate(
    20,
    (index) => {
      'rank': index + 1,
      'name': 'User ${index + 1}',
      'id': '1000$index',
      'avatar': 'https://i.pravatar.cc/150?img=${index + 1}',
      'value': (10000 - (index * 500)).toString(),
      'level': (20 - index).toString(),
    },
  );

  List<Color> _getGradientColors() {
    switch (_tabController.index) {
      case 0: // Famous - Deep Purple/Blue
        return [
          const Color(0xFF2E3192),
          const Color(0xFF1BFFFF),
        ];
      case 1: // Stars - Pink/Orange/Purple
        return [
          const Color(0xFF8E2DE2),
          const Color(0xFF4A00E0),
        ];
      case 2: // CP - Cyan/Blue
        return [
          const Color(0xFF00c6ff),
          const Color(0xFF0072ff),
        ];
      default:
        return [const Color(0xFF2E3192), const Color(0xFF1BFFFF)];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.2),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: _buildMainTabs(),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.2),
              ),
              child: const Icon(Icons.help_outline, color: Colors.white, size: 20),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getGradientColors(),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Sub Tabs (Wealth/Charm)
              _buildSubTabs(),

              const SizedBox(height: 16),
              // Time Period Tabs
              _buildTimeTabs(),

              // Update Time Info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Update time: 22:18 (GMT+3)",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content (Podium + List)
              Expanded(
                child: Stack(
                  children: [
                    // Podium Background Glow
                    Positioned(
                      top: 50,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.15),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Main Content
                    Column(
                      children: [
                        // Podium Area
                        SizedBox(
                          height: 320,
                          child: _buildPodium(),
                        ),
                        
                        // List Area
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(30),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, -5),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(30),
                              ),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: _mockUsers.length - 3,
                                itemBuilder: (context, index) {
                                  final user = _mockUsers[index + 3];
                                  return _buildListItem(user, index + 4); // index + 4 because rank starts at 4
                                },
                              ),
                            ),
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
      ),
    );
  }

  Widget _buildMainTabs() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: const Color(0xFF2E3192),
        unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: "Famous"),
          Tab(text: "Stars"),
          Tab(text: "CP"),
        ],
      ),
    );
  }

  Widget _buildSubTabs() {
    return Container(
      height: 40,
      width: 220,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(4),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            alignment:
                _selectedSubTab == 0
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
            child: Container(
              width: 104, // (220 - 8 padding) / 2 approx
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE65E8B), Color(0xFFFF9A9E)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE65E8B).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedSubTab = 0),
                  behavior: HitTestBehavior.translucent,
                  child: Center(
                    child: Text(
                      "Wealth",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            _selectedSubTab == 0
                                ? FontWeight.w800
                                : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedSubTab = 1),
                  behavior: HitTestBehavior.translucent,
                  child: Center(
                    child: Text(
                      "Charm",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            _selectedSubTab == 1
                                ? FontWeight.w800
                                : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTabs() {
    final periods = ["Daily", "Weekly", "Monthly"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(periods.length, (index) {
        bool isSelected = _selectedTimePeriod == index;
        return GestureDetector(
          onTap: () => setState(() => _selectedTimePeriod = index),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              periods[index],
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF2E3192)
                    : Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPodium() {
    if (_mockUsers.length < 3) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Rank 2 (Left)
          Positioned(
            left: 0,
            bottom: 0,
            right: MediaQuery.of(context).size.width * 0.62,
            child: _buildPodiumItem(_mockUsers[1], 2),
          ),
          // Rank 3 (Right)
          Positioned(
            right: 0,
            bottom: 0,
            left: MediaQuery.of(context).size.width * 0.62,
            child: _buildPodiumItem(_mockUsers[2], 3),
          ),
          // Rank 1 (Center - Last to render on top)
          Positioned(
            left: MediaQuery.of(context).size.width * 0.28,
            right: MediaQuery.of(context).size.width * 0.28,
            bottom: 0,
            child: _buildPodiumItem(_mockUsers[0], 1),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(Map<String, dynamic> user, int rank) {
    // 3D effect adjustments
    double height = rank == 1 ? 160 : (rank == 2 ? 130 : 110);
    double avatarSize = rank == 1 ? 46 : 36;
    
    // Premium Colors
    List<Color> gradientColors;
    Color borderColor;
    
    if (rank == 1) {
      gradientColors = [const Color(0xFFFFD700), const Color(0xFFFFA500)]; // Gold
      borderColor = const Color(0xFFFFD700);
    } else if (rank == 2) {
      gradientColors = [const Color(0xFFE0E0E0), const Color(0xFFB0B0B0)]; // Silver
      borderColor = const Color(0xFFC0C0C0);
    } else {
      gradientColors = [const Color(0xFFFFA07A), const Color(0xFFCD5C5C)]; // Bronze
      borderColor = const Color(0xFFCD7F32);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Avatar Group
        SizedBox(
          height: avatarSize * 2 + 30,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Avatar Border
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: avatarSize,
                    backgroundImage: NetworkImage(user['avatar']),
                  ),
                ),
              ),
              
              // Crown Icon (Top)
              if (rank == 1)
                Positioned(
                  top: -22,
                  child: Icon(
                    Icons.emoji_events, // Fallback if asset missing
                    color: borderColor,
                    size: 32,
                  ),
                ),

              // Rank Badge (Bottom)
              Positioned(
                bottom: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    rank.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Name
        Text(
          user['name'],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
            shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
          ),
        ),
        
        // Value
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.diamond, size: 10, color: Colors.white.withValues(alpha: 0.9)),
            const SizedBox(width: 2),
            Text(
              user['value'],
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // 3D Podium Base
        CustomPaint(
          size: Size(double.infinity, height),
          painter: PodiumPainter(
            color: Colors.white.withValues(alpha: 0.15 + (0.05 * (4-rank))),
            shadowColor: Colors.black.withValues(alpha: 0.1),
          ),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Center(
              child: Text(
                rank.toString(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListItem(Map<String, dynamic> user, int rank) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 30,
            child: Text(
              rank.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
          ),
          
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundImage: NetworkImage(user['avatar']),
            ),
          ),
          const SizedBox(width: 12),
          
          // Name & Level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, size: 8, color: Colors.white),
                          const SizedBox(width: 2),
                          Text(
                            "Lv.${user['level']}",
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "ID:${user['id']}",
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Value Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.diamond, size: 12, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  user['value'],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
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

class PodiumPainter extends CustomPainter {
  final Color color;
  final Color shadowColor;

  PodiumPainter({required this.color, required this.shadowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    // Create a trapezoid shape for 3D effect
    path.moveTo(size.width * 0.1, 0); // Top left
    path.lineTo(size.width * 0.9, 0); // Top right
    path.lineTo(size.width, size.height); // Bottom right
    path.lineTo(0, size.height); // Bottom left
    path.close();

    // Draw shadow
    canvas.drawShadow(path, shadowColor, 4, true);
    
    // Draw main shape
    canvas.drawPath(path, paint);

    // Draw top highlight (border)
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
      
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
