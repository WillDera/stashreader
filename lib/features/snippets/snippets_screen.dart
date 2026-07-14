import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/snippet.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/icon_button_round.dart';
import '../../widgets/library_header.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/one_hand_spacer.dart';
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
          child: Consumer<SnippetsProvider>(
            builder: (context, p, _) => _body(context, p),
          ),
        ),
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

  Widget _body(BuildContext context, SnippetsProvider p) {
    // Single scrollable surface — spacer, header, tag bar, and list all
    // scroll together, matching the Settings layout.
    if (p.loading && p.snippets.isEmpty) return _loading();
    if (p.error != null) {
      return Column(
        children: [
          const LibraryHeader(title: 'Snippets', titleSize: 32),
          Expanded(
            child: EmptyState(
              icon: Icons.error_outline,
              title: 'Could not load snippets',
              subtitle: p.error!,
              primaryActionLabel: 'Try again',
              onPrimaryAction: () => p.loadSnippets(),
            ),
          ),
        ],
      );
    }
    final items = p.snippets;
    if (items.isEmpty && p.filterTag == null) {
      return Column(
        children: [
          const LibraryHeader(title: 'Snippets', titleSize: 32),
          Expanded(
            child: EmptyState(
              icon: Icons.format_quote_outlined,
              title: 'No snippets yet',
              subtitle:
                  'Highlight text while reading, or tap + to create one.',
              primaryActionLabel: 'New snippet',
              primaryActionIcon: Icons.add,
              onPrimaryAction: () => _createSnippet(context),
            ),
          ),
        ],
      );
    }
    return ListView(
      padding: EdgeInsets.zero,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const OneHandSpacer(),
        const LibraryHeader(title: 'Snippets', titleSize: 32),
        if (p.allTags.isNotEmpty)
          TagFilterBar(
            tags: p.allTags,
            selected: p.filterTag,
            onChanged: p.setFilterTag,
          ),
        if (items.isEmpty)
          SizedBox(
            height: 200,
            child: EmptyState(
              icon: Icons.format_quote_outlined,
              title: 'No matching snippets',
              subtitle: 'Try a different tag or remove the filter.',
            ),
          )
        else
          ...items.map(
            (s) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: SnippetCard(
                snippet: s,
                onTap: () => _editSnippet(context, s, p),
              ),
            ),
          ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _loading() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        const OneHandSpacer(),
        for (var i = 0; i < 4; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Skeleton(
              height: 180,
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
          ),
      ],
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
                context, message: 'Snippet saved', icon: Icons.check);
          }
        } catch (e) {
          if (context.mounted) {
            StashToast.show(
                context, message: 'Failed: $e', icon: Icons.error_outline);
          }
        }
      },
    );
  }

  void _editSnippet(BuildContext context, Snippet snippet, SnippetsProvider p) {
    SnippetDetailSheet.show(
      context,
      snippet: snippet,
      onSave: (s) async {
        await p.updateSnippet(s);
        if (context.mounted) {
          StashToast.show(context, message: 'Snippet updated', icon: Icons.check);
        }
      },
      onDelete: (id) async {
        await p.deleteSnippet(id);
        if (context.mounted) {
          StashToast.show(context, message: 'Snippet deleted', icon: Icons.check);
        }
      },
    );
  }
}
