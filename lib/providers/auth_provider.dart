import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/database_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  final DatabaseService _databaseService = DatabaseService();

  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('current_user');

      if (username != null && username.isNotEmpty) {
        _currentUser = await _databaseService.getUser(username);
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
      // Clear invalid user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _databaseService.authenticateUser(username, password);

      if (user != null) {
        _currentUser = user;

        // Debug info
        debugPrint('Login successful!');
        debugPrint('User: ${user.name}');
        debugPrint('Username: ${user.username}');
        debugPrint('Role: ${user.role}');
        debugPrint('Is Active: ${user.isActive}');

        // Save to preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user', username);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        debugPrint('Login failed: User not found or invalid credentials');
      }
    } catch (e) {
      debugPrint('Error during login: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;

    // Clear preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');

    notifyListeners();
  }
}
