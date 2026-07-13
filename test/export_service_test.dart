import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:stashreader/core/database/database.dart';
import 'package:stashreader/core/models/book.dart';
import 'package:stashreader/core/models/snippet.dart';

import 'helpers/test_database.dart';

/// Tests JSON round-trip: export data → import data → verify integrity.
/// ExportService wraps DatabaseService.exportToJson/importFromJson + FilePicker.
/// We test the DB-level export/import logic directly.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = await createTestDb();
  });

  tearDown(() async {
    await db.close();
  });

  group('Model JSON round-trip', () {
    test('Book toJson/fromJson preserves fields', () {
      final book = Book(
        id: 1,
        title: 'Test Title',
        author: 'Test Author',
        coverPath: '/path/to/cover',
        source: 'local',
        sourceUrl: 'https://example.com',
        filePath: '/path/to/file.epub',
        progress: 0.42,
        currentChapterIndex: 3,
        totalChapters: 10,
      );

      final json = book.toJson();
      final restored = Book.fromJson(json);

      expect(restored.id, book.id);
      expect(restored.title, book.title);
      expect(restored.author, book.author);
      expect(restored.coverPath, book.coverPath);
      expect(restored.source, book.source);
      expect(restored.sourceUrl, book.sourceUrl);
      expect(restored.filePath, book.filePath);
      expect(restored.progress, book.progress);
      expect(restored.currentChapterIndex, book.currentChapterIndex);
      expect(restored.totalChapters, book.totalChapters);
    });

    test('Snippet toJson/fromJson preserves fields and tags', () {
      final snippet = Snippet(
        id: 1,
        text: 'Important quote',
        note: 'My thoughts',
        sourceTitle: 'Source Book',
        sourceUrl: 'https://example.com',
        color: '#FF5733',
        bookId: 5,
        chapterId: 10,
        tags: ['flutter', 'dart'],
      );

      final json = snippet.toJson();
      final restored = Snippet.fromJson(json);

      expect(restored.id, snippet.id);
      expect(restored.text, snippet.text);
      expect(restored.note, snippet.note);
      expect(restored.sourceTitle, snippet.sourceTitle);
      expect(restored.sourceUrl, snippet.sourceUrl);
      expect(restored.color, snippet.color);
      expect(restored.bookId, snippet.bookId);
      expect(restored.chapterId, snippet.chapterId);
      expect(restored.tags, ['flutter', 'dart']);
    });

    test('Snippet with null optional fields round-trips', () {
      final snippet = Snippet(
        id: 2,
        text: 'Minimal snippet',
      );

      final json = snippet.toJson();
      final restored = Snippet.fromJson(json);

      expect(restored.note, isNull);
      expect(restored.sourceTitle, isNull);
      expect(restored.sourceUrl, isNull);
      expect(restored.color, isNull);
      expect(restored.bookId, isNull);
      expect(restored.chapterId, isNull);
      expect(restored.tags, isEmpty);
    });
  });

  group('DB-level export/import', () {
    test('export format matches expected structure', () async {
      // Insert test data
      await db.customInsert(
        'INSERT INTO books (title, author, source) VALUES (?, ?, ?)',
        variables: [
          Variable.withString('Exported Book'),
          Variable.withString('Author'),
          Variable.withString('local'),
        ],
      );

      await db.customInsert(
        'INSERT INTO snippets (content, note, created_at, updated_at) VALUES (?, ?, ?, ?)',
        variables: [
          Variable.withString('Exported snippet'),
          Variable.withString('A note'),
          Variable.withDateTime(DateTime.now()),
          Variable.withDateTime(DateTime.now()),
        ],
      );

      // Simulate export (same logic as DatabaseService.exportToJson)
      final bookRows =
          await db.customSelect('SELECT * FROM books ORDER BY updated_at DESC').get();
      final snippetRows =
          await db.customSelect('SELECT * FROM snippets ORDER BY created_at DESC').get();

      final export = {
        'version': 1,
        'exported_at': DateTime.now().toIso8601String(),
        'books': bookRows.map((r) {
          return Book(
            id: r.data['id'] as int,
            title: r.data['title'] as String,
            author: r.data['author'] as String?,
            source: r.data['source'] as String? ?? 'local',
          ).toJson();
        }).toList(),
        'snippets': snippetRows.map((r) {
          return Snippet(
            id: r.data['id'] as int,
            text: r.data['content'] as String,
            note: r.data['note'] as String?,
          ).toJson();
        }).toList(),
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(export);
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(parsed['version'], 1);
      expect(parsed['exported_at'], isNotNull);
      expect(parsed['books'], isA<List>());
      expect(parsed['books'].length, 1);
      expect(parsed['snippets'], isA<List>());
      expect(parsed['snippets'].length, 1);
      expect(parsed['books'][0]['title'], 'Exported Book');
      expect(parsed['snippets'][0]['text'], 'Exported snippet');
    });

    test('import data integrity round-trip', () async {
      // Create export JSON
      final exportData = {
        'version': 1,
        'exported_at': DateTime.now().toIso8601String(),
        'books': [
          Book(
            id: 1,
            title: 'Imported Book',
            author: 'Import Author',
            source: 'local',
            progress: 0.25,
            totalChapters: 8,
          ).toJson(),
        ],
        'snippets': [
          Snippet(
            id: 1,
            text: 'Imported snippet text',
            note: 'Import note',
            tags: ['import', 'test'],
          ).toJson(),
        ],
      };

      final jsonStr = jsonEncode(exportData);

      // Simulate import (same logic as DatabaseService.importFromJson)
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final books = data['books'] as List? ?? [];
      final snippets = data['snippets'] as List? ?? [];

      for (final b in books) {
        final book = Book.fromJson(b as Map<String, dynamic>);
        await db.customInsert(
          'INSERT INTO books (title, author, source, progress, total_chapters) '
          'VALUES (?, ?, ?, ?, ?)',
          variables: [
            Variable.withString(book.title),
            Variable.withString(book.author ?? ''),
            Variable.withString(book.source),
            Variable.withReal(book.progress),
            Variable.withInt(book.totalChapters),
          ],
        );
      }

      for (final s in snippets) {
        final snippet = Snippet.fromJson(s as Map<String, dynamic>);
        await db.customInsert(
          'INSERT INTO snippets (content, note, created_at, updated_at) VALUES (?, ?, ?, ?)',
          variables: [
            Variable.withString(snippet.text),
            Variable.withString(snippet.note ?? ''),
            Variable.withDateTime(DateTime.now()),
            Variable.withDateTime(DateTime.now()),
          ],
        );
      }

      // Verify data was imported correctly
      final importedBooks =
          await db.customSelect('SELECT * FROM books').get();
      expect(importedBooks.length, 1);
      expect(importedBooks.first.data['title'], 'Imported Book');
      expect(importedBooks.first.data['author'], 'Import Author');
      expect((importedBooks.first.data['progress'] as num).toDouble(), 0.25);
      expect(importedBooks.first.data['total_chapters'], 8);

      final importedSnippets =
          await db.customSelect('SELECT * FROM snippets').get();
      expect(importedSnippets.length, 1);
      expect(importedSnippets.first.data['content'], 'Imported snippet text');
      expect(importedSnippets.first.data['note'], 'Import note');
    });

    test('import skips duplicate books by title+author', () async {
      // Insert a book
      await db.customInsert(
        'INSERT INTO books (title, author, source) VALUES (?, ?, ?)',
        variables: [
          Variable.withString('Existing Book'),
          Variable.withString('Author'),
          Variable.withString('local'),
        ],
      );

      // Try to import the same book
      final importData = {
        'books': [
          Book(
            id: 1,
            title: 'Existing Book',
            author: 'Author',
            source: 'local',
          ).toJson(),
        ],
        'snippets': [],
      };

      final data = importData;
      final List books = data['books'] ?? [];

      for (final b in books) {
        final book = Book.fromJson(b as Map<String, dynamic>);
        final existing = await db
            .customSelect(
                'SELECT id FROM books WHERE title = ? AND author = ?',
                variables: [
              Variable.withString(book.title),
              Variable.withString(book.author ?? ''),
            ])
            .get();
        if (existing.isEmpty) {
          await db.customInsert(
            'INSERT INTO books (title, author, source) VALUES (?, ?, ?)',
            variables: [
              Variable.withString(book.title),
              Variable.withString(book.author ?? ''),
              Variable.withString(book.source),
            ],
          );
        }
      }

      final allBooks = await db.customSelect('SELECT * FROM books').get();
      expect(allBooks.length, 1); // No duplicate created
    });

    test('empty export contains version and empty arrays', () {
      final export = {
        'version': 1,
        'exported_at': DateTime.now().toIso8601String(),
        'books': <Map<String, dynamic>>[],
        'snippets': <Map<String, dynamic>>[],
      };

      final jsonStr = jsonEncode(export);
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(parsed['version'], 1);
      expect(parsed['books'], isEmpty);
      expect(parsed['snippets'], isEmpty);
    });
  });
}
