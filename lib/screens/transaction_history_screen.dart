import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.currentUser == null) return;

    try {
      final transactions = await _apiService.getTransactions(userProvider.currentUser!.id);
      if (mounted) {
        setState(() {
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserProvider>(context).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? const Center(child: Text("No transactions yet"))
              : ListView.separated(
                  itemCount: _transactions.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final t = _transactions[index];
                    final isSender = t['sender_id'].toString() == currentUser?.id.toString();
                    final amount = int.tryParse(t['amount'].toString()) ?? 0;
                    final date = DateTime.tryParse(t['created_at']) ?? DateTime.now();
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSender ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                        child: Icon(
                          isSender ? Icons.arrow_upward : Icons.arrow_downward,
                          color: isSender ? Colors.red : Colors.green,
                        ),
                      ),
                      title: Text(
                        isSender 
                            ? "Sent ${t['gift_name']} to ${t['receiver_name']}"
                            : "Received ${t['gift_name']} from ${t['sender_name']}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(DateFormat('MMM d, y HH:mm').format(date)),
                      trailing: Text(
                        "${isSender ? '-' : '+'}$amount",
                        style: TextStyle(
                          color: isSender ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
