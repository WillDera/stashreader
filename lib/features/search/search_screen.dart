import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/book.dart';
import '../../core/models/chapter.dart' as ch_model;
import '../../core/models/snippet.dart';
import '../../core/services/database_service.dart';
import '../../core/services/search_service.dart';
import '../../theme/app_theme.dart';
import '../reader/reader_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  SearchService? _searchService;
  List<SearchResult> _results = [];
  List<String> _recentSearches = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    final db = context.read<DatabaseService>();
    _searchService = SearchService(db.db);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecentSearches();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  void _saveSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final searches = (prefs.getStringList('recent_searches') ?? []);
    searches.remove(query);
    searches.insert(0, query);
    if (searches.length > 10) searches.removeLast();
    await prefs.setStringList('recent_searches', searches);
    setState(() => _recentSearches = searches);
  }

  void _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    setState(() => _recentSearches = []);
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await _searchService!.searchAll(query.trim());
      setState(() => _results = results);
      _saveSearch(query.trim());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    } finally {
      setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom search header — no AppBar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search books, snippets...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: _search,
                      onChanged: (v) {
                        if (v.isEmpty) setState(() => _results = []);
                      },
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _results = []);
                        _focusNode.requestFocus();
                      },
                      child: const Icon(Icons.clear, size: 20),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Content
            Expanded(child: _buildBody(context, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark) {
    if (_searching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.isEmpty && _results.isEmpty) {
      if (_recentSearches.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search, size: 64, color: AppTheme.accent.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text(
                'Search your library',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Find books, chapters, and snippets',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
              ),
            ],
          ),
        );
      }
      return _buildRecentSearches(context, isDark);
    }

    if (_results.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: AppTheme.accent.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('No results for "${_searchController.text}"'),
          ],
        ),
      );
    }

    return _buildResults(context);
  }

  Widget _buildRecentSearches(BuildContext context, bool isDark) {
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Searches', style: Theme.of(context).textTheme.titleMedium),
              TextButton(
                onPressed: _clearRecentSearches,
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final q = _recentSearches[index];
              return GestureDetector(
                onTap: () {
                  _searchController.text = q;
                  _search(q);
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: borderColor, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.history, size: 20, color: AppTheme.accent.withValues(alpha: 0.6)),
                      const SizedBox(width: 12),
                      Text(q),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResults(BuildContext context) {
    final books = _results.where((r) => r.type == 'book').toList();
    final chapters = _results.where((r) => r.type == 'chapter').toList();
    final snippets = _results.where((r) => r.type == 'snippet').toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        if (books.isNotEmpty) ...[
          _sectionHeader(context, 'Books', books.length),
          ...books.map((r) => _buildBookResult(context, r)),
        ],
        if (chapters.isNotEmpty) ...[
          _sectionHeader(context, 'Chapters', chapters.length),
          ...chapters.map((r) => _buildChapterResult(context, r)),
        ],
        if (snippets.isNotEmpty) ...[
          _sectionHeader(context, 'Snippets', snippets.length),
          ...snippets.map((r) => _buildSnippetResult(context, r)),
        ],
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        '$title ($count)',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.accent,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  // ponytail: custom result rows, no ListTile
  Widget _buildBookResult(BuildContext context, SearchResult result) {
    final book = result.item as Book;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ReaderScreen(bookId: book.id)),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
        ),
        child: Row(
          children: [
            Icon(Icons.menu_book, color: AppTheme.accent, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                  if (book.author != null) ...[
                    const SizedBox(height: 2),
                    Text(book.author!, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            Text('${(book.progress * 100).toInt()}%', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterResult(BuildContext context, SearchResult result) {
    final chapter = result.item as ch_model.Chapter;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ReaderScreen(bookId: chapter.bookId)),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
        ),
        child: Row(
          children: [
            Icon(Icons.article, color: AppTheme.accent, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chapter.title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                    result.matchPreview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnippetResult(BuildContext context, SearchResult result) {
    final snippet = result.item as Snippet;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.bookmark, color: AppTheme.accent, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  snippet.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (snippet.sourceTitle != null) ...[
                  const SizedBox(height: 2),
                  Text(snippet.sourceTitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
