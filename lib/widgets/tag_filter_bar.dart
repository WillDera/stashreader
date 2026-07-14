import 'package:flutter/material.dart';
import 'tag_pill.dart';

class TagFilterBar extends StatelessWidget {
  final List<String> tags;
  final String? selected;
  final ValueChanged<String?> onChanged;
  final ScrollController? controller;

  const TagFilterBar({
    super.key,
    required this.tags,
    required this.selected,
    required this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView(
        controller: controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          TagPill(
            label: 'All',
            selected: selected == null,
            onTap: () => onChanged(null),
            leadingIcon: Icons.apps,
          ),
          const SizedBox(width: 8),
          for (final tag in tags) ...[
            TagPill(
              label: tag,
              selected: selected == tag,
              onTap: () => onChanged(selected == tag ? null : tag),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
