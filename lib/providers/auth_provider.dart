import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  Future<void> loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('currentUser');
      
      if (userJson != null) {
        _currentUser = User.fromJson(json.decode(userJson));
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user: $e');
    }
  }

  Future<void> register(String username, String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('users') ?? '[]';
      final usersList = json.decode(usersJson) as List;
      
      // Check if user already exists
      if (usersList.any((user) => user['email'] == email)) {
        _setError('Email already registered');
        return;
      }

      if (usersList.any((user) => user['username'] == username)) {
        _setError('Username already taken');
        return;
      }

      // Create new user
      final newUser = User(
        id: const Uuid().v4(),
        username: username,
        email: email,
        password: User.hashPassword(password),
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      usersList.add(newUser.toJson());
      await prefs.setString('users', json.encode(usersList));
      
      // Auto login after registration
      await _loginUser(newUser);
    } catch (e) {
      _setError('Registration failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('users') ?? '[]';
      final usersList = json.decode(usersJson) as List;

      final user = usersList.firstWhere(
        (user) => user['email'] == email,
        orElse: () => null,
      );

      if (user == null) {
        _setError('User not found');
        return;
      }

      if (!User.verifyPassword(password, user['password'])) {
        _setError('Incorrect password');
        return;
      }

      // Update last login
      user['lastLogin'] = DateTime.now().toIso8601String();
      
      // Update users list
      final userIndex = usersList.indexWhere((u) => u['email'] == email);
      usersList[userIndex] = user;
      await prefs.setString('users', json.encode(usersList));

      await _loginUser(User.fromJson(user));
    } catch (e) {
      _setError('Login failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('currentUser');
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  Future<void> updateProfile({String? username, String? email}) async {
    if (_currentUser == null) return;

    _setLoading(true);
    _clearError();

    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('users') ?? '[]';
      final usersList = json.decode(usersJson) as List;

      final userIndex = usersList.indexWhere((u) => u['id'] == _currentUser!.id);
      if (userIndex == -1) return;

      // Check if new email/username is already taken
      if (email != null && email != _currentUser!.email) {
        if (usersList.any((u) => u['email'] == email && u['id'] != _currentUser!.id)) {
          _setError('Email already registered');
          return;
        }
      }

      if (username != null && username != _currentUser!.username) {
        if (usersList.any((u) => u['username'] == username && u['id'] != _currentUser!.id)) {
          _setError('Username already taken');
          return;
        }
      }

      // Update user
      final updatedUser = _currentUser!.copyWith(
        username: username,
        email: email,
      );

      usersList[userIndex] = updatedUser.toJson();
      await prefs.setString('users', json.encode(usersList));
      await prefs.setString('currentUser', json.encode(updatedUser.toJson()));

      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      _setError('Profile update failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loginUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentUser', json.encode(user.toJson()));
    _currentUser = user;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
