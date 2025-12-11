import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/note_model.dart';
import '../services/cloud_storage_service.dart';

class CloudNoteProvider with ChangeNotifier {
  List<NoteModel> _notes = [];
  String _searchQuery = '';
  String _selectedCategory = '';
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

  List<NoteModel> get notes {
    if (_currentUserId == null) return [];
    
    var filteredNotes = _notes.where((note) {
      if (note.userId != _currentUserId) return false;
      
      // Search in title, content, tags, and task titles
      if (_searchQuery.isEmpty) {
        if (_selectedCategory.isEmpty) return true;
        return note.category == _selectedCategory;
      }
      
      final query = _searchQuery.toLowerCase();
      final matchesSearch = note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query) ||
          note.tags.any((tag) => tag.toLowerCase().contains(query)) ||
          note.tasks.any((task) => task.title.toLowerCase().contains(query));
      
      if (!matchesSearch) return false;
      
      if (_selectedCategory.isEmpty) return true;
      return note.category == _selectedCategory;
    }).toList();

    // Sort: pinned first, then by modified date
    filteredNotes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.modifiedAt.compareTo(a.modifiedAt);
    });

    return filteredNotes;
  }

  List<String> get categories {
    if (_currentUserId == null) return [];
    return _notes
        .where((note) => note.userId == _currentUserId && note.category.isNotEmpty)
        .map((note) => note.category)
        .toSet()
        .toList();
  }

  String get selectedCategory => _selectedCategory;

  Future<void> loadNotes() async {
    try {
      _isSyncing = true;
      notifyListeners();

      if (_isCloudEnabled && _cloudService.isAuthenticated) {
        // Load from cloud
        final cloudNotes = await _cloudService.loadNotes();
        _notes = cloudNotes;
        
        // Also sync with local storage for backup
        await _saveToLocal();
      } else {
        // Load from local storage
        await _loadFromLocal();
      }
      
      debugPrint('Loaded ${_notes.length} notes (${_isCloudEnabled ? "cloud" : "local"})');
    } catch (e, stackTrace) {
      debugPrint('Error loading notes: $e');
      debugPrint('Stack trace: $stackTrace');
      // Fallback to local storage
      await _loadFromLocal();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getString('notes') ?? '[]';
    
    if (notesJson.isEmpty || notesJson == '[]') {
      _notes = [];
      return;
    }
    
    final notesList = json.decode(notesJson) as List;
    _notes = notesList.map((noteJson) {
      try {
        return NoteModel.fromJson(noteJson as Map<String, dynamic>);
      } catch (e) {
        debugPrint('Error parsing note: $e');
        return null;
      }
    }).whereType<NoteModel>().toList();
  }

  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final notesJsonList = _notes.map((note) {
        try {
          return note.toJson();
        } catch (e) {
          debugPrint('Error serializing note ${note.id}: $e');
          return null;
        }
      }).whereType<Map<String, dynamic>>().toList();
      
      final notesJson = json.encode(notesJsonList);
      await prefs.setString('notes', notesJson);
    } catch (e) {
      debugPrint('Error saving notes locally: $e');
    }
  }

  Future<void> saveNotes() async {
    try {
      if (_isCloudEnabled && _cloudService.isAuthenticated) {
        // Save to cloud
        for (final note in _notes) {
          await _cloudService.saveNote(note);
        }
      }
      
      // Always save locally as backup
      await _saveToLocal();
      
      debugPrint('Successfully saved ${_notes.length} notes');
    } catch (e, stackTrace) {
      debugPrint('Error saving notes: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> addNote(NoteModel note) async {
    try {
      _notes.add(note);
      notifyListeners(); // Notify immediately for UI update
      
      if (_isCloudEnabled && _cloudService.isAuthenticated) {
        await _cloudService.saveNote(note);
      }
      
      await _saveToLocal(); // Save locally as backup
      debugPrint('Note added: ${note.id}');
    } catch (e) {
      debugPrint('Error adding note: $e');
      // Remove the note if save failed
      _notes.removeWhere((n) => n.id == note.id);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateNote(NoteModel note) async {
    try {
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = note;
        notifyListeners(); // Notify immediately for UI update
        
        if (_isCloudEnabled && _cloudService.isAuthenticated) {
          await _cloudService.saveNote(note);
        }
        
        await _saveToLocal(); // Save locally as backup
        debugPrint('Note updated: ${note.id}');
      } else {
        debugPrint('Note not found for update: ${note.id}');
      }
    } catch (e) {
      debugPrint('Error updating note: $e');
      rethrow;
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      final noteExists = _notes.any((note) => note.id == noteId);
      if (!noteExists) {
        debugPrint('Note not found for deletion: $noteId');
        return;
      }
      
      _notes.removeWhere((note) => note.id == noteId);
      notifyListeners(); // Notify immediately for UI update
      
      if (_isCloudEnabled && _cloudService.isAuthenticated) {
        await _cloudService.deleteNote(noteId);
      }
      
      await _saveToLocal(); // Update local storage
      debugPrint('Note deleted: $noteId');
    } catch (e) {
      debugPrint('Error deleting note: $e');
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

      final localNotes = List<NoteModel>.from(_notes);
      await _cloudService.syncNotes(localNotes);
      
      // Reload notes to get the latest from cloud
      await loadNotes();
      
      debugPrint('Sync completed successfully');
    } catch (e) {
      debugPrint('Error syncing with cloud: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  List<NoteModel> getNotesWithReminders(DateTime day) {
    if (_currentUserId == null) return [];
    
    return _notes.where((note) {
      if (note.userId != _currentUserId) return false;
      if (note.reminderAt == null) return false;
      return note.reminderAt!.year == day.year &&
             note.reminderAt!.month == day.month &&
             note.reminderAt!.day == day.day;
    }).toList();
  }
}
