import 'package:flutter/material.dart';
import '../../core/models/snippet.dart';
import '../../core/services/database_service.dart';
import '../../core/services/stats_service.dart';

class SnippetsProvider extends ChangeNotifier {
  final DatabaseService _db;
  final StatsService _statsService;

  List<Snippet> _snippets = [];
  List<String> _allTags = [];
  String? _filterTag;
  bool _loading = true;
  String? _error;

  SnippetsProvider(this._db, this._statsService);

  List<Snippet> get snippets {
    if (_filterTag == null) return _snippets;
    return _snippets.where((s) => s.tags.contains(_filterTag)).toList();
  }

  List<String> get allTags => _allTags;
  String? get filterTag => _filterTag;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadSnippets() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _snippets = await _db.getSnippets();
      _allTags = await _db.getAllTags();
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  void setFilterTag(String? tag) {
    _filterTag = tag;
    notifyListeners();
  }

  Future<int> createSnippet({
    required String text,
    String? note,
    String? sourceTitle,
    String? sourceUrl,
    String? color,
    int? bookId,
    int? chapterId,
    List<String> tags = const [],
  }) async {
    final id = await _db.createSnippet(
      text: text,
      note: note,
      sourceTitle: sourceTitle,
      sourceUrl: sourceUrl,
      color: color,
      bookId: bookId,
      chapterId: chapterId,
      tags: tags,
    );
    await _statsService.trackSnippet();
    await loadSnippets();
    return id;
  }

  Future<void> updateSnippet(Snippet snippet) async {
    await _db.updateSnippet(snippet);
    await loadSnippets();
  }

  Future<void> deleteSnippet(int id) async {
    await _db.deleteSnippet(id);
    await loadSnippets();
  }
}
