import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';
import 'dart:async';

class DMScreen extends StatefulWidget {
  final int otherUserId;
  final String otherUsername;
  final String? otherAvatar;

  const DMScreen({
    super.key,
    required this.otherUserId,
    required this.otherUsername,
    this.otherAvatar,
  });

  @override
  State<DMScreen> createState() => _DMScreenState();
}

class _DMScreenState extends State<DMScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ApiService _apiService = ApiService();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  int _lastMessageId = 0;
  Timer? _pollingTimer;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    // Poll for new messages every 3 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchMessages(background: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages({bool background = false}) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.currentUser == null) return;

    try {
      final messages = await _apiService.getDMs(
        userProvider.currentUser!.id,
        widget.otherUserId,
        afterId: _lastMessageId,
      );

      if (messages.isNotEmpty) {
        if (mounted) {
          setState(() {
            for (var msg in messages) {
              _messages.add({
                'id': msg['id'],
                'content': msg['content'],
                'isMe':
                    msg['sender_id'].toString() ==
                    userProvider.currentUser!.id.toString(),
                'time': DateTime.parse(msg['created_at']),
              });
              _lastMessageId =
                  int.tryParse(msg['id'].toString()) ?? _lastMessageId;
            }
            if (!background) _isLoading = false;
          });

          // Scroll to bottom
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      } else {
        if (!background && mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (!background && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.currentUser == null) return;

    final content = _messageController.text;
    _messageController.clear();

    // Optimistic UI Update
    setState(() {
      _messages.add({
        'id': -1, // Temporary ID
        'content': content,
        'isMe': true,
        'time': DateTime.now(),
      });
    });

    try {
      final success = await _apiService.sendDM(
        userProvider.currentUser!.id,
        widget.otherUserId,
        content,
      );

      if (success) {
        // Refresh to get the real message with ID
        _fetchMessages(background: true);
      } else {
        // Handle error (maybe show retry icon)
      }
    } catch (e) {
      debugPrint("Error sending DM: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(
                widget.otherAvatar ?? 'https://i.pravatar.cc/150',
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.otherUsername,
              style: const TextStyle(color: Colors.black, fontSize: 16),
            ),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isMe = msg['isMe'] as bool;
                        return Align(
                          alignment:
                              isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isMe
                                      ? const Color(0xFFE65E8B)
                                      : Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              msg['content'],
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Color(0xFFE65E8B),
                          ),
                          onPressed: _sendMessage,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
