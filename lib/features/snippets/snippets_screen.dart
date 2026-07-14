import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/snippet.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/icon_button_round.dart';
import '../../widgets/library_header.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/snippet_card.dart';
import '../../widgets/snippet_detail_sheet.dart';
import '../../widgets/tag_filter_bar.dart';
import '../../widgets/toast.dart';
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
    final leftHanded = context.watch<ThemeProvider>().handMode == HandMode.left;
    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<SnippetsProvider>(
                builder: (context, p, _) => const LibraryHeader(
                  title: 'Snippets',
                  titleSize: 32,
                ),
              ),
              Expanded(
                child: Consumer<SnippetsProvider>(
                  builder: (context, p, _) {
                    if (p.loading && p.snippets.isEmpty) {
                      return _buildLoading();
                    }
                    if (p.error != null) {
                      return EmptyState(
                        icon: Icons.error_outline,
                        title: 'Could not load snippets',
                        subtitle: p.error!,
                        primaryActionLabel: 'Try again',
                        onPrimaryAction: () => p.loadSnippets(),
                      );
                    }
                    final items = p.snippets;
                    return Column(
                      children: [
                        if (p.allTags.isNotEmpty)
                          TagFilterBar(
                            tags: p.allTags,
                            selected: p.filterTag,
                            onChanged: p.setFilterTag,
                          ),
                        Expanded(
                          child: items.isEmpty
                              ? _buildEmpty(p.filterTag != null)
                              : _buildList(context, items, p),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Floating add button — position respects handMode.
        Positioned(
          left: leftHanded ? 20 : null,
          right: leftHanded ? null : 20,
          bottom: 12,
          child: IconButtonRound(
            icon: Icons.add,
            size: 52,
            variant: IconButtonVariant.filled,
            backgroundColor: context.colors.accent,
            iconColor: context.colors.onAccent,
            onPressed: () => _createSnippet(context),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const Skeleton(
        height: 180,
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
    );
  }

  Widget _buildEmpty(bool filtered) {
    return EmptyState(
      icon: Icons.format_quote_outlined,
      title: filtered ? 'No matching snippets' : 'No snippets yet',
      subtitle: filtered
          ? 'Try a different tag or remove the filter.'
          : 'Highlight text while reading, or tap + to create one.',
      primaryActionLabel: filtered ? null : 'New snippet',
      primaryActionIcon: Icons.add,
      onPrimaryAction: filtered ? null : () => _createSnippet(context),
    );
  }

  Widget _buildList(
      BuildContext context, List<Snippet> items, SnippetsProvider p) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final snippet = items[i];
        return SnippetCard(
          snippet: snippet,
          onTap: () => _editSnippet(context, snippet, p),
        );
      },
    );
  }

  void _createSnippet(BuildContext context) {
    SnippetDetailSheet.show(
      context,
      creating: true,
      onSave: (s) async {
        try {
          await context.read<SnippetsProvider>().createSnippet(
                text: s.text,
                note: s.note,
                sourceTitle: s.sourceTitle,
                color: s.color,
                tags: s.tags,
              );
          if (context.mounted) {
            StashToast.show(
              context,
              message: 'Snippet saved',
              icon: Icons.check,
            );
          }
        } catch (e) {
          if (context.mounted) {
            StashToast.show(
              context,
              message: 'Failed: $e',
              icon: Icons.error_outline,
            );
          }
        }
      },
    );
  }

  void _editSnippet(
      BuildContext context, Snippet snippet, SnippetsProvider p) {
    SnippetDetailSheet.show(
      context,
      snippet: snippet,
      onSave: (s) async {
        await p.updateSnippet(s);
        if (context.mounted) {
          StashToast.show(
            context,
            message: 'Snippet updated',
            icon: Icons.check,
          );
        }
      },
      onDelete: (id) async {
        await p.deleteSnippet(id);
        if (context.mounted) {
          StashToast.show(
            context,
            message: 'Snippet deleted',
            icon: Icons.check,
          );
        }
      },
    );
  }
}
