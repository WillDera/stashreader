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
    return Consumer<LibraryProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom header — no AppBar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: provider.selectionMode
                            ? Text(
                                '${provider.selectedIds.length} selected',
                                style: Theme.of(context).textTheme.titleLarge,
                              )
                            : Text(
                                'Library',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                      ),
                      if (provider.selectionMode) ...[
                        _iconButton(
                          icon: Icons.close,
                          onTap: () => provider.clearSelection(),
                        ),
                        const SizedBox(width: 4),
                        _iconButton(
                          icon: Icons.delete,
                          onTap: () => _confirmDelete(context, provider),
                        ),
                      ] else ...[
                        _iconButton(
                          icon: provider.isGridView ? Icons.view_list : Icons.grid_view,
                          onTap: () => provider.toggleLayout(),
                        ),
                        const SizedBox(width: 4),
                        _iconButton(
                          icon: Icons.add,
                          onTap: () => _showImportOptions(context),
                        ),
                      ],
                    ],
                  ),
                ),
                // Content
                Expanded(child: _buildBody(context, provider)),
              ],
            ),
          ),
          floatingActionButton: provider.selectionMode ? null : _buildFAB(context),
        );
      },
    );
  }

  Widget _iconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 22),
      ),
    );
  }

  void _confirmDelete(BuildContext context, LibraryProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove books?'),
        content: Text(
            'Delete ${provider.selectedIds.length} book(s) and all their chapters?'),
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
      await provider.deleteSelected();
    }
  }

  Widget _buildBody(BuildContext context, LibraryProvider provider) {
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
              Icon(Icons.error_outline, size: 48, color: AppTheme.accent.withValues(alpha: 0.6)),
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
    return provider.isGridView
        ? _buildGridView(context, provider)
        : _buildListView(context, provider);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories_rounded,
              size: 56,
              color: AppTheme.accent.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 20),
            Text(
              'Your library is empty',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(
              'Import an EPUB file, add web content, or create a note to get started.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTextSecondary,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 28),
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

  Widget _buildGridView(BuildContext context, LibraryProvider provider) {
    final continueBooks = provider.books.where((b) => b.progress > 0 && b.progress < 1.0).toList();
    return RefreshIndicator(
      onRefresh: () => provider.loadBooks(),
      child: CustomScrollView(
        slivers: [
          if (continueBooks.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildContinueReading(context, continueBooks, provider),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                mainAxisExtent: 340,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final book = provider.books[index];
                  final selected = provider.selectedIds.contains(book.id);
                  return BookCard(
                    book: book,
                    variant: BookCardVariant.grid,
                    selected: selected,
                    selectionMode: provider.selectionMode,
                    onTap: () {
                      if (provider.selectionMode) {
                        provider.toggleSelection(book.id);
                      } else {
                        _openReader(context, book.id);
                      }
                    },
                    onLongPress: () => provider.toggleSelection(book.id),
                  );
                },
                childCount: provider.books.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(BuildContext context, LibraryProvider provider) {
    final continueBooks = provider.books.where((b) => b.progress > 0 && b.progress < 1.0).toList();
    return RefreshIndicator(
      onRefresh: () => provider.loadBooks(),
      child: CustomScrollView(
        slivers: [
          if (continueBooks.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildContinueReading(context, continueBooks, provider),
            ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final book = provider.books[index];
                final selected = provider.selectedIds.contains(book.id);
                return BookCard(
                  book: book,
                  selected: selected,
                  selectionMode: provider.selectionMode,
                  variant: BookCardVariant.list,
                  onTap: () {
                    if (provider.selectionMode) {
                      provider.toggleSelection(book.id);
                    } else {
                      _openReader(context, book.id);
                    }
                  },
                  onLongPress: () {
                    provider.toggleSelection(book.id);
                  },
                );
              },
              childCount: provider.books.length,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }

  Widget _buildContinueReading(BuildContext context, List<Book> books, LibraryProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Text(
            'Continue Reading',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accent,
                ),
          ),
        ),
        SizedBox(
          height: 124,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: books.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final book = books[index];
              return _buildContinueCard(context, book);
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildContinueCard(BuildContext context, Book book) {
    return GestureDetector(
      onTap: () => _openReader(context, book.id),
      child: SizedBox(
        width: 110,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cover — no card wrapper
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 80,
                width: double.infinity,
                child: book.coverPath != null && book.coverPath!.isNotEmpty
                    ? Image.file(
                        File(book.coverPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _continuePlaceholder(book),
                      )
                    : _continuePlaceholder(book),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: book.progress.clamp(0.0, 1.0),
                      minHeight: 3,
                      backgroundColor: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkBorder
                          : AppTheme.lightBorder,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _continuePlaceholder(Book book) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            book.source == 'web' ? Icons.language : Icons.auto_stories,
            color: AppTheme.accent.withValues(alpha: 0.6),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'library_fab',
      onPressed: () => _showImportOptions(context),
      child: const Icon(Icons.add),
    );
  }

  void _showImportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add to Library', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              _importOption(
                icon: Icons.file_present,
                title: 'Import File',
                subtitle: 'EPUB, TXT, or Markdown',
                onTap: () {
                  Navigator.pop(ctx);
                  _importFile(context);
                },
              ),
              _importOption(
                icon: Icons.language,
                title: 'Add URL',
                subtitle: 'Import web content',
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddUrlDialog(context);
                },
              ),
              _importOption(
                icon: Icons.edit_note,
                title: 'Add Note',
                subtitle: 'Create a manual snippet',
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

  Widget _importOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.accent, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
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
      final epubService = EpubService();
      final result = await epubService.parseEpub(filePath);
      if (result == null) throw Exception('Failed to parse EPUB');

      final db = context.read<DatabaseService>();

      final existing = await db.findLocalBook(result.book.title, result.book.author);
      if (existing != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Already in library')),
          );
          _openReader(context, existing.id);
        }
        return;
      }
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
