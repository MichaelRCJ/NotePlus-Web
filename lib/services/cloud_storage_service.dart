import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/note_model.dart';
import '../models/reminder_model.dart';

class CloudStorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _notesCollection => 
      _firestore.collection('users').doc(_auth.currentUser?.uid).collection('notes');
  
  CollectionReference get _remindersCollection => 
      _firestore.collection('users').doc(_auth.currentUser?.uid).collection('reminders');

  // Notes operations
  Future<List<NoteModel>> loadNotes() async {
    try {
      if (_auth.currentUser == null) return [];
      
      final snapshot = await _notesCollection.get();
      final notes = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is set
        return NoteModel.fromJson(data);
      }).toList();
      
      return notes;
    } catch (e) {
      print('Error loading notes from cloud: $e');
      return [];
    }
  }

  Future<void> saveNote(NoteModel note) async {
    try {
      if (_auth.currentUser == null) throw Exception('User not authenticated');
      
      final noteData = note.toJson();
      noteData['modifiedAt'] = Timestamp.fromDate(note.modifiedAt);
      noteData['createdAt'] = Timestamp.fromDate(note.createdAt);
      if (note.reminderAt != null) {
        noteData['reminderAt'] = Timestamp.fromDate(note.reminderAt!);
      }
      
      if (note.id.isEmpty) {
        // Create new note
        final docRef = await _notesCollection.add(noteData);
        noteData['id'] = docRef.id;
      } else {
        // Update existing note
        await _notesCollection.doc(note.id).set(noteData, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error saving note to cloud: $e');
      rethrow;
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      if (_auth.currentUser == null) throw Exception('User not authenticated');
      await _notesCollection.doc(noteId).delete();
    } catch (e) {
      print('Error deleting note from cloud: $e');
      rethrow;
    }
  }

  // Reminders operations
  Future<List<Reminder>> loadReminders() async {
    try {
      if (_auth.currentUser == null) return [];
      
      final snapshot = await _remindersCollection.get();
      final reminders = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is set
        return Reminder.fromJson(data);
      }).toList();
      
      return reminders;
    } catch (e) {
      print('Error loading reminders from cloud: $e');
      return [];
    }
  }

  Future<void> saveReminder(Reminder reminder) async {
    try {
      if (_auth.currentUser == null) throw Exception('User not authenticated');
      
      final reminderData = reminder.toJson();
      reminderData['reminderAt'] = Timestamp.fromDate(reminder.reminderAt);
      
      if (reminder.id.isEmpty) {
        // Create new reminder
        final docRef = await _remindersCollection.add(reminderData);
        reminderData['id'] = docRef.id;
      } else {
        // Update existing reminder
        await _remindersCollection.doc(reminder.id).set(reminderData, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error saving reminder to cloud: $e');
      rethrow;
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    try {
      if (_auth.currentUser == null) throw Exception('User not authenticated');
      await _remindersCollection.doc(reminderId).delete();
    } catch (e) {
      print('Error deleting reminder from cloud: $e');
      rethrow;
    }
  }

  // Sync operations
  Future<void> syncNotes(List<NoteModel> localNotes) async {
    try {
      if (_auth.currentUser == null) return;
      
      final cloudNotes = await loadNotes();
      
      // Upload local notes that don't exist in cloud
      for (final localNote in localNotes) {
        final emptyNote = NoteModel(
          id: '',
          userId: _auth.currentUser?.uid,
          title: '',
          content: '',
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );
        final cloudNote = cloudNotes.firstWhere(
          (note) => note.id == localNote.id,
          orElse: () => emptyNote,
        );
        
        if (cloudNote.id.isEmpty || localNote.modifiedAt.isAfter(cloudNote.modifiedAt)) {
          await saveNote(localNote);
        }
      }
      
      // Download cloud notes that are newer
      for (final cloudNote in cloudNotes) {
        final localNote = localNotes.firstWhere(
          (note) => note.id == cloudNote.id,
          orElse: () => NoteModel(
            id: '',
            userId: _auth.currentUser?.uid ?? '',
            title: '',
            content: '',
            createdAt: DateTime.now(),
            modifiedAt: DateTime.now(),
          ),
        );
        
        if (localNote.id.isEmpty || cloudNote.modifiedAt.isAfter(localNote.modifiedAt)) {
          // This note should be returned to the caller
        }
      }
    } catch (e) {
      print('Error syncing notes: $e');
    }
  }

  Future<void> syncReminders(List<Reminder> localReminders) async {
    try {
      if (_auth.currentUser == null) return;
      
      final cloudReminders = await loadReminders();
      
      // Upload local reminders that don't exist in cloud
      for (final localReminder in localReminders) {
        final cloudReminder = cloudReminders.firstWhere(
          (reminder) => reminder.id == localReminder.id,
          orElse: () => Reminder(
            id: '',
            title: '',
            description: '',
            reminderAt: DateTime.now(),
            noteId: '',
            userId: _auth.currentUser?.uid ?? '',
          ),
        );
        
        if (cloudReminder.id.isEmpty) {
          await saveReminder(localReminder);
        }
      }
    } catch (e) {
      print('Error syncing reminders: $e');
    }
  }

  // Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
}
