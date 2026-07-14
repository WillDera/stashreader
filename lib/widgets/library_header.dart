import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'icon_button_round.dart';

/// A page header used by Library, Snippets, Search, Settings.
/// Title (displayMedium), optional subtitle (small, secondary), optional
/// trailing actions, optional leading widget.
class LibraryHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBack;
  final EdgeInsets padding;
  final double titleSize;

  const LibraryHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.leading,
    this.showBackButton = false,
    this.onBack,
    this.padding = const EdgeInsets.fromLTRB(24, 16, 16, 12),
    this.titleSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showBackButton) ...[
            IconButtonRound(
              icon: Icons.arrow_back_ios_new,
              size: 40,
              variant: IconButtonVariant.tonal,
              onPressed: onBack ?? () => Navigator.maybePop(context),
            ),
            const SizedBox(width: 8),
          ] else if (leading != null) ...[
            leading!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: c.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
