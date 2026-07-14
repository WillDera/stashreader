import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/export_service.dart';
import '../../core/services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _fontOptions = ['System', 'Serif', 'Mono'];
  static const _googleFontOptions = [null, 'Roboto', 'Merriweather', 'Lora', 'Playfair Display'];
  bool _importing = false;
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Settings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),

            // Theme
            _sectionHeader(context, 'Appearance'),
            _buildThemeSection(context, themeProv, borderColor),

            const SizedBox(height: 16),

            // Font
            _sectionHeader(context, 'Font'),
            _buildFontSection(context, themeProv, borderColor),

            const SizedBox(height: 16),

            // Reader settings
            _sectionHeader(context, 'Reader'),
            _buildReaderSection(context, themeProv, borderColor),

            const SizedBox(height: 16),

            // Data
            _sectionHeader(context, 'Data'),
            _buildDataSection(context, borderColor),

            const SizedBox(height: 24),

            // About
            _sectionHeader(context, 'About'),
            _buildAboutSection(context, borderColor),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context, ThemeProvider themeProv, Color borderColor) {
    return _sectionContainer(borderColor, [
      RadioGroup<ThemeMode>(
        groupValue: themeProv.themeMode,
        onChanged: (v) => themeProv.setThemeMode(v!),
        child: Column(
          children: [
            _radioRow('Light', ThemeMode.light, themeProv: themeProv),
            _divider(borderColor),
            _radioRow('Dark', ThemeMode.dark, themeProv: themeProv),
            _divider(borderColor),
            _radioRow('System', ThemeMode.system, themeProv: themeProv),
          ],
        ),
      ),
      _divider(borderColor),
      _switchRow(
        title: 'Sepia',
        subtitle: 'Warm paper-like background',
        value: themeProv.sepiaMode,
        onChanged: (v) => themeProv.setSepiaMode(v),
      ),
    ]);
  }

  Widget _buildFontSection(BuildContext context, ThemeProvider themeProv, Color borderColor) {
    return _sectionContainer(borderColor, [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('System Font', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
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
            Text('Google Fonts', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: _googleFontOptions.map((font) {
                final selected = themeProv.googleFont == font;
                return ChoiceChip(
                  label: Text(font ?? 'None'),
                  selected: selected,
                  onSelected: (_) => themeProv.setGoogleFont(font),
                  selectedColor: AppTheme.accent.withValues(alpha: 0.2),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildReaderSection(BuildContext context, ThemeProvider themeProv, Color borderColor) {
    return _sectionContainer(borderColor, [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Font Size', style: Theme.of(context).textTheme.labelLarge),
                const Spacer(),
                Text('${themeProv.fontSize.toInt()}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            Slider(
              value: themeProv.fontSize,
              min: 12,
              max: 28,
              divisions: 16,
              activeColor: AppTheme.accent,
              onChanged: (v) => themeProv.setFontSize(v),
            ),
            const SizedBox(height: 8),
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
          ],
        ),
      ),
    ]);
  }

  Widget _buildDataSection(BuildContext context, Color borderColor) {
    return _sectionContainer(borderColor, [
      _actionRow(
        icon: Icons.file_upload,
        title: 'Export Data',
        subtitle: 'Save books & snippets as JSON',
        trailing: _exporting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
        onTap: _exporting ? null : _exportData,
      ),
      _divider(borderColor),
      _actionRow(
        icon: Icons.file_download,
        title: 'Import Data',
        subtitle: 'Restore from backup',
        trailing: _importing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
        onTap: _importing ? null : _importData,
      ),
    ]);
  }

  Widget _buildAboutSection(BuildContext context, Color borderColor) {
    return _sectionContainer(borderColor, [
      _infoRow(icon: Icons.info_outline, title: 'StashReader', subtitle: 'Version 1.3.0'),
      _divider(borderColor),
      _infoRow(
        icon: Icons.code,
        title: 'Hybrid reader + knowledge snippet manager',
        subtitle: 'Built with Flutter & Drift',
      ),
    ]);
  }

  // === Reusable structural widgets ===

  Widget _sectionContainer(Color borderColor, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _radioRow(String title, ThemeMode value, {required ThemeProvider themeProv}) {
    return GestureDetector(
      onTap: () => themeProv.setThemeMode(value),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.bodyLarge),
            ),
            Radio<ThemeMode>(
              value: value,
              activeColor: AppTheme.accent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchRow({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppTheme.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.accent, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accent, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(Color borderColor) {
    return Container(
      height: 0.5,
      color: borderColor,
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.accent,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }

  Future<void> _exportData() async {
    setState(() => _exporting = true);
    try {
      final db = context.read<DatabaseService>();
      final exportService = ExportService(db);
      await exportService.exportToJson();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _importData() async {
    setState(() => _importing = true);
    try {
      final db = context.read<DatabaseService>();
      final exportService = ExportService(db);
      final result = await exportService.importFromJson();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }
}
