import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/gift.dart';
import '../providers/user_provider.dart';
import '../screens/wallet_screen.dart';

class GiftBottomSheet extends StatefulWidget {
  final int roomId;
  final int receiverId; // Who receives the gift (usually Host or user on seat)
  final Function(String message)? onGiftSent;

  const GiftBottomSheet({
    super.key,
    required this.roomId,
    required this.receiverId,
    this.onGiftSent,
  });

  @override
  State<GiftBottomSheet> createState() => _GiftBottomSheetState();
}

class _GiftBottomSheetState extends State<GiftBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedGiftIndex = -1;
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

    if (currentUser.diamonds < gift.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yetersiz bakiye'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final result = await _apiService.sendGift(
        senderId: currentUser.id,
        receiverId: widget.receiverId,
        giftId: gift.id,
        roomId: widget.roomId,
      );

      if (mounted) {
        if (result['success'] == true) {
          // Update local balance immediately
          if (result['new_balance'] != null) {
            userProvider.updateBalance(
              gift.price, // Just pass the cost, provider handles subtraction
            );
          }

          // Notify parent to show message (Optional now since backend sends it)
          // But kept for immediate local feedback if needed, or removed to avoid dupes.
          // Let's rely on backend message for the chat list, but maybe we want a toast?
          // widget.onGiftSent?.call('${currentUser.username} sent ${gift.name}');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
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
      height: 400, // Fixed height for bottom sheet
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header (Tabs)
          Container(
            height: 50,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: const Color(0xFF66B4FF),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF66B4FF),
              dividerColor: Colors.transparent,
              labelStyle: TextStyle(
                fontSize: w(14),
                fontWeight: FontWeight.bold,
              ),
              tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
            ),
          ),

          // Gift Grid
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF66B4FF),
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

          // Bottom Bar (Balance & Send)
          Container(
            padding: EdgeInsets.symmetric(horizontal: w(16), vertical: 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                // Balance
                GestureDetector(
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
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.monetization_on,
                          color: Colors.amber,
                          size: w(16),
                        ),
                        SizedBox(width: w(4)),
                        Text(
                          balance.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: w(4)),
                        const Icon(
                          Icons.add_circle,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Send Button
                GestureDetector(
                  onTap: _isSending ? null : _sendGift,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: w(24),
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _selectedGiftIndex != -1 && !_isSending
                              ? const Color(0xFF66B4FF)
                              : Colors.grey[800],
                      borderRadius: BorderRadius.circular(20),
                    ),
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
                              'Send',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
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
    // In real app, API should support category filtering or we filter locally
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
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
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
          child: Container(
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? const Color(0xFF66B4FF).withValues(alpha: 0.2)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border:
                  isSelected
                      ? Border.all(color: const Color(0xFF66B4FF), width: 2)
                      : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Gift Icon (Placeholder logic since we don't have real images yet)
                Icon(Icons.card_giftcard, color: Colors.pink, size: w(32)),
                const SizedBox(height: 8),
                Text(
                  gift.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: w(12),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: w(10),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      gift.price.toString(),
                      style: TextStyle(color: Colors.white70, fontSize: w(10)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
