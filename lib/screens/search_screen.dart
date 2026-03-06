import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/room.dart';
import 'profile_screen.dart';
import 'live_room_screen.dart';
import 'chat_party_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  List<dynamic> _userResults = [];
  List<Room> _roomResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final results = await _apiService.search(query);
      if (mounted) {
        setState(() {
          _userResults = results['users'] ?? [];
          
          final roomList = results['rooms'] as List? ?? [];
          _roomResults = roomList.map((json) => Room.fromJson(json)).toList();
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Search users or rooms...',
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
            onSubmitted: _performSearch,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFE65E8B),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFE65E8B),
          tabs: const [
            Tab(text: 'Users'),
            Tab(text: 'Rooms'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Users Tab
                _userResults.isEmpty
                    ? const Center(child: Text("No users found"))
                    : ListView.builder(
                        itemCount: _userResults.length,
                        itemBuilder: (context, index) {
                          final user = _userResults[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                user['avatar_url'] ?? 'https://i.pravatar.cc/150',
                              ),
                            ),
                            title: Text(user['username']),
                            subtitle: Text("Level ${user['level']}"),
                            trailing: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfileScreen(
                                      userId: int.parse(user['id'].toString()),
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE65E8B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                minimumSize: const Size(60, 30),
                              ),
                              child: const Text("View", style: TextStyle(fontSize: 12)),
                            ),
                          );
                        },
                      ),

                // Rooms Tab
                _roomResults.isEmpty
                    ? const Center(child: Text("No rooms found"))
                    : ListView.builder(
                        itemCount: _roomResults.length,
                        itemBuilder: (context, index) {
                          final room = _roomResults[index];
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                room.hostAvatar ?? 'https://i.pravatar.cc/150',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(room.title),
                            subtitle: Text("${room.hostName} • ${room.roomType.toUpperCase()}"),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              if (room.roomType == 'live') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LiveRoomScreen(
                                      roomTitle: room.title,
                                      roomTag: room.tag,
                                    ),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatPartyScreen(
                                      roomTitle: room.title,
                                      roomId: room.id,
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
              ],
            ),
    );
  }
}
