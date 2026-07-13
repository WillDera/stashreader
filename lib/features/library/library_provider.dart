import 'package:flutter/material.dart';
import '../../core/models/book.dart';
import '../../core/services/database_service.dart';

class LibraryProvider extends ChangeNotifier {
  final DatabaseService _db;
  List<Book> _books = [];
  bool _loading = true;
  String? _error;

  LibraryProvider(this._db);

  List<Book> get books => _books;
  bool get loading => _loading;
  String? get error => _error;

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
    await loadBooks();
  }
}
