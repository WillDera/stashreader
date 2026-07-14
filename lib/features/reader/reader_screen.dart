import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/snippets/snippets_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/reader_settings_panel.dart';
import 'reader_provider.dart';

class ReaderScreen extends StatefulWidget {
  final int bookId;

  const ReaderScreen({super.key, required this.bookId});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ReaderProvider>().loadBook(widget.bookId);
      // Restore scroll position after the chapter renders
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final pos = context.read<ReaderProvider>().scrollPosition;
        if (pos > 0 && _scrollController.hasClients) {
          _scrollController.jumpTo(pos.clamp(0, _scrollController.position.maxScrollExtent));
        }
      });
    });
  }

  @override
  void dispose() {
    final provider = context.read<ReaderProvider>();
    provider.stopReadingTimer();
    provider.updateScrollPosition(
        _scrollController.hasClients ? _scrollController.offset : 0);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          context.read<ReaderProvider>().stopReadingTimer();
        }
      },
      child: Consumer<ReaderProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return Scaffold(
              appBar: AppBar(title: const Text('Loading...')),
              body: const Center(child: CircularProgressIndicator()),
            );
          }
          if (provider.error != null || provider.currentChapter == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Reader')),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppTheme.accent),
                    const SizedBox(height: 16),
                    Text(provider.error ?? 'Content not available'),
                  ],
                ),
              ),
            );
          }

          final book = provider.book!;
          final chapter = provider.currentChapter!;

          return Scaffold(
            backgroundColor: themeProv.isDark
                ? AppTheme.darkBackground
                : AppTheme.lightBackground,
            appBar: AppBar(
              title: Text(book.title, style: const TextStyle(fontSize: 16)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.list_alt),
                  tooltip: 'Chapters',
                  onPressed: () =>
                      _showChapterList(context, provider),
                ),
                IconButton(
                  icon: const Icon(Icons.text_fields),
                  tooltip: 'Reader Settings',
                  onPressed: () =>
                      _showReaderSettings(context, themeProv),
                ),
              ],
            ),
            body: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null) {
                  if (details.primaryVelocity! < -200) {
                    provider.goToNextChapter();
                  } else if (details.primaryVelocity! > 200) {
                    provider.goToPreviousChapter();
                  }
                }
              },
              child: Column(
                children: [
                  // Chapter title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                    child: Text(
                      chapter.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  // Progress
                  if (provider.chapters.length > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Text(
                            '${provider.currentIndex + 1}/${provider.chapters.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: themeProv.isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: (provider.currentIndex + 1) /
                                    provider.chapters.length,
                                minHeight: 3,
                                backgroundColor: themeProv.isDark
                                    ? AppTheme.darkBorder
                                    : AppTheme.lightBorder,
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        AppTheme.accent),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                      child: SelectableText.rich(
                        TextSpan(
                          text: _stripHtml(chapter.content),
                          style: TextStyle(
                            fontSize: themeProv.fontSize,
                            height: themeProv.lineHeight,
                            fontFamily: _resolveFont(themeProv),
                            color: themeProv.isDark
                                ? AppTheme.darkText
                                : AppTheme.lightText,
                          ),
                        ),
                        onSelectionChanged: (selection, cause) {
                          if (selection.isValid &&
                              !selection.isCollapsed) {
                            final content = _stripHtml(chapter.content);
                            _selectedText =
                                content.substring(selection.start, selection.end);
                          } else {
                            _selectedText = null;
                          }
                        },
                        contextMenuBuilder: (context, editableTextState) {
                          final items =
                              List<ContextMenuButtonItem>.from(
                                  editableTextState.contextMenuButtonItems);
                          if (_selectedText != null &&
                              _selectedText!.trim().isNotEmpty) {
                            items.add(ContextMenuButtonItem(
                              onPressed: () {
                                _createSnippet(
                                    context, _selectedText!, provider);
                              },
                              label: 'Create Snippet',
                            ));
                          }
                          return AdaptiveTextSelectionToolbar.buttonItems(
                            buttonItems: items,
                            anchors: editableTextState.contextMenuAnchors,
                          );
                        },
                      ),
                    ),
                  ),
                  // Bottom nav for chapters
                  if (provider.chapters.length > 1)
                    _buildBottomNav(themeProv, provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNav(ThemeProvider themeProv, ReaderProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color:
            themeProv.isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        border: Border(
          top: BorderSide(
            color: themeProv.isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: provider.currentIndex > 0
                ? () => provider.goToPreviousChapter()
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
          ),
          Text(
            '${provider.currentIndex + 1} / ${provider.chapters.length}',
            style: const TextStyle(fontSize: 12),
          ),
          TextButton.icon(
            onPressed: provider.currentIndex < provider.chapters.length - 1
                ? () => provider.goToNextChapter()
                : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Next'),
          ),
        ],
      ),
    );
  }

  void _showChapterList(BuildContext context, ReaderProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Chapters',
                  style: Theme.of(ctx).textTheme.titleLarge),
            ),
            const Divider(height: 0),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: provider.chapters.length,
                itemBuilder: (ctx, i) {
                  final ch = provider.chapters[i];
                  final isCurrent = i == provider.currentIndex;
                  return ListTile(
                    selected: isCurrent,
                    selectedTileColor:
                        AppTheme.accent.withValues(alpha: 0.1),
                    leading: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: isCurrent ? AppTheme.accent : null,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    title: Text(ch.title,
                        style: TextStyle(
                          fontWeight: isCurrent
                              ? FontWeight.w600
                              : FontWeight.normal,
                        )),
                    trailing: ch.readAt != null
                        ? const Icon(Icons.check_circle_outline,
                            size: 18, color: AppTheme.accent)
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      provider.navigateToChapter(i);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReaderSettings(BuildContext context, ThemeProvider themeProv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) =>
          ReaderSettingsPanel(themeProvider: themeProv),
    );
  }

  void _createSnippet(
      BuildContext context, String text, ReaderProvider provider) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Snippet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(text,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontStyle: FontStyle.italic)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'Add a personal note...',
              ),
              maxLines: 3,
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
              _saveSnippet(context, text, noteController.text.trim(), provider);
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accent),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSnippet(BuildContext context, String text, String note,
      ReaderProvider provider) async {
    try {
      final snippetsProvider = context.read<SnippetsProvider>();
      await snippetsProvider.createSnippet(
        text: text,
        note: note.isNotEmpty ? note : null,
        sourceTitle: provider.book?.title,
        sourceUrl: provider.book?.sourceUrl,
        bookId: provider.book?.id,
        chapterId: provider.currentChapter?.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Snippet created!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create snippet: $e')),
        );
      }
    }
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _resolveFont(ThemeProvider themeProv) {
    if (themeProv.googleFont != null && themeProv.googleFont!.isNotEmpty) {
      return themeProv.googleFont!;
    }
    return themeProv.fontFamily;
  }
}
