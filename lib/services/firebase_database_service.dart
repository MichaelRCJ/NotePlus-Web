import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../models/reminder_model.dart';

class FirebaseDatabaseService {
  bool _isFirebaseInitialized = false;

  // Reference to collections (mock for now)
  dynamic get _db => null;
  dynamic get _auth => null;

  // Get current user ID
  String? get currentUserId => _auth?.currentUser?.uid;

  // Save note to Firebase (mock implementation)
  Future<String> saveNote(NoteModel note) async {
    if (!_isFirebaseInitialized) {
      print('Firebase not initialized - using local storage');
      return note.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : note.id;
    }

    try {
      final noteData = {
        'id': note.id.isEmpty ? _generateId() : note.id,
        'userId': currentUserId,
        'title': note.title,
        'content': note.content,
        'createdAt': note.createdAt.toIso8601String(),
        'modifiedAt': note.modifiedAt.toIso8601String(),
        'backgroundColor': note.backgroundColor?.value,
        'isPinned': note.isPinned,
        'reminderAt': note.reminderAt?.toIso8601String(),
        'tags': note.tags,
        'attachments': note.attachments,
      };

      if (note.id.isEmpty) {
        // Create new note
        final docRef = await _db.collection('notes').add(noteData);
        return docRef.id;
      } else {
        // Update existing note
        await _db.collection('notes').doc(note.id).update(noteData);
        return note.id;
      }
    } catch (e) {
      print('Firebase error - using local fallback: $e');
      return note.id.isEmpty ? _generateId() : note.id;
    }
  }

  // Get all notes for current user (mock implementation)
  Future<List<NoteModel>> getNotes() async {
    if (!_isFirebaseInitialized) {
      print('Firebase not initialized - returning empty list');
      return [];
    }

    try {
      final snapshot = await _db
          .collection('notes')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('modifiedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => _docToNote(doc)).toList();
    } catch (e) {
      print('Firebase error - returning empty list: $e');
      return [];
    }
  }

  // Get note by ID
  Future<NoteModel?> getNoteById(String noteId) async {
    if (!_isFirebaseInitialized) return null;
    
    try {
      final doc = await _db.collection('notes').doc(noteId).get();
      if (!doc.exists) return null;
      
      final note = _docToNote(doc);
      return note.userId == currentUserId ? note : null;
    } catch (e) {
      print('Firebase error: $e');
      return null;
    }
  }

  // Delete note
  Future<void> deleteNote(String noteId) async {
    if (!_isFirebaseInitialized) {
      print('Firebase not initialized - skipping delete');
      return;
    }
    
    try {
      await _db.collection('notes').doc(noteId).delete();
    } catch (e) {
      print('Firebase error: $e');
    }
  }

  // Save reminder to Firebase
  Future<String> saveReminder(Reminder reminder) async {
    if (!_isFirebaseInitialized) {
      print('Firebase not initialized - using local storage');
      return reminder.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : reminder.id;
    }

    try {
      final reminderData = {
        'id': reminder.id.isEmpty ? _generateId() : reminder.id,
        'userId': currentUserId,
        'title': reminder.title,
        'description': reminder.description,
        'reminderAt': reminder.reminderAt.toIso8601String(),
        'isCompleted': reminder.isCompleted,
        'isTriggered': reminder.isTriggered,
        'noteId': reminder.noteId,
        'createdAt': DateTime.now().toIso8601String(),
      };

      if (reminder.id.isEmpty) {
        // Create new reminder
        final docRef = await _db.collection('reminders').add(reminderData);
        return docRef.id;
      } else {
        // Update existing reminder
        await _db.collection('reminders').doc(reminder.id).update(reminderData);
        return reminder.id;
      }
    } catch (e) {
      print('Firebase error - using local fallback: $e');
      return reminder.id.isEmpty ? _generateId() : reminder.id;
    }
  }

  // Get all reminders for current user
  Future<List<Reminder>> getReminders() async {
    if (!_isFirebaseInitialized) {
      print('Firebase not initialized - returning empty list');
      return [];
    }

    try {
      final snapshot = await _db
          .collection('reminders')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('reminderAt')
          .get();

      return snapshot.docs.map((doc) => _docToReminder(doc)).toList();
    } catch (e) {
      print('Firebase error - returning empty list: $e');
      return [];
    }
  }

  // Get reminders for specific day
  Future<List<Reminder>> getRemindersForDay(DateTime day) async {
    if (!_isFirebaseInitialized) return [];
    
    try {
      final startOfDay = DateTime(day.year, day.month, day.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _db
          .collection('reminders')
          .where('userId', isEqualTo: currentUserId)
          .where('reminderAt', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('reminderAt', isLessThan: endOfDay.toIso8601String())
          .orderBy('reminderAt')
          .get();

      return snapshot.docs.map((doc) => _docToReminder(doc)).toList();
    } catch (e) {
      print('Firebase error: $e');
      return [];
    }
  }

  // Delete reminder
  Future<void> deleteReminder(String reminderId) async {
    if (!_isFirebaseInitialized) {
      print('Firebase not initialized - skipping delete');
      return;
    }
    
    try {
      await _db.collection('reminders').doc(reminderId).delete();
    } catch (e) {
      print('Firebase error: $e');
    }
  }

  // Toggle reminder completion
  Future<void> toggleReminderCompletion(String reminderId, bool isCompleted) async {
    if (!_isFirebaseInitialized) {
      print('Firebase not initialized - skipping toggle');
      return;
    }
    
    try {
      await _db.collection('reminders').doc(reminderId).update({
        'isCompleted': isCompleted,
        'modifiedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Firebase error: $e');
    }
  }

  // Helper methods
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  NoteModel _docToNote(doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return NoteModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      createdAt: DateTime.parse(data['createdAt']),
      modifiedAt: DateTime.parse(data['modifiedAt']),
      backgroundColor: data['backgroundColor'] != null 
          ? Color(data['backgroundColor']) 
          : null,
      reminderAt: data['reminderAt'] != null 
          ? DateTime.parse(data['reminderAt']) 
          : null,
      tags: List<String>.from(data['tags'] ?? []),
      attachments: List<String>.from(data['attachments'] ?? []),
    );
  }

  Reminder _docToReminder(doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Reminder(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      reminderAt: DateTime.parse(data['reminderAt']),
      isCompleted: data['isCompleted'] ?? false,
      isTriggered: data['isTriggered'] ?? false,
      noteId: data['noteId'] ?? '',
      userId: data['userId'] ?? '',
    );
  }

  // Stream for real-time updates (mock implementation)
  Stream<List<NoteModel>> get notesStream {
    if (!_isFirebaseInitialized) {
      print('Firebase not initialized - returning empty stream');
      return Stream.value([]);
    }
    
    return _db
        .collection('notes')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('modifiedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => _docToNote(doc)).toList());
  }

  Stream<List<Reminder>> get remindersStream {
    if (!_isFirebaseInitialized) {
      print('Firebase not initialized - returning empty stream');
      return Stream.value([]);
    }
    
    return _db
        .collection('reminders')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('reminderAt')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => _docToReminder(doc)).toList());
  }

  // Initialize Firebase (call this when Firebase is ready)
  void initializeFirebase() {
    _isFirebaseInitialized = true;
    print('Firebase service initialized');
  }
}
