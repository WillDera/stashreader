import 'dart:io';
import 'package:flutter/material.dart';
import '../core/models/book.dart';
import '../theme/app_theme.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final double coverHeight;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.coverHeight = 160,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Cover
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildCover(context),
              ),
              const SizedBox(width: 16),
              // Info
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
              const Icon(Icons.chevron_right, color: AppTheme.accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover(BuildContext context) {
    if (book.coverPath != null && book.coverPath!.isNotEmpty) {
      return Image.file(
        File(book.coverPath!),
        width: coverHeight * 0.6,
        height: coverHeight,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholderCover(),
      );
    }
    return _placeholderCover();
  }

  Widget _placeholderCover() {
    return Container(
      width: coverHeight * 0.6,
      height: coverHeight,
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            book.source == 'web' ? Icons.language : Icons.menu_book,
            color: AppTheme.accent,
            size: 32,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              book.title.length > 3 ? book.title.substring(0, 2).toUpperCase() : book.title,
              style: const TextStyle(
                color: AppTheme.accent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
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
        minHeight: 4,
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
    return Icon(icon, size: 14, color: AppTheme.accent);
  }
}
