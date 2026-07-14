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
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    // ponytail: left-accent border, no Card, no shadow, no elevation
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: _parseColor(snippet.color), width: 3),
            right: BorderSide(color: borderColor, width: 0.5),
            top: BorderSide(color: borderColor, width: 0.5),
            bottom: BorderSide(color: borderColor, width: 0.5),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text quote
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _parseColor(snippet.color).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _parseColor(snippet.color).withValues(alpha: 0.15),
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
              const SizedBox(height: 10),
              Text(
                snippet.note!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                      height: 1.4,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 10),

            // Footer: source + tags + date
            Row(
              children: [
                if (snippet.sourceTitle != null) ...[
                  Icon(Icons.source, size: 14, color: AppTheme.accent.withValues(alpha: 0.7)),
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
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: snippet.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
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
    );
  }

  static Color _parseColor(String? color) {
    if (color == null || color.isEmpty) return AppTheme.accent;
    try {
      return Color(int.parse(color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppTheme.accent;
    }
  }
}
