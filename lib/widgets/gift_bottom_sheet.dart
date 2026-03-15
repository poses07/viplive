import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/gift.dart';
import '../providers/user_provider.dart';
import '../screens/wallet_screen.dart';

class GiftBottomSheet extends StatefulWidget {
  final Function(Map<String, dynamic> gift)? onSendGift;
  final Map<String, dynamic>? receiver; // Receiver info (name, avatar)

  const GiftBottomSheet({
    super.key,
    this.onSendGift,
    this.receiver, // Add receiver parameter
  });

  @override
  State<GiftBottomSheet> createState() => _GiftBottomSheetState();
}

class _GiftBottomSheetState extends State<GiftBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedGiftIndex = -1;
  int _selectedQuantity = 1; // Default quantity
  final List<int> _quantities = [1, 9, 49, 99, 499]; // Quantity options

  // _balance is now managed by UserProvider, but we keep a local variable for immediate UI updates if needed
  // or better, directly use provider data. Let's use provider data.

  final ApiService _apiService = ApiService();
  List<Gift> _gifts = [];
  bool _isLoading = true;
  bool _isSending = false;

  final List<String> _tabs = [
    'Popular',
    'Lucky',
    'Luxury',
    'Classic',
    'Privilege',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _fetchGifts();
  }

  Future<void> _fetchGifts() async {
    try {
      final gifts = await _apiService.getGifts();
      if (mounted) {
        setState(() {
          _gifts = gifts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading gifts: $e')));
      }
    }
  }

  Future<void> _sendGift() async {
    if (_selectedGiftIndex == -1) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    if (currentUser == null) return;

    final gift = _gifts[_selectedGiftIndex];
    final int totalPrice = gift.price * _selectedQuantity;

    if (currentUser.diamonds < totalPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yetersiz bakiye (Gerekli: $totalPrice)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Delegate sending logic to parent via callback
    if (widget.onSendGift != null) {
      setState(() => _isSending = true);

      // Call parent and wait (if parent returns Future, but currently it returns void/dynamic)
      // Since we don't know if parent is async, we just call it.
      // Ideally, onSendGift should return a Future<bool> to stop loading.
      // For now, we assume parent handles UI feedback (closing sheet or showing success).

      await widget.onSendGift!({
        'id': gift.id,
        'name': gift.name,
        'price': gift.price,
        'icon': gift.iconUrl,
        'quantity': _selectedQuantity,
      });

      if (mounted) {
        setState(() => _isSending = false);
      }
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
    double w(double width) => width * (screenSize.width / designWidth);

    final user = Provider.of<UserProvider>(context).currentUser;
    final int balance = user?.diamonds ?? 0;

    return Container(
      height: 480, // Slightly taller for premium feel
      decoration: BoxDecoration(
        color: const Color(
          0xFF121212,
        ).withValues(alpha: 0.95), // Deep dark background
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header (Receiver Info & Tabs)
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              children: [
                // Receiver Info (Top Left)
                if (widget.receiver != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE65E8B), Color(0xFFFF9A9E)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFE65E8B,
                                ).withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundImage: NetworkImage(
                              widget.receiver!['avatar'] ??
                                  'https://i.pravatar.cc/150',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Sending to",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              widget.receiver!['name'] ?? 'Unknown',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Balance Display (Top Right)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.diamond,
                                color: Colors.cyanAccent,
                                size: w(14),
                              ),
                              SizedBox(width: w(4)),
                              Text(
                                balance.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(width: w(6)),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => const WalletScreen(),
                                    ),
                                  );
                                },
                                child: Icon(
                                  Icons.add_circle,
                                  color: const Color(0xFFE65E8B),
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Modern Tabs
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
                  indicatorColor: const Color(0xFFE65E8B),
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorWeight: 3,
                  dividerColor: Colors.transparent,
                  labelStyle: TextStyle(
                    fontSize: w(14),
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: w(14),
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
                ),
              ],
            ),
          ),

          // Gift Grid
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE65E8B),
                      ),
                    )
                    : TabBarView(
                      controller: _tabController,
                      children: List.generate(
                        _tabs.length,
                        (index) => _buildGiftGrid(w, index),
                      ),
                    ),
          ),

          // Bottom Action Bar
          Container(
            padding: EdgeInsets.fromLTRB(w(16), 12, w(16), 24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  offset: const Offset(0, -4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                // Quantity Selector
                Expanded(
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children:
                          _quantities.map((q) {
                            bool isSelected = _selectedQuantity == q;
                            return GestureDetector(
                              onTap:
                                  () => setState(() => _selectedQuantity = q),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? const Color(0xFFE65E8B)
                                          : Colors.transparent,
                                  shape: BoxShape.circle,
                                  boxShadow:
                                      isSelected
                                          ? [
                                            BoxShadow(
                                              color: const Color(
                                                0xFFE65E8B,
                                              ).withValues(alpha: 0.4),
                                              blurRadius: 8,
                                            ),
                                          ]
                                          : null,
                                ),
                                child: Text(
                                  q.toString(),
                                  style: TextStyle(
                                    color:
                                        isSelected ? Colors.white : Colors.grey,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),

                SizedBox(width: w(12)),

                // Send Button
                GestureDetector(
                  onTap: _isSending ? null : _sendGift,
                  child: Container(
                    height: 44,
                    padding: EdgeInsets.symmetric(horizontal: w(24)),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors:
                            _selectedGiftIndex != -1 && !_isSending
                                ? [
                                  const Color(0xFFE65E8B),
                                  const Color(0xFFFF9A9E),
                                ]
                                : [Colors.grey[800]!, Colors.grey[700]!],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow:
                          _selectedGiftIndex != -1 && !_isSending
                              ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFFE65E8B,
                                  ).withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                              : null,
                    ),
                    alignment: Alignment.center,
                    child:
                        _isSending
                            ? SizedBox(
                              width: w(20),
                              height: w(20),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text(
                              "SEND",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                letterSpacing: 1,
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

  Widget _buildGiftGrid(double Function(double) w, int tabIndex) {
    // Filter gifts by category (mock logic for now as API returns all)
    final categoryGifts = _gifts;

    if (categoryGifts.isEmpty) {
      return const Center(
        child: Text(
          'No gifts available',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: categoryGifts.length,
      itemBuilder: (context, index) {
        bool isSelected = _selectedGiftIndex == index;
        final gift = categoryGifts[index];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedGiftIndex = index;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? const Color(0xFFE65E8B).withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isSelected ? const Color(0xFFE65E8B) : Colors.transparent,
                width: 1.5,
              ),
              boxShadow:
                  isSelected
                      ? [
                        BoxShadow(
                          color: const Color(0xFFE65E8B).withValues(alpha: 0.2),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                      : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Gift Icon (Ideally from URL)
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Image.network(
                    gift.iconUrl,
                    width: w(40),
                    height: w(40),
                    errorBuilder:
                        (_, __, ___) => Icon(
                          Icons.card_giftcard,
                          color: Colors.pinkAccent,
                          size: w(32),
                        ),
                  ),
                ),

                const SizedBox(height: 4),
                Text(
                  gift.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: w(11),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.diamond,
                        color: Colors.cyanAccent,
                        size: w(10),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        gift.price.toString(),
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
          ),
        );
      },
    );
  }
}
