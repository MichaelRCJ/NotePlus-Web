import 'package:flutter/foundation.dart';
import 'note.dart';

class NoteProvider extends ChangeNotifier {
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  String _searchQuery = '';
  String _selectedTag = '';

  List<Note> get notes => _filteredNotes.isEmpty ? _notes : _filteredNotes;
  String get searchQuery => _searchQuery;
  String get selectedTag => _selectedTag;

  NoteProvider() {
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    // In a real app, this would load from a database or API
    // For now, we'll start with empty notes
    _notes = [];
    notifyListeners();
  }

  void addNote(Note note) {
    _notes.insert(0, note);
    _applyFilters();
    notifyListeners();
  }

  void updateNote(Note note) {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = note;
      _applyFilters();
      notifyListeners();
    }
  }

  void deleteNote(String id) {
    _notes.removeWhere((note) => note.id == id);
    _applyFilters();
    notifyListeners();
  }

  void searchNotes(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void filterByTag(String tag) {
    _selectedTag = tag;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedTag = '';
    _filteredNotes = [];
    notifyListeners();
  }

  void _applyFilters() {
    _filteredNotes = _notes.where((note) {
      final matchesSearch = _searchQuery.isEmpty ||
          note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note.content.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesTag = _selectedTag.isEmpty || note.tags.contains(_selectedTag);
      
      return matchesSearch && matchesTag;
    }).toList();
  }

  List<String> getAllTags() {
    final Set<String> tags = {};
    for (final note in _notes) {
      tags.addAll(note.tags);
    }
    return tags.toList()..sort();
  }
}
