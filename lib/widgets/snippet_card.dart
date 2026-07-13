import 'package:flutter/material.dart';
import '../core/models/snippet.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class SnippetCard extends StatelessWidget {
  final Snippet snippet;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const SnippetCard({
    super.key,
    required this.snippet,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text quote
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (snippet.color != null
                          ? Color(int.parse(snippet.color!.replaceFirst('#', '0xFF')))
                          : AppTheme.accent)
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (snippet.color != null
                            ? Color(int.parse(snippet.color!.replaceFirst('#', '0xFF')))
                            : AppTheme.accent)
                        .withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  snippet.text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Note
              if (snippet.note != null && snippet.note!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  snippet.note!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 8),

              // Footer: source + tags + date
              Row(
                children: [
                  if (snippet.sourceTitle != null) ...[
                    Icon(Icons.source, size: 14, color: AppTheme.accent),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        snippet.sourceTitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.accent,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (snippet.sourceTitle != null) const Spacer(),
                  Text(
                    dateFormat.format(snippet.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                  ),
                ],
              ),

              // Tags
              if (snippet.tags.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: snippet.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
