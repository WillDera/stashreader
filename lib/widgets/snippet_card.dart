import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/models/snippet.dart';
import '../theme/app_theme.dart';
import '../theme/tokens/app_colors.dart';
import '../theme/tokens/app_spacing.dart';
import '../theme/tokens/app_type.dart';
import 'animated_press.dart';
import 'tag_pill.dart';

/// A Deepstash-style snippet "idea card". Top hairline in the highlight
/// color, large italic quote in Literata, optional note, source, tags.
class SnippetCard extends StatelessWidget {
  final Snippet snippet;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool dense;

  const SnippetCard({
    super.key,
    required this.snippet,
    this.onTap,
    this.onLongPress,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final brightness = Theme.of(context).brightness;
    final isSepia = c.bg == AppColors.sepiaBg;
    final colorKey = snippet.color ?? 'yellow';
    final color = AppColors.highlight(colorKey, brightness, isSepia: isSepia);

    return AnimatedPress(
      onTap: onTap,
      onLongPress: onLongPress,
      scaleDown: 0.99,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: AppSpacing.brLg,
          border: Border.all(color: c.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top color hairline
            Container(
              height: 2,
              width: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 16),
            // Quote
            Text(
              '"${snippet.text}"',
              style: AppType.readingItalic(
                fontSize: 16,
                lineHeight: 1.5,
                color: c.textPrimary,
              ),
            ),
            // Note
            if (snippet.note != null && snippet.note!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: c.surfaceMuted,
                  borderRadius: AppSpacing.brMd,
                ),
                child: Text(
                  snippet.note!,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Footer
            Row(
              children: [
                if (snippet.sourceTitle != null) ...[
                  Icon(
                    Icons.book_outlined,
                    size: 13,
                    color: c.textTertiary,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      snippet.sourceTitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  '·',
                  style: TextStyle(color: c.textTertiary, fontSize: 12),
                ),
                const SizedBox(width: 8),
                Text(
                  _relativeDate(snippet.createdAt),
                  style: TextStyle(
                    color: c.textTertiary,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (snippet.tags.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: c.surfaceMuted,
                      borderRadius: AppSpacing.brPill,
                    ),
                    child: Text(
                      '${snippet.tags.length} tag${snippet.tags.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
              ],
            ),
            if (snippet.tags.isNotEmpty && !dense) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: snippet.tags
                    .take(4)
                    .map((t) => TagPill(label: t))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _relativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 7) return DateFormat('MMM d').format(date);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}
