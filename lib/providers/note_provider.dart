import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/firebase_database_service.dart';
import '../models/note_model.dart';

class NoteProvider with ChangeNotifier {
  List<NoteModel> _notes = [];
  List<NoteModel> _deletedNotes = []; // Papelera de reciclaje
  String _searchQuery = '';
  String _selectedCategory = '';
  String _sortBy = 'modifiedAt'; // 'title', 'createdAt', 'modifiedAt'
  bool _sortAscending = false;
  bool _showPinnedOnly = false;
  bool _showWithRemindersOnly = false;
  String? _currentUserId;
  final FirebaseDatabaseService _firebaseService = FirebaseDatabaseService();

  void setCurrentUserId(String userId) {
    _currentUserId = userId;
    notifyListeners();
  }

  List<NoteModel> get notes {
    if (_currentUserId == null) return [];
    
    var filteredNotes = _notes.where((note) {
      if (note.userId != _currentUserId) return false;
      
      // Filtro por búsqueda avanzada
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesSearch = note.title.toLowerCase().contains(query) ||
            note.content.toLowerCase().contains(query) ||
            note.tags.any((tag) => tag.toLowerCase().contains(query)) ||
            note.tasks.any((task) => task.title.toLowerCase().contains(query)) ||
            note.category.toLowerCase().contains(query);
        
        if (!matchesSearch) return false;
      }
      
      // Filtro por categoría
      if (_selectedCategory.isNotEmpty && note.category != _selectedCategory) {
        return false;
      }
      
      // Filtro por notas fijadas
      if (_showPinnedOnly && !note.isPinned) return false;
      
      // Filtro por recordatorios
      if (_showWithRemindersOnly && note.reminderAt == null) return false;
      
      return true;
    }).toList();

    // Ordenamiento avanzado
    switch (_sortBy) {
      case 'title':
        filteredNotes.sort((a, b) => _sortAscending 
            ? a.title.compareTo(b.title)
            : b.title.compareTo(a.title));
        break;
      case 'createdAt':
        filteredNotes.sort((a, b) => _sortAscending 
            ? a.createdAt.compareTo(b.createdAt)
            : b.createdAt.compareTo(a.createdAt));
        break;
      case 'modifiedAt':
      default:
        filteredNotes.sort((a, b) {
          // Prioridad: notas fijadas primero
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          
          // Luego por fecha de modificación
          return _sortAscending 
              ? a.modifiedAt.compareTo(b.modifiedAt)
              : b.modifiedAt.compareTo(a.modifiedAt);
        });
        break;
    }

    return filteredNotes;
  }

  // Getters para filtros
  List<NoteModel> get deletedNotes => _deletedNotes.where((note) => note.userId == _currentUserId).toList();
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;
  bool get showPinnedOnly => _showPinnedOnly;
  bool get showWithRemindersOnly => _showWithRemindersOnly;

  List<String> get categories {
    if (_currentUserId == null) return [];
    return _notes
        .where((note) => note.userId == _currentUserId && note.category.isNotEmpty)
        .map((note) => note.category)
        .toSet()
        .toList();
  }

  // Métodos para filtros avanzados
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  void toggleSortOrder() {
    _sortAscending = !_sortAscending;
    notifyListeners();
  }

  void togglePinnedFilter() {
    _showPinnedOnly = !_showPinnedOnly;
    notifyListeners();
  }

  void toggleReminderFilter() {
    _showWithRemindersOnly = !_showWithRemindersOnly;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = '';
    _sortBy = 'modifiedAt';
    _sortAscending = false;
    _showPinnedOnly = false;
    _showWithRemindersOnly = false;
    notifyListeners();
  }

  Future<void> loadNotes() async {
    try {
      if (_currentUserId == null) {
        _notes = [];
        _deletedNotes = [];
        notifyListeners();
        return;
      }
      
      // Try to load from Firebase first
      _notes = await _firebaseService.getNotes();
      
      // If Firebase returns empty, try local storage
      if (_notes.isEmpty) {
        await _loadNotesFromLocal();
      } else {
        // Save Firebase data to local for backup
        await _saveNotesToLocal();
      }
      
      // Load deleted notes from local storage
      await _loadDeletedNotesFromLocal();
      
      debugPrint('Loaded ${_notes.length} notes and ${_deletedNotes.length} deleted notes');
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Error loading notes: $e');
      // Fallback to local storage
      await _loadNotesFromLocal();
      await _loadDeletedNotesFromLocal();
      notifyListeners();
    }
  }

  Future<void> _loadNotesFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString('notes_$_currentUserId') ?? '[]';
      final notesList = json.decode(notesJson) as List;
      
      _notes = notesList.map((note) => NoteModel.fromJson(note)).toList();
      debugPrint('Loaded ${_notes.length} notes from local storage');
    } catch (e) {
      debugPrint('Error loading notes from local: $e');
      _notes = [];
    }
  }

  Future<void> _saveNotesToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = json.encode(_notes.map((note) => note.toJson()).toList());
      await prefs.setString('notes_$_currentUserId', notesJson);
      debugPrint('Saved ${_notes.length} notes to local storage');
    } catch (e) {
      debugPrint('Error saving notes to local: $e');
    }
  }

  Future<void> addNote(NoteModel note) async {
    try {
      final savedNoteId = await _firebaseService.saveNote(note);
      final savedNote = note.copyWith(id: savedNoteId);
      _notes.add(savedNote);
      await _saveNotesToLocal(); // Also save locally
      notifyListeners();
      debugPrint('Note added: ${savedNote.id}');
    } catch (e) {
      debugPrint('Error adding note: $e');
      // Save locally even if Firebase fails
      final localNote = note.copyWith(id: note.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : note.id);
      _notes.add(localNote);
      await _saveNotesToLocal();
      notifyListeners();
    }
  }

  Future<void> updateNote(NoteModel note) async {
    try {
      await _firebaseService.saveNote(note);
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = note;
      } else {
        _notes.add(note);
      }
      await _saveNotesToLocal(); // Also save locally
      notifyListeners();
      debugPrint('Note updated: ${note.id}');
    } catch (e) {
      debugPrint('Error updating note: $e');
      // Update locally even if Firebase fails
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = note;
      } else {
        _notes.add(note);
      }
      await _saveNotesToLocal();
      notifyListeners();
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      await _firebaseService.deleteNote(noteId);
      _notes.removeWhere((note) => note.id == noteId);
      await _saveNotesToLocal(); // Also save locally
      notifyListeners();
      debugPrint('Note deleted: $noteId');
    } catch (e) {
      debugPrint('Error deleting note: $e');
      // Delete locally even if Firebase fails
      _notes.removeWhere((note) => note.id == noteId);
      await _saveNotesToLocal();
      notifyListeners();
    }
  }

  // Métodos para papelera de reciclaje
  Future<void> moveToTrash(NoteModel note) async {
    try {
      // Mover a papelera
      _deletedNotes.add(note.copyWith(modifiedAt: DateTime.now()));
      _notes.removeWhere((n) => n.id == note.id);
      
      // Guardar cambios
      await _saveNotesToLocal();
      await _saveDeletedNotesToLocal();
      
      notifyListeners();
      debugPrint('Note moved to trash: ${note.id}');
    } catch (e) {
      debugPrint('Error moving note to trash: $e');
    }
  }

  Future<void> restoreFromTrash(NoteModel note) async {
    try {
      // Restaurar de papelera
      _deletedNotes.removeWhere((n) => n.id == note.id);
      _notes.add(note.copyWith(modifiedAt: DateTime.now()));
      
      // Guardar cambios
      await _saveNotesToLocal();
      await _saveDeletedNotesToLocal();
      
      notifyListeners();
      debugPrint('Note restored from trash: ${note.id}');
    } catch (e) {
      debugPrint('Error restoring note from trash: $e');
    }
  }

  Future<void> permanentlyDelete(String noteId) async {
    try {
      _deletedNotes.removeWhere((note) => note.id == noteId);
      await _saveDeletedNotesToLocal();
      notifyListeners();
      debugPrint('Note permanently deleted: $noteId');
    } catch (e) {
      debugPrint('Error permanently deleting note: $e');
    }
  }

  Future<void> emptyTrash() async {
    try {
      _deletedNotes.clear();
      await _saveDeletedNotesToLocal();
      notifyListeners();
      debugPrint('Trash emptied');
    } catch (e) {
      debugPrint('Error emptying trash: $e');
    }
  }

  Future<void> _saveDeletedNotesToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deletedNotesJson = json.encode(_deletedNotes.map((note) => note.toJson()).toList());
      await prefs.setString('deleted_notes_$_currentUserId', deletedNotesJson);
    } catch (e) {
      debugPrint('Error saving deleted notes to local: $e');
    }
  }

  Future<void> _loadDeletedNotesFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deletedNotesJson = prefs.getString('deleted_notes_$_currentUserId') ?? '[]';
      final deletedNotesList = json.decode(deletedNotesJson) as List;
      
      _deletedNotes = deletedNotesList.map((note) => NoteModel.fromJson(note)).toList();
    } catch (e) {
      debugPrint('Error loading deleted notes from local: $e');
      _deletedNotes = [];
    }
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

