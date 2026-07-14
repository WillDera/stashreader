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
import '../../theme/theme_provider.dart';
import '../../widgets/continue_reading_shelf.dart';
import '../../widgets/dialog_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/icon_button_round.dart';
import '../../widgets/import_sheet.dart';
import '../../widgets/library_book_card.dart';
import '../../widgets/library_header.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/reading_streak_card.dart';
import '../../widgets/toast.dart';
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
    final leftHanded =
        context.watch<ThemeProvider>().handMode == HandMode.left;
    return Consumer<LibraryProvider>(
      builder: (context, provider, _) {
        return Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, provider),
                  Expanded(child: _buildBody(context, provider)),
                ],
              ),
            ),
            if (!provider.loading && !provider.selectionMode && provider.books.isNotEmpty)
              Positioned(
                left: leftHanded ? 20 : null,
                right: leftHanded ? null : 20,
                bottom: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Grid / List toggle icon
                    IconButtonRound(
                      icon: provider.isGridView
                          ? Icons.list
                          : Icons.grid_view_rounded,
                      size: 44,
                      variant: IconButtonVariant.filled,
                      backgroundColor: context.colors.surfaceMuted,
                      iconColor: context.colors.textPrimary,
                      onPressed: provider.toggleLayout,
                    ),
                    const SizedBox(height: 10),
                    // Add / Import FAB
                    IconButtonRound(
                      icon: Icons.add,
                      size: 52,
                      variant: IconButtonVariant.filled,
                      backgroundColor: context.colors.accent,
                      iconColor: context.colors.onAccent,
                      onPressed: () => _showImportOptions(context),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, LibraryProvider provider) {
    if (provider.selectionMode) {
      return LibraryHeader(
        title: '${provider.selectedIds.length} selected',
        actions: [
          IconButtonRound(
            icon: Icons.delete_outline,
            size: 40,
            variant: IconButtonVariant.tonal,
            iconColor: const Color(0xFFC44C4C),
            onPressed: () => _confirmDelete(context, provider),
          ),
          const SizedBox(width: 8),
          IconButtonRound(
            icon: Icons.close,
            size: 40,
            variant: IconButtonVariant.tonal,
            onPressed: provider.clearSelection,
          ),
          const SizedBox(width: 8),
        ],
      );
    }
    return LibraryHeader(
      title: 'Library',
      subtitle: _librarySubtitle(provider.books),
      titleSize: 32,
      actions: [],
    );
  }

  String? _librarySubtitle(List<Book> books) {
    if (books.isEmpty) return null;
    final reading = books.where((b) => b.progress > 0 && b.progress < 1).length;
    if (reading == 0) return '${books.length} book${books.length == 1 ? '' : 's'}';
    return '$reading reading · ${books.length} total';
  }

  Widget _buildBody(BuildContext context, LibraryProvider provider) {
    if (provider.loading && provider.books.isEmpty) {
      return _buildLoading(context);
    }
    if (provider.error != null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        subtitle: provider.error!,
        primaryActionLabel: 'Try again',
        primaryActionIcon: Icons.refresh,
        onPrimaryAction: () => provider.loadBooks(),
      );
    }
    if (provider.books.isEmpty) return _buildEmpty(context);
    return Expanded(
      child: provider.isGridView
          ? _buildGrid(context, provider)
          : _buildList(context, provider),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        children: [
          const Skeleton(height: 18, width: 120),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.62,
              ),
              itemCount: 6,
              itemBuilder: (_, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Skeleton(
                    height: 200,
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                  ),
                  SizedBox(height: 8),
                  Skeleton(height: 12, width: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return EmptyState(
      icon: Icons.auto_stories_outlined,
      title: 'Your library is empty',
      subtitle:
          'Import an EPUB, paste a URL, or write a note to begin your reading collection.',
      primaryActionLabel: 'Add to library',
      primaryActionIcon: Icons.add,
      onPrimaryAction: () => _showImportOptions(context),
    );
  }

  Widget _buildGrid(BuildContext context, LibraryProvider provider) {
    final continueBooks =
        provider.books.where((b) => b.progress > 0 && b.progress < 1.0).toList();
    return RefreshIndicator(
      color: context.colors.accent,
      backgroundColor: context.colors.surface,
      onRefresh: () => provider.loadBooks(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (continueBooks.isNotEmpty)
            SliverToBoxAdapter(
              child: ContinueReadingShelf(
                books: continueBooks,
                onTap: (b) => _openReader(context, b.id),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            sliver: SliverToBoxAdapter(
              child: ReadingStreakCard(
                minutesPerDay: List.filled(7, 0),
                currentStreak: 0,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Text(
                    'All books',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${provider.books.length}',
                    style: TextStyle(
                      color: context.colors.textTertiary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 18,
                crossAxisSpacing: 18,
                childAspectRatio: 0.6,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final book = provider.books[index];
                  return LibraryBookCard(
                    book: book,
                    variant: LibraryCardVariant.grid,
                    selected: provider.selectedIds.contains(book.id),
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

  Widget _buildList(BuildContext context, LibraryProvider provider) {
    return RefreshIndicator(
      color: context.colors.accent,
      backgroundColor: context.colors.surface,
      onRefresh: () => provider.loadBooks(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: provider.books.length,
        separatorBuilder: (_, _) => const SizedBox(height: 4),
        itemBuilder: (context, i) {
          final book = provider.books[i];
          return LibraryBookCard(
            book: book,
            variant: LibraryCardVariant.list,
            selected: provider.selectedIds.contains(book.id),
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
      ),
    );
  }

  void _confirmDelete(BuildContext context, LibraryProvider provider) async {
    final confirmed = await StashDialog.show<bool>(
      context,
      title: 'Remove books?',
      content:
          'Delete ${provider.selectedIds.length} book${provider.selectedIds.length == 1 ? '' : 's'} and all their chapters?',
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: TextStyle(color: context.colors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'Delete',
            style: TextStyle(color: Color(0xFFC44C4C)),
          ),
        ),
      ],
    );
    if (confirmed == true) {
      await provider.deleteSelected();
    }
  }

  void _showImportOptions(BuildContext context) {
    ImportSheet.show(
      context,
      options: [
        ImportOption(
          icon: Icons.file_present_outlined,
          title: 'Import file',
          subtitle: 'EPUB, TXT, or Markdown',
          onTap: () => _importFile(context),
        ),
        ImportOption(
          icon: Icons.link,
          title: 'Add URL',
          subtitle: 'Save a web article for offline',
          onTap: () => _showAddUrlDialog(context),
        ),
        ImportOption(
          icon: Icons.edit_note,
          title: 'New snippet',
          subtitle: 'Capture a thought or quote',
          onTap: () => _showAddNoteDialog(context),
        ),
      ],
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
      if (!context.mounted) return;
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
          StashToast.show(
            context,
            message: '"$title" imported',
            icon: Icons.check,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        StashToast.show(
          context,
          message: 'Import failed: $e',
          icon: Icons.error_outline,
        );
      }
    }
  }

  Future<void> _importEpub(BuildContext context, String filePath) async {
    try {
      final epubService = EpubService();
      final result = await epubService.parseEpub(filePath);
      if (result == null) throw Exception('Failed to parse EPUB');
      if (!context.mounted) return;
      final db = context.read<DatabaseService>();

      final existing = await db.findLocalBook(result.book.title, result.book.author);
      if (existing != null) {
        if (context.mounted) {
          StashToast.show(
            context,
            message: '"${result.book.title}" is already in your library',
            icon: Icons.info_outline,
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
        StashToast.show(
          context,
          message: '"${result.book.title}" added (${result.chapters.length} chapters)',
          icon: Icons.check,
        );
      }
    } catch (e) {
      if (context.mounted) {
        StashToast.show(
          context,
          message: 'EPUB import failed: $e',
          icon: Icons.error_outline,
        );
      }
    }
  }

  void _showAddUrlDialog(BuildContext context) {
    UrlImportDialog.show(
      context,
      onSubmit: (url) => _fetchWebContent(context, url),
    );
  }

  Future<void> _fetchWebContent(BuildContext context, String url) async {
    if (url.isEmpty) return;
    if (!context.mounted) return;
    try {
      StashToast.show(
        context,
        message: 'Fetching content…',
        icon: Icons.cloud_download_outlined,
        duration: const Duration(seconds: 3),
      );

      final scraper = WebScraperService();
      final result = await scraper.fetchContent(url);
      if (!context.mounted) return;
      final db = context.read<DatabaseService>();

      final cache = CacheService(db.db);
      final cached = await cache.getCached(url);
      if (cached != null) {
        if (context.mounted) {
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
            StashToast.show(
              context,
              message: 'Loaded from cache',
              icon: Icons.check,
            );
          }
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
        StashToast.show(
          context,
          message: '"${result.title}" added',
          icon: Icons.check,
        );
      }
    } catch (e) {
      if (context.mounted) {
        StashToast.show(
          context,
          message: 'Failed to fetch: $e',
          icon: Icons.error_outline,
        );
      }
    }
  }

  void _showAddNoteDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    StashDialog.show<void>(
      context,
      title: 'New note',
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleCtrl,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: contentCtrl,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Content'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: context.colors.textSecondary),
          ),
        ),
        PremiumButton(
          label: 'Save',
          size: PremiumButtonSize.sm,
          onPressed: () {
            final t = titleCtrl.text.trim();
            final c = contentCtrl.text.trim();
            if (t.isEmpty || c.isEmpty) return;
            Navigator.pop(context);
            _createNote(context, t, c);
          },
        ),
      ],
    );
  }

  Future<void> _createNote(BuildContext context, String title, String content) async {
    if (title.isEmpty || content.isEmpty) return;
    if (!context.mounted) return;
    try {
      final snippetsProvider = context.read<SnippetsProvider>();
      await snippetsProvider.createSnippet(
        text: content,
        sourceTitle: title,
        tags: ['note'],
      );
      if (context.mounted) {
        StashToast.show(
          context,
          message: 'Note created',
          icon: Icons.check,
        );
      }
    } catch (e) {
      if (context.mounted) {
        StashToast.show(
          context,
          message: 'Failed to create note: $e',
          icon: Icons.error_outline,
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


