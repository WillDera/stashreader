import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/snippet.dart';
import '../../theme/app_theme.dart';
import '../../widgets/snippet_card.dart';
import 'snippets_provider.dart';

class SnippetsScreen extends StatefulWidget {
  const SnippetsScreen({super.key});

  @override
  State<SnippetsScreen> createState() => _SnippetsScreenState();
}

class _SnippetsScreenState extends State<SnippetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SnippetsProvider>().loadSnippets();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Snippets',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            // Content
            Expanded(
              child: Consumer<SnippetsProvider>(
                builder: (context, provider, _) {
                  if (provider.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (provider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Error: ${provider.error}'),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => provider.loadSnippets(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      // Tag filter bar
                      if (provider.allTags.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ChoiceChip(
                                  label: const Text('All'),
                                  selected: provider.filterTag == null,
                                  onSelected: (_) => provider.setFilterTag(null),
                                  selectedColor: AppTheme.accent.withValues(alpha: 0.2),
                                ),
                                const SizedBox(width: 6),
                                ...provider.allTags.map((tag) {
                                  final selected = provider.filterTag == tag;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      label: Text(tag),
                                      selected: selected,
                                      onSelected: (_) =>
                                          provider.setFilterTag(selected ? null : tag),
                                      selectedColor: AppTheme.accent.withValues(alpha: 0.2),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      // Snippet list
                      Expanded(
                        child: provider.snippets.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.bookmark_outline,
                                        size: 48, color: AppTheme.accent.withValues(alpha: 0.35)),
                                    const SizedBox(height: 14),
                                    Text(
                                      provider.filterTag != null
                                          ? 'No snippets with tag "${provider.filterTag}"'
                                          : 'No snippets yet',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      provider.filterTag != null
                                          ? 'Try a different tag'
                                          : 'Select text in the reader to create snippets',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppTheme.lightTextSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: () => provider.loadSnippets(),
                                child: ListView.builder(
                                  padding: const EdgeInsets.only(top: 4, bottom: 80),
                                  itemCount: provider.snippets.length,
                                  itemBuilder: (context, index) {
                                    final snippet = provider.snippets[index];
                                    return Dismissible(
                                      key: ValueKey(snippet.id),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 20),
                                        color: Colors.red,
                                        child: const Icon(Icons.delete, color: Colors.white),
                                      ),
                                      onDismissed: (_) {
                                        provider.deleteSnippet(snippet.id);
                                      },
                                      child: SnippetCard(
                                        snippet: snippet,
                                        onTap: () => _showSnippetDetail(context, snippet, provider),
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'snippets_fab',
        onPressed: () => _showCreateSnippetDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showSnippetDetail(
      BuildContext context, Snippet snippet, SnippetsProvider provider) {
    final textController = TextEditingController(text: snippet.text);
    final noteController = TextEditingController(text: snippet.note);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Snippet'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(labelText: 'Text'),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note'),
                maxLines: 3,
              ),
              if (snippet.sourceTitle != null) ...[
                const SizedBox(height: 8),
                Text('Source: ${snippet.sourceTitle}',
                    style: Theme.of(ctx).textTheme.bodySmall),
              ],
              if (snippet.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: snippet.tags.map((t) {
                    return Chip(label: Text(t, style: const TextStyle(fontSize: 12)));
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              provider.deleteSnippet(snippet.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final updated = snippet.copyWith(
                text: textController.text.trim(),
                note: noteController.text.trim().isNotEmpty
                    ? noteController.text.trim()
                    : null,
              );
              provider.updateSnippet(updated);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accent),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCreateSnippetDialog(BuildContext context) {
    final textController = TextEditingController();
    final noteController = TextEditingController();
    final sourceController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Snippet'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'Text',
                  hintText: 'Paste or type the snippet...',
                ),
                maxLines: 4,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sourceController,
                decoration: const InputDecoration(
                  labelText: 'Source (optional)',
                  hintText: 'Book or article title',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (textController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                await context.read<SnippetsProvider>().createSnippet(
                      text: textController.text.trim(),
                      note: noteController.text.trim().isNotEmpty
                          ? noteController.text.trim()
                          : null,
                      sourceTitle: sourceController.text.trim().isNotEmpty
                          ? sourceController.text.trim()
                          : null,
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Snippet created')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accent),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
