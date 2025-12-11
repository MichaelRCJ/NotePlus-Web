import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/reminder_model.dart';
import '../services/cloud_storage_service.dart';

class CloudReminderProvider with ChangeNotifier {
  List<Reminder> _reminders = [];
  Timer? _timer;
  String? _currentUserId;
  final CloudStorageService _cloudService = CloudStorageService();
  bool _isCloudEnabled = false;
  bool _isSyncing = false;

  void setCurrentUserId(String userId) {
    _currentUserId = userId;
    notifyListeners();
  }

  void setCloudEnabled(bool enabled) {
    _isCloudEnabled = enabled;
    notifyListeners();
  }

  bool get isCloudEnabled => _isCloudEnabled;
  bool get isSyncing => _isSyncing;

  List<Reminder> get reminders {
    if (_currentUserId == null) return [];
    return _reminders.where((r) => r.userId == _currentUserId).toList();
  }

  Future<void> loadReminders() async {
    try {
      _isSyncing = true;
      notifyListeners();

      if (_isCloudEnabled && _cloudService.isAuthenticated) {
        // Load from cloud
        final cloudReminders = await _cloudService.loadReminders();
        _reminders = cloudReminders;
        
        // Also save to local storage for backup
        await _saveToLocal();
      } else {
        // Load from local storage
        await _loadFromLocal();
      }
      
      _scheduleNextReminder();
      debugPrint('Loaded ${_reminders.length} reminders (${_isCloudEnabled ? "cloud" : "local"})');
    } catch (e) {
      debugPrint('Error loading reminders: $e');
      // Fallback to local storage
      await _loadFromLocal();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getString('reminders') ?? '[]';
    final remindersList = json.decode(remindersJson) as List;
    _reminders = remindersList.map((reminder) => Reminder.fromJson(reminder)).toList();
  }

  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersJson = json.encode(_reminders.map((reminder) => reminder.toJson()).toList());
      await prefs.setString('reminders', remindersJson);
    } catch (e) {
      debugPrint('Error saving reminders locally: $e');
    }
  }

  Future<void> saveReminders() async {
    try {
      if (_isCloudEnabled && _cloudService.isAuthenticated) {
        // Save to cloud
        for (final reminder in _reminders) {
          await _cloudService.saveReminder(reminder);
        }
      }
      
      // Always save locally as backup
      await _saveToLocal();
      
      debugPrint('Successfully saved ${_reminders.length} reminders');
    } catch (e) {
      debugPrint('Error saving reminders: $e');
      rethrow;
    }
  }

  Future<void> addReminder(Reminder reminder) async {
    try {
      _reminders.add(reminder);
      notifyListeners();
      
      if (_isCloudEnabled && _cloudService.isAuthenticated) {
        await _cloudService.saveReminder(reminder);
      }
      
      await _saveToLocal(); // Save locally as backup
      _scheduleNextReminder();
      debugPrint('Reminder added: ${reminder.id}');
    } catch (e) {
      debugPrint('Error adding reminder: $e');
      // Remove the reminder if save failed
      _reminders.removeWhere((r) => r.id == reminder.id);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateReminder(Reminder reminder) async {
    try {
      final index = _reminders.indexWhere((r) => r.id == reminder.id);
      if (index != -1) {
        _reminders[index] = reminder;
        notifyListeners();
        
        if (_isCloudEnabled && _cloudService.isAuthenticated) {
          await _cloudService.saveReminder(reminder);
        }
        
        await _saveToLocal(); // Save locally as backup
        _scheduleNextReminder();
        debugPrint('Reminder updated: ${reminder.id}');
      } else {
        debugPrint('Reminder not found for update: ${reminder.id}');
      }
    } catch (e) {
      debugPrint('Error updating reminder: $e');
      rethrow;
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    try {
      _reminders.removeWhere((reminder) => reminder.id == reminderId);
      notifyListeners();
      
      if (_isCloudEnabled && _cloudService.isAuthenticated) {
        await _cloudService.deleteReminder(reminderId);
      }
      
      await _saveToLocal(); // Update local storage
      _scheduleNextReminder();
      debugPrint('Reminder deleted: $reminderId');
    } catch (e) {
      debugPrint('Error deleting reminder: $e');
      rethrow;
    }
  }

  Future<void> syncWithCloud() async {
    if (!_cloudService.isAuthenticated) {
      debugPrint('Cannot sync: User not authenticated');
      return;
    }

    try {
      _isSyncing = true;
      notifyListeners();

      final localReminders = List<Reminder>.from(_reminders);
      await _cloudService.syncReminders(localReminders);
      
      // Reload reminders to get the latest from cloud
      await loadReminders();
      
      debugPrint('Reminder sync completed successfully');
    } catch (e) {
      debugPrint('Error syncing reminders with cloud: $e');
    } finally {
      _isSyncing = false;
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
