import 'package:drift/drift.dart';
import '../database/database.dart';
import '../models/book.dart';
import '../models/chapter.dart';
import '../models/snippet.dart';

class SearchResult {
  final String type; // 'book', 'chapter', 'snippet'
  final dynamic item;
  final String matchPreview;

  SearchResult({
    required this.type,
    required this.item,
    required this.matchPreview,
  });
}

class SearchService {
  final AppDatabase _db;

  SearchService(this._db);

  Future<List<SearchResult>> searchAll(String query) async {
    if (query.trim().isEmpty) return [];
    final results = <SearchResult>[];
    final pattern = '%${query.trim()}%';

    results.addAll(await _searchBooks(pattern));
    results.addAll(await _searchChapters(pattern));
    results.addAll(await _searchSnippets(pattern));

    return results;
  }

  Future<List<Book>> searchBooks(String query) async {
    if (query.trim().isEmpty) return [];
    final pattern = '%${query.trim()}%';
    return _searchBooks(pattern).then(
      (results) => results.map((r) => r.item as Book).toList(),
    );
  }

  Future<List<Chapter>> searchChapters(String query) async {
    if (query.trim().isEmpty) return [];
    final pattern = '%${query.trim()}%';
    return _searchChapters(pattern).then(
      (results) => results.map((r) => r.item as Chapter).toList(),
    );
  }

  Future<List<Snippet>> searchSnippets(String query) async {
    if (query.trim().isEmpty) return [];
    final pattern = '%${query.trim()}%';
    return _searchSnippets(pattern).then(
      (results) => results.map((r) => r.item as Snippet).toList(),
    );
  }

  Future<List<SearchResult>> _searchBooks(String pattern) async {
    final rows = await _db.customSelect(
      'SELECT * FROM books WHERE title LIKE ? OR author LIKE ?',
      variables: [Variable.withString(pattern), Variable.withString(pattern)],
    ).get();
    return rows.map((r) {
      final book = _bookFromRow(r.data);
      return SearchResult(
        type: 'book',
        item: book,
        matchPreview: book.title,
      );
    }).toList();
  }

  Future<List<SearchResult>> _searchChapters(String pattern) async {
    final rows = await _db.customSelect(
      'SELECT c.*, b.title as book_title FROM chapters c '
      'INNER JOIN books b ON b.id = c.book_id '
      'WHERE c.title LIKE ? OR c.content LIKE ? '
      'ORDER BY c."index" ASC',
      variables: [Variable.withString(pattern), Variable.withString(pattern)],
    ).get();
    return rows.map((r) {
      final chapter = _chapterFromRow(r.data);
      final content = (r.data['content'] as String?) ?? '';
      final preview = content.length > 150 ? '${content.substring(0, 150)}...' : content;
      return SearchResult(
        type: 'chapter',
        item: chapter,
        matchPreview: preview.replaceAll(RegExp(r'<[^>]*>'), ' '),
      );
    }).toList();
  }

  Future<List<SearchResult>> _searchSnippets(String pattern) async {
    final rows = await _db.customSelect(
      'SELECT * FROM snippets WHERE content LIKE ? OR note LIKE ? OR source_title LIKE ? '
      'ORDER BY created_at DESC',
      variables: [
        Variable.withString(pattern),
        Variable.withString(pattern),
        Variable.withString(pattern),
      ],
    ).get();
    if (rows.isEmpty) return [];
    final ids = rows.map((r) => r.data['id'] as int).toList();
    final tagMap = await _batchGetTags(ids);
    final results = <SearchResult>[];
    for (final r in rows) {
      final snippet = _snippetFromRow(r.data, tagMap[r.data['id'] as int] ?? []);
      final preview =
          snippet.text.length > 150 ? '${snippet.text.substring(0, 150)}...' : snippet.text;
      results.add(SearchResult(
        type: 'snippet',
        item: snippet,
        matchPreview: preview.replaceAll(RegExp(r'<[^>]*>'), ' '),
      ));
    }
    return results;
  }

  Book _bookFromRow(Map<String, dynamic> row) {
    return Book(
      id: row['id'] as int,
      title: row['title'] as String,
      author: row['author'] as String?,
      coverPath: row['cover_path'] as String?,
      source: row['source'] as String? ?? 'local',
      sourceUrl: row['source_url'] as String?,
      filePath: row['file_path'] as String?,
      progress: (row['progress'] as num?)?.toDouble() ?? 0.0,
      currentChapterIndex: row['current_chapter_index'] as int? ?? 0,
      totalChapters: row['total_chapters'] as int? ?? 0,
    );
  }

  Chapter _chapterFromRow(Map<String, dynamic> row) {
    final readAtRaw = row['read_at'];
    final readAt = readAtRaw is String ? DateTime.tryParse(readAtRaw) : readAtRaw as DateTime?;
    return Chapter(
      id: row['id'] as int,
      bookId: row['book_id'] as int,
      title: row['title'] as String,
      content: row['content'] as String,
      index: row['index'] as int,
      readAt: readAt,
    );
  }

  Snippet _snippetFromRow(Map<String, dynamic> row, [List<String>? preloadedTags]) {
    final sid = row['id'] as int;
    return Snippet(
      id: sid,
      text: row['content'] as String,
      note: row['note'] as String?,
      sourceTitle: row['source_title'] as String?,
      sourceUrl: row['source_url'] as String?,
      color: row['color'] as String?,
      bookId: row['book_id'] as int?,
      chapterId: row['chapter_id'] as int?,
      tags: preloadedTags ?? [],
    );
  }

  Future<Map<int, List<String>>> _batchGetTags(List<int> snippetIds) async {
    if (snippetIds.isEmpty) return {};
    final placeholders = snippetIds.map((_) => '?').join(',');
    final rows = await _db.customSelect(
      'SELECT st.snippet_id, t.name FROM tags t '
      'INNER JOIN snippet_tags st ON st.tag_id = t.id '
      'WHERE st.snippet_id IN ($placeholders) ORDER BY t.name',
      variables: snippetIds.map((id) => Variable.withInt(id)).toList(),
    ).get();
    final map = <int, List<String>>{};
    for (final r in rows) {
      final sid = r.data['snippet_id'] as int;
      map.putIfAbsent(sid, () => []).add(r.data['name'] as String);
    }
    return map;
  }
}
