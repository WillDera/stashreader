import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class ReaderSettingsPanel extends StatefulWidget {
  final ThemeProvider themeProvider;

  const ReaderSettingsPanel({super.key, required this.themeProvider});

  @override
  State<ReaderSettingsPanel> createState() => _ReaderSettingsPanelState();
}

class _ReaderSettingsPanelState extends State<ReaderSettingsPanel> {
  static const _fontOptions = ['System', 'Serif', 'Mono'];
  static const _fontSizeRange = 12.0;
  static const _fontSizeRangeEnd = 28.0;

  @override
  Widget build(BuildContext context) {
    final themeProv = widget.themeProvider;
    final isDark = themeProv.isDark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Reader Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),

            // Font family
            Text('Font', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _fontOptions.map((font) {
                final selected = themeProv.fontFamily == font;
                return ChoiceChip(
                  label: Text(font),
                  selected: selected,
                  onSelected: (_) => themeProv.setFontFamily(font),
                  selectedColor: AppTheme.accent.withValues(alpha: 0.2),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Font size
            Row(
              children: [
                Text('Size', style: Theme.of(context).textTheme.labelLarge),
                const Spacer(),
                Text('${themeProv.fontSize.toInt()}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            Slider(
              value: themeProv.fontSize,
              min: _fontSizeRange,
              max: _fontSizeRangeEnd,
              divisions: 16,
              activeColor: AppTheme.accent,
              onChanged: (v) => themeProv.setFontSize(v),
            ),
            const SizedBox(height: 8),

            // Line height
            Row(
              children: [
                Text('Line Height', style: Theme.of(context).textTheme.labelLarge),
                const Spacer(),
                Text(themeProv.lineHeight.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            Slider(
              value: themeProv.lineHeight,
              min: 1.0,
              max: 2.5,
              divisions: 15,
              activeColor: AppTheme.accent,
              onChanged: (v) => themeProv.setLineHeight(v),
            ),
            const SizedBox(height: 16),

            // Theme toggle
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                color: AppTheme.accent,
              ),
              title: Text(isDark ? 'Dark Mode' : 'Light Mode'),
              trailing: Switch(
                value: isDark,
                activeColor: AppTheme.accent,
                onChanged: (_) => themeProv.toggleTheme(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
