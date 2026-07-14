import 'package:flutter/material.dart';
import '../../core/models/book.dart';
import '../../core/services/database_service.dart';

class LibraryProvider extends ChangeNotifier {
  final DatabaseService _db;
  List<Book> _books = [];
  bool _loading = true;
  String? _error;
  final Set<int> _selectedIds = {};
  bool _selectionMode = false;

  LibraryProvider(this._db);

  List<Book> get books => _books;
  bool get loading => _loading;
  String? get error => _error;
  Set<int> get selectedIds => _selectedIds;
  bool get selectionMode => _selectionMode;

  Future<void> loadBooks() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _books = await _db.getBooks();
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<int> addBook(Book book) async {
    final id = await _db.insertBook(book);
    await loadBooks();
    return id;
  }

  Future<void> deleteBook(int id) async {
    await _db.deleteBook(id);
    _selectedIds.remove(id);
    await loadBooks();
  }

  void toggleSelection(int id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
      if (_selectedIds.isEmpty) _selectionMode = false;
    } else {
      _selectedIds.add(id);
      _selectionMode = true;
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    _selectionMode = false;
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    for (final id in _selectedIds.toList()) {
      await _db.deleteBook(id);
    }
    _selectedIds.clear();
    _selectionMode = false;
    await loadBooks();
  }
}
