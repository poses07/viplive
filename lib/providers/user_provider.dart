import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  // Real Login
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.login(username, password);
      
      if (result['success'] == true) {
        // If diamonds field is missing or 0, give default for testing
        Map<String, dynamic> userData = Map.from(result['user']);
        if (userData['diamonds'] == null || userData['diamonds'] == 0) {
           userData['diamonds'] = 5000; // Mock balance for testing
        }
        
        _currentUser = User.fromJson(userData);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        debugPrint('Login failed: ${result['error']}');
      }
    } catch (e) {
      debugPrint('Login error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Real Register
  Future<bool> register({
    required String username,
    required String password,
    String gender = '',
    String country = '',
    String dob = '',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.register(
        username: username,
        password: password,
        gender: gender,
        country: country,
        dob: dob,
      );

      if (result['success'] == true) {
        _currentUser = User.fromJson(result['user']);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        debugPrint('Register failed: ${result['error']}');
      }
    } catch (e) {
      debugPrint('Register error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  void updateBalance(int cost) {
    if (_currentUser != null) {
      _currentUser = User(
        id: _currentUser!.id,
        username: _currentUser!.username,
        avatarUrl: _currentUser!.avatarUrl,
        level: _currentUser!.level,
        diamonds: _currentUser!.diamonds - cost,
        beans: _currentUser!.beans + cost, // Assuming beans increase when receiving? Or just decrement diamonds
        isHost: _currentUser!.isHost,
      );
      notifyListeners();
    }
  }

  // Mock login for development
  Future<void> loginMock() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    // Simulate logged in user (ID: 1 is Alexander in our DB)
    _currentUser = User(
      id: 1,
      username: 'Alexander',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
      level: 5,
      diamonds: 1000,
      isHost: true,
    );

    _isLoading = false;
    notifyListeners();
  }
}
