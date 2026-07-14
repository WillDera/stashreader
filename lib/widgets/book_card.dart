import 'dart:io';
import 'package:flutter/material.dart';
import '../core/models/book.dart';
import '../theme/app_theme.dart';

enum BookCardVariant { list, grid }

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool selectionMode;
  final BookCardVariant variant;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.onLongPress,
    this.selected = false,
    this.selectionMode = false,
    this.variant = BookCardVariant.list,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: variant == BookCardVariant.grid
          ? _buildGridLayout(context, isDark)
          : _buildListLayout(context, isDark),
    );
  }

  // ponytail: no Card, no shadow, no elevation — content defines the surface
  Widget _buildListLayout(BuildContext context, bool isDark) {
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          if (selectionMode)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? AppTheme.accent : null,
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildCover(context, variant: BookCardVariant.list),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  book.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (book.author != null && book.author!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    book.author!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                _buildProgressBar(context),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _sourceIcon(book.source),
                    const SizedBox(width: 4),
                    Text(
                      book.totalChapters > 0
                          ? '${book.currentChapterIndex}/${book.totalChapters} chapters'
                          : '${(book.progress * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ponytail: cover image + title only, no card wrapper
  Widget _buildGridLayout(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildCover(context, variant: BookCardVariant.grid),
            ),
            if (selectionMode)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected ? AppTheme.accent : Colors.white,
                  size: 22,
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            book.title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCover(BuildContext context, {required BookCardVariant variant}) {
    final placeholder = _placeholderCover(variant: variant);

    Widget cover;
    if (book.coverPath != null && book.coverPath!.isNotEmpty) {
      cover = Image.file(
        File(book.coverPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      );
    } else {
      cover = placeholder;
    }

    if (variant == BookCardVariant.grid) {
      return AspectRatio(
        aspectRatio: 3 / 4,
        child: cover,
      );
    }
    return SizedBox(width: 36, height: 60, child: cover);
  }

  Widget _placeholderCover({required BookCardVariant variant}) {
    if (variant == BookCardVariant.grid) {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              book.source == 'web' ? Icons.language : Icons.auto_stories,
              color: AppTheme.accent.withValues(alpha: 0.7),
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              book.title.length > 3 ? book.title.substring(0, 2).toUpperCase() : book.title,
              style: TextStyle(
                color: AppTheme.accent.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      width: 36,
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            book.source == 'web' ? Icons.language : Icons.auto_stories,
            color: AppTheme.accent.withValues(alpha: 0.7),
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: book.progress.clamp(0.0, 1.0),
        minHeight: 3,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkBorder
            : AppTheme.lightBorder,
        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
      ),
    );
  }

  Widget _sourceIcon(String source) {
    IconData icon;
    switch (source) {
      case 'web':
        icon = Icons.language;
        break;
      case 'manual':
        icon = Icons.edit_note;
        break;
      default:
        icon = Icons.file_present;
    }
    return Icon(icon, size: 14, color: AppTheme.accent.withValues(alpha: 0.6));
  }
}
