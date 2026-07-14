import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../theme/tokens/app_spacing.dart';
import '../theme/tokens/app_type.dart';
import 'animated_press.dart';
import 'dialog_sheet.dart';
import 'segmented_control.dart';

class ReaderSettingsSheet extends StatefulWidget {
  final ThemeProvider themeProvider;
  const ReaderSettingsSheet({super.key, required this.themeProvider});

  static Future<void> show(BuildContext context, ThemeProvider prov) {
    return StashSheet.show<void>(
      context,
      title: 'Reader',
      subtitle: 'Tune typography and theme.',
      initialChildSize: 0.78,
      maxChildSize: 0.95,
      child: ReaderSettingsSheet(themeProvider: prov),
    );
  }

  @override
  State<ReaderSettingsSheet> createState() => _ReaderSettingsSheetState();
}

class _ReaderSettingsSheetState extends State<ReaderSettingsSheet> {
  @override
  Widget build(BuildContext context) {
    final p = widget.themeProvider;
    final c = context.colors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // Live preview card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: AppSpacing.brLg,
            border: Border.all(color: c.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The art of reading',
                style: TextStyle(
                  color: c.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Preview',
                style: AppType.reading(
                  fontSize: p.fontSize,
                  lineHeight: p.lineHeight,
                  color: c.textPrimary,
                ).copyWith(
                  fontWeight: FontWeight.w600,
                  height: p.lineHeight,
                  fontSize: p.fontSize * 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'StashReader is a calm, focused place to read what matters, save what moves you, and revisit it any time.',
                style: AppType.reading(
                  fontSize: p.fontSize,
                  lineHeight: p.lineHeight,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _SectionLabel('Theme'),
        const SizedBox(height: 8),
        SegmentedControl<ThemeMode>(
          segments: const {
            ThemeMode.light: 'Light',
            ThemeMode.dark: 'Dark',
            ThemeMode.system: 'Auto',
          },
          value: p.themeMode,
          onChanged: (v) => p.setThemeMode(v),
        ),
        const SizedBox(height: 12),
        AnimatedPress(
          onTap: () => p.setSepiaMode(!p.sepiaMode),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: p.sepiaMode ? c.accentMuted : c.surface,
              borderRadius: AppSpacing.brLg,
              border: Border.all(
                color: p.sepiaMode ? c.accent : c.border,
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.coffee_outlined,
                  size: 18,
                  color: p.sepiaMode ? c.accent : c.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sepia mode',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  p.sepiaMode ? 'On' : 'Off',
                  style: TextStyle(
                    color: c.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        _SectionLabel('Typography'),
        const SizedBox(height: 12),
        _LabelRow('Font', '${p.fontSize.toInt()}px · ${p.lineHeight.toStringAsFixed(1)}'),
        SegmentedControl<ReadingFont>(
          segments: const {
            ReadingFont.literata: 'Literata',
            ReadingFont.inter: 'Inter',
            ReadingFont.system: 'System',
          },
          value: p.readingFont,
          onChanged: (v) => p.setReadingFont(v),
        ),
        const SizedBox(height: 16),
        _LabelRow('Size', '${p.fontSize.toInt()}'),
        Slider(
          value: p.fontSize,
          min: 13,
          max: 26,
          divisions: 13,
          onChanged: (v) => p.setFontSize(v),
        ),
        _LabelRow('Line height', p.lineHeight.toStringAsFixed(2)),
        Slider(
          value: p.lineHeight,
          min: 1.2,
          max: 2.2,
          divisions: 10,
          onChanged: (v) => p.setLineHeight(v),
        ),
        const SizedBox(height: 28),
        _SectionLabel('Page'),
        const SizedBox(height: 12),
        _LabelRow('Width', '${p.pageWidth.toInt()}px'),
        Slider(
          value: p.pageWidth,
          min: 520,
          max: 760,
          divisions: 12,
          onChanged: (v) => p.setPageWidth(v),
        ),
        const SizedBox(height: 12),
        SegmentedControl<TextAlign>(
          segments: const {
            TextAlign.left: 'Left',
            TextAlign.justify: 'Justify',
            TextAlign.center: 'Center',
          },
          value: p.textAlign,
          onChanged: (v) => p.setTextAlign(v),
        ),
        const SizedBox(height: 16),
        _ToggleRow(
          title: 'Hyphenation',
          subtitle: 'Break long words at line ends',
          value: p.hyphenation,
          onChanged: (v) => p.setHyphenation(v),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: c.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _LabelRow extends StatelessWidget {
  final String label;
  final String value;
  const _LabelRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: c.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
