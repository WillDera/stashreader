import 'package:drift/drift.dart';
import '../database/database.dart';
import '../models/chapter.dart';

class CacheService {
  final AppDatabase _db;

  CacheService(this._db);

  Future<bool> isCached(String url) async {
    final hash = _urlHash(url);
    final rows = await _db.customSelect(
      'SELECT id FROM web_cache WHERE url_hash = ?',
      variables: [Variable.withString(hash)],
    ).get();
    return rows.isNotEmpty;
  }

  Future<Chapter?> getCached(String url) async {
    final hash = _urlHash(url);
    final rows = await _db.customSelect(
      'SELECT * FROM web_cache WHERE url_hash = ?',
      variables: [Variable.withString(hash)],
    ).get();
    if (rows.isEmpty) return null;
    final row = rows.first.data;
    return Chapter(
      id: row['id'] as int,
      bookId: 0,
      title: row['title'] as String,
      content: row['content'] as String,
      index: 0,
    );
  }

  Future<void> cacheContent(String url, String title, String htmlContent) async {
    final hash = _urlHash(url);
    await _db.customInsert(
      'INSERT OR REPLACE INTO web_cache (url_hash, url, title, content) VALUES (?, ?, ?, ?)',
      variables: [
        Variable.withString(hash),
        Variable.withString(url),
        Variable.withString(title),
        Variable.withString(htmlContent),
      ],
    );
  }

  Future<void> clearCache() async {
    await _db.customUpdate('DELETE FROM web_cache');
  }

  // ponytail: url.hashCode is 32-bit, collision probability negligible for personal use
  String _urlHash(String url) {
    return 'cache:${url.hashCode}';
  }
}
