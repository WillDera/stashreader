import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../core/models/book.dart';
import '../../core/models/chapter.dart';
import '../../core/services/database_service.dart';
import '../../core/services/epub_service.dart';
import '../../core/services/web_scraper_service.dart';
import '../../core/services/cache_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/book_card.dart';
import '../reader/reader_screen.dart';
import '../snippets/snippets_provider.dart';
import 'library_provider.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibraryProvider>().loadBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
      ),
      body: Consumer<LibraryProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppTheme.accent),
                    const SizedBox(height: 16),
                    Text('Something went wrong', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(provider.error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => provider.loadBooks(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (provider.books.isEmpty) {
            return _buildEmptyState(context);
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadBooks(),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: provider.books.length,
              itemBuilder: (context, index) {
                final book = provider.books[index];
                return Dismissible(
                  key: ValueKey(book.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Remove book?'),
                        content: Text('Delete "${book.title}" and all its chapters?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      context.read<LibraryProvider>().deleteBook(book.id);
                    }
                    return false; // always return false — we handle removal via provider
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: BookCard(
                    book: book,
                    onTap: () => _openReader(context, book.id),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_rounded, size: 64, color: AppTheme.accent.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'Your library is empty',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Import an EPUB file, add web content, or create a note to get started.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTextSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showImportOptions(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Content'),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.accent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showImportOptions(context),
      child: const Icon(Icons.add),
    );
  }

  void _showImportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add to Library', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.file_present, color: AppTheme.accent),
                title: const Text('Import File'),
                subtitle: const Text('EPUB, TXT, or Markdown'),
                onTap: () {
                  Navigator.pop(ctx);
                  _importFile(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.language, color: AppTheme.accent),
                title: const Text('Add URL'),
                subtitle: const Text('Import web content'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddUrlDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_note, color: AppTheme.accent),
                title: const Text('Add Note'),
                subtitle: const Text('Create a manual snippet'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddNoteDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _importFile(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub', 'txt', 'md', 'html'],
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final filePath = file.path!;
      final ext = p.extension(filePath).toLowerCase();

      if (ext == '.epub') {
        await _importEpub(context, filePath);
      } else {
        // TXT/MD: read content directly
        final provider = context.read<LibraryProvider>();
        final content = await File(filePath).readAsString();
        final title = p.basenameWithoutExtension(filePath);
        final book = Book(
          id: 0,
          title: title,
          source: 'local',
          filePath: filePath,
          totalChapters: 1,
        );
        final bookId = await provider.addBook(book);
        // Create a single chapter from file content
        final db = context.read<DatabaseService>();
        await db.insertChapter(
          Chapter(
            id: 0,
            bookId: bookId,
            title: title,
            content: content,
            index: 0,
          ),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File imported successfully')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  Future<void> _importEpub(BuildContext context, String filePath) async {
    try {
      final db = context.read<DatabaseService>();

      final existing = await db.findBookByPath(filePath);
      if (existing != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Already in library')),
          );
          _openReader(context, existing.id);
        }
        return;
      }

      final epubService = EpubService();
      final result = await epubService.parseEpub(filePath);
      if (result == null) throw Exception('Failed to parse EPUB');

      final provider = context.read<LibraryProvider>();

      final bookId = await provider.addBook(result.book);
      for (final ch in result.chapters) {
        final updatedCh = ch.copyWith(bookId: bookId);
        await db.insertChapter(updatedCh);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${result.book.title}" imported (${result.chapters.length} chapters)')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('EPUB import failed: $e')),
        );
      }
    }
  }

  void _showAddUrlDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://example.com/article',
            labelText: 'URL',
          ),
          keyboardType: TextInputType.url,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _fetchWebContent(context, controller.text.trim());
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accent),
            child: const Text('Fetch'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchWebContent(BuildContext context, String url) async {
    if (url.isEmpty) return;
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fetching content...')),
      );

      final scraper = WebScraperService();
      final result = await scraper.fetchContent(url);
      final db = context.read<DatabaseService>();

      // Check cache first
      final cache = CacheService(db.db);
      final cached = await cache.getCached(url);
      if (cached != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Loaded from cache')),
          );
        }
        final provider = context.read<LibraryProvider>();
        final book = Book(
          id: 0,
          title: cached.title,
          source: 'web',
          sourceUrl: url,
          totalChapters: 1,
        );
        final bookId = await provider.addBook(book);
        await db.insertChapter(cached.copyWith(bookId: bookId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"${cached.title}" added from cache')),
          );
        }
        return;
      }

      final provider = context.read<LibraryProvider>();
      final book = Book(
        id: 0,
        title: result.title,
        author: result.author,
        source: 'web',
        sourceUrl: url,
        totalChapters: 1,
      );
      final bookId = await provider.addBook(book);
      await db.insertChapter(
        Chapter(
          id: 0,
          bookId: bookId,
          title: result.title,
          content: result.contentHtml,
          index: 0,
        ),
      );

      // Cache content
      await cache.cacheContent(url, result.title, result.contentHtml);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${result.title}" added to library')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch content: $e')),
        );
      }
    }
  }

  void _showAddNoteDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _createNote(context, titleController.text.trim(), contentController.text.trim());
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accent),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _createNote(BuildContext context, String title, String content) async {
    if (title.isEmpty || content.isEmpty) return;
    try {
      final snippetsProvider = context.read<SnippetsProvider>();
      await snippetsProvider.createSnippet(
        text: content,
        sourceTitle: title,
        tags: ['note'],
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note created')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create note: $e')),
        );
      }
    }
  }

  void _openReader(BuildContext context, int bookId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderScreen(bookId: bookId),
      ),
    );
  }
}
