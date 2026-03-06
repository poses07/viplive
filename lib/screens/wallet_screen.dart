import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    // Responsive helper
    final Size screenSize = MediaQuery.of(context).size;
    final double designWidth = 414.0;
    final double designHeight = 896.0;
    double w(double width) => width * (screenSize.width / designWidth);
    double h(double height) => height * (screenSize.height / designHeight);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cüzdan',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Transaction History Logic
            },
            child: const Text(
              'Kayıtlar',
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(w(20)),
        child: Column(
          children: [
            // Balance Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(w(20)),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE65E8B), Color(0xFFFF9A9E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE65E8B).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mevcut Bakiye',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: w(14),
                    ),
                  ),
                  SizedBox(height: h(10)),
                  Row(
                    children: [
                      Icon(Icons.diamond, color: Colors.white, size: w(32)),
                      SizedBox(width: w(10)),
                      Text(
                        '${user?.diamonds ?? 0}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: w(36),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: h(20)),
                  Row(
                    children: [
                      _buildBalanceItem(Icons.local_activity, '${user?.beans ?? 0} Fasulye', w),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: h(30)),

            // Purchase Options
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Elmas Yükle',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: h(15)),

            _buildPurchaseOption(100, 1.99, w, h, context),
            _buildPurchaseOption(500, 8.99, w, h, context),
            _buildPurchaseOption(1000, 16.99, w, h, context, isBest: true),
            _buildPurchaseOption(5000, 79.99, w, h, context),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceItem(IconData icon, String text, Function(double) w) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w(12), vertical: w(6)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: w(16)),
          SizedBox(width: w(5)),
          Text(
            text,
            style: TextStyle(color: Colors.white, fontSize: w(14), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseOption(int amount, double price, Function(double) w, Function(double) h, BuildContext context, {bool isBest = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: h(15)),
      padding: EdgeInsets.symmetric(horizontal: w(20), vertical: h(15)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(w(10)),
            decoration: BoxDecoration(
              color: const Color(0xFFE65E8B).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.diamond, color: const Color(0xFFE65E8B), size: w(24)),
          ),
          SizedBox(width: w(15)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$amount Elmas',
                style: TextStyle(fontSize: w(16), fontWeight: FontWeight.bold),
              ),
              if (isBest)
                Container(
                  margin: EdgeInsets.only(top: h(4)),
                  padding: EdgeInsets.symmetric(horizontal: w(6), vertical: h(2)),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'EN İYİ FİYAT',
                    style: TextStyle(fontSize: w(10), fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              // Mock Purchase
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Satın alma işlemi simüle edildi (Mock)')),
              );
              // In real app, call payment provider here
              // Provider.of<UserProvider>(context, listen: false).addDiamonds(amount);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFE65E8B),
              side: const BorderSide(color: Color(0xFFE65E8B)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            child: Text('\$$price'),
          ),
        ],
      ),
    );
  }
}
