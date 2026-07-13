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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // Theme
          _sectionHeader(context, 'Appearance'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('Light'),
                  value: ThemeMode.light,
                  groupValue: themeProv.themeMode,
                  activeColor: AppTheme.accent,
                  onChanged: (v) => themeProv.setThemeMode(v!),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Dark'),
                  value: ThemeMode.dark,
                  groupValue: themeProv.themeMode,
                  activeColor: AppTheme.accent,
                  onChanged: (v) => themeProv.setThemeMode(v!),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('System'),
                  value: ThemeMode.system,
                  groupValue: themeProv.themeMode,
                  activeColor: AppTheme.accent,
                  onChanged: (v) => themeProv.setThemeMode(v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Font
          _sectionHeader(context, 'Font'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('System Font', style: Theme.of(context).textTheme.labelLarge),
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
                  const SizedBox(height: 12),
                  Text('Google Fonts', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
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
          ),
          const SizedBox(height: 16),

          // Reader settings
          _sectionHeader(context, 'Reader'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Font size
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Data
          _sectionHeader(context, 'Data'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_upload, color: AppTheme.accent),
                  title: const Text('Export Data'),
                  subtitle: const Text('Save books & snippets as JSON'),
                  trailing: _exporting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _exporting ? null : _exportData,
                ),
                const Divider(height: 0, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.file_download, color: AppTheme.accent),
                  title: const Text('Import Data'),
                  subtitle: const Text('Restore from backup'),
                  trailing: _importing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _importing ? null : _importData,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // About
          _sectionHeader(context, 'About'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline, color: AppTheme.accent),
                  title: const Text('StashReader'),
                  subtitle: const Text('Version 1.0.0'),
                ),
                const Divider(height: 0, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.code, color: AppTheme.accent),
                  title: const Text('Hybrid reader + knowledge snippet manager'),
                  subtitle: const Text('Built with Flutter & Drift'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.accent,
              fontWeight: FontWeight.w600,
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
