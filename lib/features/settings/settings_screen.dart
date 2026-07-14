import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/export_service.dart';
import '../../core/services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_provider.dart';
import '../../theme/tokens/app_colors.dart';
import '../../theme/tokens/app_motion.dart';
import '../../theme/tokens/app_spacing.dart';
import '../../widgets/animated_press.dart';
import '../../widgets/dialog_sheet.dart';
import '../../widgets/divider_hairline.dart';
import '../../widgets/library_header.dart';
import '../../widgets/segmented_control.dart';
import '../../widgets/settings_section.dart';
import '../../widgets/toast.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          const LibraryHeader(
            title: 'Settings',
            titleSize: 32,
            subtitle: 'Version 2.0.0',
          ),
          const SizedBox(height: 4),
          _AppearanceSection(themeProv: themeProv),
          const SizedBox(height: 24),
          const _TypographySection(),
          const SizedBox(height: 24),
          const _DataSection(),
          const SizedBox(height: 24),
          const _PluginsSection(),
          const SizedBox(height: 24),
          const _AboutSection(),
        ],
      ),
    );
  }
}

// ─── Appearance ──────────────────────────────────────────────────────────
class _AppearanceSection extends StatelessWidget {
  final ThemeProvider themeProv;
  const _AppearanceSection({required this.themeProv});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SettingsSection(
      title: 'Appearance',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Theme',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              SegmentedControl<ThemeMode>(
                segments: const {
                  ThemeMode.light: 'Light',
                  ThemeMode.dark: 'Dark',
                  ThemeMode.system: 'Auto',
                },
                value: themeProv.themeMode,
                onChanged: themeProv.setThemeMode,
              ),
              const SizedBox(height: 12),
              _ToggleRow(
                title: 'Sepia mode',
                subtitle: 'Warm paper-like background',
                value: themeProv.sepiaMode,
                onChanged: themeProv.setSepiaMode,
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: HairlineDivider(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Accent',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Used for highlights, selections, and the active state.',
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final entry in const [
                    (AccentPreset.indigo, AppColors.accentIndigo,
                        AppColors.accentIndigoDark, 'Indigo'),
                    (AccentPreset.amber, AppColors.accentAmber,
                        AppColors.accentAmberDark, 'Amber'),
                    (AccentPreset.forest, AppColors.accentForest,
                        AppColors.accentForestDark, 'Forest'),
                  ]) ...[
                    _AccentSwatch(
                      preset: entry.$1,
                      light: entry.$2,
                      dark: entry.$3,
                      label: entry.$4,
                      selected: themeProv.accent == entry.$1,
                      onTap: () => themeProv.setAccent(entry.$1),
                    ),
                    const SizedBox(width: 10),
                  ],
                ],
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: HairlineDivider(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Handedness',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Floating buttons on your preferred side for one-thumb reach.',
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              SegmentedControl<HandMode>(
                segments: const {
                  HandMode.right: 'Right',
                  HandMode.left: 'Left',
                },
                value: themeProv.handMode,
                onChanged: themeProv.setHandMode,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  final AccentPreset preset;
  final Color light;
  final Color dark;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _AccentSwatch({
    required this.preset,
    required this.light,
    required this.dark,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? dark : light;
    return AnimatedPress(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: AppMotion.base,
            curve: AppMotion.standard,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppSpacing.brMd,
              border: Border.all(
                color: selected ? c.textPrimary : c.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: selected
                ? Icon(
                    Icons.check,
                    size: 20,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: c.textSecondary,
              fontSize: 11,
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
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

// ─── Typography ──────────────────────────────────────────────────────────
class _TypographySection extends StatelessWidget {
  const _TypographySection();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>();
    return SettingsSection(
      title: 'Typography',
      children: [
        SettingsRow(
          icon: Icons.text_fields,
          title: 'Reading font',
          subtitle: _fontName(p.readingFont),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => _showFontPicker(context, p),
        ),
        SettingsRow(
          icon: Icons.format_size,
          title: 'Font size',
          subtitle: '${p.fontSize.toInt()}px',
          trailing: SizedBox(
            width: 110,
            child: Slider(
              value: p.fontSize,
              min: 13,
              max: 26,
              divisions: 13,
              onChanged: p.setFontSize,
            ),
          ),
        ),
        SettingsRow(
          icon: Icons.format_line_spacing,
          title: 'Line height',
          subtitle: p.lineHeight.toStringAsFixed(2),
          trailing: SizedBox(
            width: 110,
            child: Slider(
              value: p.lineHeight,
              min: 1.2,
              max: 2.2,
              divisions: 10,
              onChanged: p.setLineHeight,
            ),
          ),
        ),
        SettingsRow(
          icon: Icons.format_align_left,
          title: 'Text alignment',
          subtitle: _alignName(p.textAlign),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => _showAlignPicker(context, p),
        ),
        SettingsRow(
          icon: Icons.auto_awesome_motion,
          title: 'Hyphenation',
          subtitle: 'Break long words at line ends',
          trailing: Switch(
            value: p.hyphenation,
            onChanged: p.setHyphenation,
          ),
        ),
      ],
    );
  }

  String _fontName(ReadingFont f) {
    switch (f) {
      case ReadingFont.literata:
        return 'Literata';
      case ReadingFont.inter:
        return 'Inter';
      case ReadingFont.system:
        return 'System default';
    }
  }

  String _alignName(TextAlign a) {
    switch (a) {
      case TextAlign.left:
        return 'Left';
      case TextAlign.justify:
        return 'Justify';
      case TextAlign.center:
        return 'Center';
      case TextAlign.right:
        return 'Right';
      case TextAlign.start:
        return 'Start';
      case TextAlign.end:
        return 'End';
    }
  }

  void _showFontPicker(BuildContext context, ThemeProvider p) {
    StashSheet.show<void>(
      context,
      title: 'Reading font',
      subtitle: 'Choose a face for long-form reading.',
      initialChildSize: 0.45,
      maxChildSize: 0.6,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: SegmentedControl<ReadingFont>(
          segments: const {
            ReadingFont.literata: 'Literata',
            ReadingFont.inter: 'Inter',
            ReadingFont.system: 'System',
          },
          value: p.readingFont,
          onChanged: (v) {
            p.setReadingFont(v);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showAlignPicker(BuildContext context, ThemeProvider p) {
    StashSheet.show<void>(
      context,
      title: 'Text alignment',
      initialChildSize: 0.4,
      maxChildSize: 0.5,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: SegmentedControl<TextAlign>(
          segments: const {
            TextAlign.left: 'Left',
            TextAlign.justify: 'Justify',
            TextAlign.center: 'Center',
          },
          value: p.textAlign,
          onChanged: (v) {
            p.setTextAlign(v);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

// ─── Data ────────────────────────────────────────────────────────────────
class _DataSection extends StatefulWidget {
  const _DataSection();

  @override
  State<_DataSection> createState() => _DataSectionState();
}

class _DataSectionState extends State<_DataSection> {
  bool _importing = false;
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Data',
      footer:
          'All your data lives on this device. Backups are plain JSON you can keep anywhere.',
      children: [
        SettingsRow(
          icon: Icons.file_upload_outlined,
          title: 'Export',
          subtitle: 'Save books & snippets as JSON',
          trailing: _exporting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: _exporting ? null : _export,
        ),
        SettingsRow(
          icon: Icons.file_download_outlined,
          title: 'Import',
          subtitle: 'Restore from a backup file',
          trailing: _importing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: _importing ? null : _import,
        ),
      ],
    );
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final db = context.read<DatabaseService>();
      final svc = ExportService(db);
      await svc.exportToJson();
      if (mounted) {
        StashToast.show(
          context,
          message: 'Backup created',
          icon: Icons.check,
        );
      }
    } catch (e) {
      if (mounted) {
        StashToast.show(
          context,
          message: 'Export failed: $e',
          icon: Icons.error_outline,
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _import() async {
    setState(() => _importing = true);
    try {
      final db = context.read<DatabaseService>();
      final svc = ExportService(db);
      final result = await svc.importFromJson();
      if (mounted) {
        StashToast.show(
          context,
          message: result,
          icon: Icons.check,
        );
      }
    } catch (e) {
      if (mounted) {
        StashToast.show(
          context,
          message: 'Import failed: $e',
          icon: Icons.error_outline,
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }
}

// ─── Plugins (placeholder) ───────────────────────────────────────────────
class _PluginsSection extends StatelessWidget {
  const _PluginsSection();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SettingsSection(
      title: 'Plugins',
      footer:
          'Plugins extend StashReader with new sources, parsers, and exporters. The plugin system is being prepared — a small set of official plugins will land in a future release.',
      children: [
        SettingsRow(
          icon: Icons.extension_outlined,
          title: 'Manage plugins',
          subtitle: 'Browse and enable extensions',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: c.accentMuted,
              borderRadius: AppSpacing.brPill,
            ),
            child: Text(
              'Coming soon',
              style: TextStyle(
                color: c.accent,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
        SettingsRow(
          icon: Icons.code,
          title: 'Plugin SDK',
          subtitle: 'Documentation for authors',
          trailing: const Icon(Icons.chevron_right, size: 18),
        ),
      ],
    );
  }
}

// ─── About ───────────────────────────────────────────────────────────────
class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'About',
      children: [
        SettingsRow(
          icon: Icons.info_outline,
          title: 'StashReader',
          subtitle: 'Version 2.0.0 · build 2.0.0+1',
        ),
        SettingsRow(
          icon: Icons.favorite_outline,
          title: 'A reader and a thinking tool',
          subtitle: 'Local-first. No accounts. No tracking.',
        ),
        SettingsRow(
          icon: Icons.book_outlined,
          title: 'Open source licenses',
          trailing: const Icon(Icons.chevron_right, size: 18),
        ),
      ],
    );
  }
}
