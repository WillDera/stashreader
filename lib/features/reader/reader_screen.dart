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
  ReaderProvider? _provider;
  String? _selectedText;
  bool _showUI = true;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadAndRestore());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider ??= context.read<ReaderProvider>();
  }

  Future<void> _loadAndRestore() async {
    await _provider!.loadBook(widget.bookId);
    if (!mounted) return;
    _restoreScrollPosition();
  }

  void _restoreScrollPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        final pos = _provider!.scrollPosition;
        if (pos > 0) {
          _scrollController.jumpTo(
              pos.clamp(0, _scrollController.position.maxScrollExtent));
        }
      }
    });
  }

  @override
  void dispose() {
    _provider?.stopReadingTimer();
    _scrollController.dispose();
    super.dispose();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final currentOffset = _scrollController.hasClients
          ? _scrollController.offset
          : _lastScrollOffset;
      context.read<ReaderProvider>().updateScrollPosition(currentOffset);
      final diff = currentOffset - _lastScrollOffset;

      if (diff > 20 && currentOffset > 50) {
        if (_showUI) setState(() => _showUI = false);
        _lastScrollOffset = currentOffset;
      } else if (diff < -5 || currentOffset <= 0) {
        if (!_showUI) setState(() => _showUI = true);
        _lastScrollOffset = currentOffset;
      }
    }
    return false;
  }

  void _handleTapUp(TapUpDetails details) {
    if (!mounted) return;
    final RenderBox renderBox = context.findRenderObject()! as RenderBox;
    final localPos = renderBox.globalToLocal(details.globalPosition);
    final screenWidth = renderBox.size.width;

    final provider = context.read<ReaderProvider>();
    if (provider.chapters.length <= 1) return;

    if (localPos.dx < screenWidth / 3) {
      provider.goToPreviousChapter();
      setState(() {
        _lastScrollOffset = 0;
        _showUI = true;
      });
    } else if (localPos.dx > 2 * screenWidth / 3) {
      provider.goToNextChapter();
      setState(() {
        _lastScrollOffset = 0;
        _showUI = true;
      });
    } else {
      setState(() => _showUI = !_showUI);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    return Consumer<ReaderProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return Scaffold(
              backgroundColor: themeProv.isSepia
                  ? AppTheme.sepiaBackground
                  : (themeProv.isDark ? AppTheme.darkBackground : AppTheme.lightBackground),
              body: const Center(child: CircularProgressIndicator()),
            );
          }
          if (provider.error != null || provider.currentChapter == null) {
            final bgColor = themeProv.isSepia
                ? AppTheme.sepiaBackground
                : (themeProv.isDark ? AppTheme.darkBackground : AppTheme.lightBackground);
            return Scaffold(
              backgroundColor: bgColor,
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: AppTheme.accent.withValues(alpha: 0.6)),
                    const SizedBox(height: 16),
                    Text(provider.error ?? 'Content not available'),
                  ],
                ),
              ),
            );
          }

          final book = provider.book!;
          final chapter = provider.currentChapter!;
          final bgColor = themeProv.isSepia
              ? AppTheme.sepiaBackground
              : (themeProv.isDark ? AppTheme.darkBackground : AppTheme.lightBackground);
          final textColor = themeProv.isSepia
              ? AppTheme.sepiaText
              : (themeProv.isDark ? AppTheme.darkText : AppTheme.lightText);
          final textSecondaryColor = themeProv.isSepia
              ? AppTheme.sepiaTextSecondary
              : (themeProv.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary);

          return Scaffold(
            backgroundColor: bgColor,
            appBar: _showUI
                ? AppBar(
                    backgroundColor: Colors.transparent,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    title: Text(book.title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15, color: textSecondaryColor)),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.text_fields),
                        tooltip: 'Reader Settings',
                        onPressed: () =>
                            _showReaderSettings(context, themeProv),
                      ),
                    ],
                  )
                : null,
            body: Column(
              children: [
                // Thin top progress bar — single 2px line, no container
                if (provider.chapters.length > 1)
                  _buildTopProgressBar(provider),
                // Content area with tap zones
                Expanded(
                  child: GestureDetector(
                    onTapUp: _handleTapUp,
                    child: NotificationListener<ScrollUpdateNotification>(
                      onNotification: _onScrollNotification,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Chapter title — slightly larger, more bottom margin
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                chapter.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  fontStyle: FontStyle.italic,
                                  color: textSecondaryColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            // Content text
                            SelectableText.rich(
                              TextSpan(
                                text: _stripHtml(chapter.content),
                                style: TextStyle(
                                  fontSize: themeProv.fontSize,
                                  height: themeProv.lineHeight,
                                  fontFamily: _resolveFont(themeProv),
                                  color: textColor,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              onSelectionChanged: (selection, cause) {
                                if (selection.isValid &&
                                    !selection.isCollapsed) {
                                  final content =
                                      _stripHtml(chapter.content);
                                  _selectedText = content.substring(
                                      selection.start, selection.end);
                                } else {
                                  _selectedText = null;
                                }
                              },
                              contextMenuBuilder:
                                  (context, editableTextState) {
                                final items =
                                    List<ContextMenuButtonItem>.from(
                                        editableTextState
                                            .contextMenuButtonItems);
                                if (_selectedText != null &&
                                    _selectedText!
                                        .trim()
                                        .isNotEmpty) {
                                  items.add(ContextMenuButtonItem(
                                    onPressed: () {
                                      _createSnippet(context,
                                          _selectedText!, provider);
                                    },
                                    label: 'Create Snippet',
                                  ));
                                }
                                return AdaptiveTextSelectionToolbar
                                    .buttonItems(
                                  buttonItems: items,
                                  anchors: editableTextState
                                      .contextMenuAnchors,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar:
                _showUI && provider.chapters.length > 1
                    ? _buildBottomNav(themeProv, provider)
                    : null,
          );
        },
    );
  }

  // ponytail: single 2px line with rounded caps, no container wrapper
  Widget _buildTopProgressBar(ReaderProvider provider) {
    final fraction = (provider.currentIndex + 1) / provider.chapters.length;
    return SizedBox(
      height: 2,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: fraction.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.accent,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(ThemeProvider themeProv, ReaderProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () => _showChapterList(context, provider),
              icon: const Icon(Icons.list_alt, size: 18),
              label: const Text('Chapters', style: TextStyle(fontSize: 13)),
            ),
            TextButton.icon(
              onPressed: provider.currentIndex < provider.chapters.length - 1
                  ? () {
                      provider.goToNextChapter();
                      setState(() {
                        _lastScrollOffset = 0;
                        _showUI = true;
                      });
                    }
                  : null,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Next', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  void _showChapterList(BuildContext context, ReaderProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child:
                  Text('Chapters', style: Theme.of(ctx).textTheme.titleLarge),
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
                      setState(() {
                        _lastScrollOffset = 0;
                        _showUI = true;
                      });
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
      builder: (ctx) => ReaderSettingsPanel(themeProvider: themeProv),
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
                borderRadius: BorderRadius.circular(12),
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
              _saveSnippet(
                  context, text, noteController.text.trim(), provider);
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Snippet created!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create snippet: $e')),
        );
      }
    }
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</(?:p|div|h[1-6]|li|blockquote|tr|th|td)>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  String _resolveFont(ThemeProvider themeProv) {
    if (themeProv.googleFont != null && themeProv.googleFont!.isNotEmpty) {
      return themeProv.googleFont!;
    }
    return themeProv.fontFamily;
  }
}
