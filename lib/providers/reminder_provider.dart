import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/firebase_database_service.dart';
import '../models/reminder_model.dart';

class ReminderProvider with ChangeNotifier {
  List<Reminder> _reminders = [];
  Timer? _timer;
  String? _currentUserId;
  final FirebaseDatabaseService _firebaseService = FirebaseDatabaseService();

  void setCurrentUserId(String userId) {
    _currentUserId = userId;
    notifyListeners();
  }

  List<Reminder> get reminders {
    if (_currentUserId == null) return [];
    return _reminders.where((r) => r.userId == _currentUserId).toList();
  }

  Future<void> loadReminders() async {
    try {
      if (_currentUserId == null) {
        _reminders = [];
        notifyListeners();
        return;
      }
      
      // Try to load from Firebase first
      _reminders = await _firebaseService.getReminders();
      
      // If Firebase returns empty, try local storage
      if (_reminders.isEmpty) {
        await _loadRemindersFromLocal();
      } else {
        // Save Firebase data to local for backup
        await _saveRemindersToLocal();
      }
      
      _scheduleNextReminder();
      notifyListeners();
      debugPrint('Loaded ${_reminders.length} reminders');
    } catch (e) {
      debugPrint('Error loading reminders: $e');
      // Fallback to local storage
      await _loadRemindersFromLocal();
      _scheduleNextReminder();
      notifyListeners();
    }
  }

  Future<void> _loadRemindersFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersJson = prefs.getString('reminders_$_currentUserId') ?? '[]';
      final remindersList = json.decode(remindersJson) as List;
      
      _reminders = remindersList.map((reminder) => Reminder.fromJson(reminder)).toList();
      debugPrint('Loaded ${_reminders.length} reminders from local storage');
    } catch (e) {
      debugPrint('Error loading reminders from local: $e');
      _reminders = [];
    }
  }

  Future<void> _saveRemindersToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersJson = json.encode(_reminders.map((reminder) => reminder.toJson()).toList());
      await prefs.setString('reminders_$_currentUserId', remindersJson);
      debugPrint('Saved ${_reminders.length} reminders to local storage');
    } catch (e) {
      debugPrint('Error saving reminders to local: $e');
    }
  }

  Future<void> addReminder(Reminder reminder) async {
    try {
      final savedReminderId = await _firebaseService.saveReminder(reminder);
      final savedReminder = reminder.copyWith(id: savedReminderId);
      _reminders.add(savedReminder);
      await _saveRemindersToLocal(); // Also save locally
      _scheduleNextReminder();
      notifyListeners();
      debugPrint('Reminder added: ${savedReminder.id}');
    } catch (e) {
      debugPrint('Error adding reminder: $e');
      // Save locally even if Firebase fails
      final localReminder = reminder.copyWith(id: reminder.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : reminder.id);
      _reminders.add(localReminder);
      await _saveRemindersToLocal();
      _scheduleNextReminder();
      notifyListeners();
    }
  }

  Future<void> updateReminder(Reminder reminder) async {
    try {
      await _firebaseService.saveReminder(reminder);
      final index = _reminders.indexWhere((r) => r.id == reminder.id);
      if (index != -1) {
        _reminders[index] = reminder;
      } else {
        _reminders.add(reminder);
      }
      await _saveRemindersToLocal(); // Also save locally
      _scheduleNextReminder();
      notifyListeners();
      debugPrint('Reminder updated: ${reminder.id}');
    } catch (e) {
      debugPrint('Error updating reminder: $e');
      // Update locally even if Firebase fails
      final index = _reminders.indexWhere((r) => r.id == reminder.id);
      if (index != -1) {
        _reminders[index] = reminder;
      } else {
        _reminders.add(reminder);
      }
      await _saveRemindersToLocal();
      _scheduleNextReminder();
      notifyListeners();
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    try {
      await _firebaseService.deleteReminder(reminderId);
      _reminders.removeWhere((reminder) => reminder.id == reminderId);
      await _saveRemindersToLocal(); // Also save locally
      _scheduleNextReminder();
      notifyListeners();
      debugPrint('Reminder deleted: $reminderId');
    } catch (e) {
      debugPrint('Error deleting reminder: $e');
      // Delete locally even if Firebase fails
      _reminders.removeWhere((reminder) => reminder.id == reminderId);
      await _saveRemindersToLocal();
      _scheduleNextReminder();
      notifyListeners();
    }
  }

  List<Reminder> getRemindersForDay(DateTime day) {
    if (_currentUserId == null) return [];
    return _reminders.where((reminder) {
      if (reminder.userId != _currentUserId) return false;
      return reminder.reminderAt.year == day.year &&
             reminder.reminderAt.month == day.month &&
             reminder.reminderAt.day == day.day;
    }).toList();
  }

  void _scheduleNextReminder() {
    _timer?.cancel();
    
    final upcomingReminders = _reminders
        .where((r) => r.userId == _currentUserId && !r.isCompleted && r.reminderAt.isAfter(DateTime.now()))
        .toList();
    
    if (upcomingReminders.isEmpty) return;
    
    upcomingReminders.sort((a, b) => a.reminderAt.compareTo(b.reminderAt));
    final nextReminder = upcomingReminders.first;
    final duration = nextReminder.reminderAt.difference(DateTime.now());
    
    if (duration.inMilliseconds > 0) {
      _timer = Timer(duration, () {
        _triggerReminder(nextReminder);
      });
    }
  }

  void _triggerReminder(Reminder reminder) {
    // This would trigger a notification
    // For now, we'll just mark it as triggered
    final updatedReminder = reminder.copyWith(isTriggered: true);
    updateReminder(updatedReminder);
    _scheduleNextReminder();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
