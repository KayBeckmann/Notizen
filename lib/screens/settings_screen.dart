import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/theme_provider.dart';
import '../widgets/sync/sync_settings.dart';

/// Einstellungen-Bildschirm
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeNotifierProvider);
    final seedColor = ref.watch(seedColorNotifierProvider);
    final useDynamicColor = ref.watch(useDynamicColorNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: ListView(
        children: [
          // Erscheinungsbild
          _buildSectionHeader(context, 'Erscheinungsbild'),

          // Theme-Modus
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Design'),
            subtitle: Text(_getThemeModeText(themeMode)),
            onTap: () => _showThemeModeDialog(context, ref, themeMode),
          ),

          // Dynamic Color
          SwitchListTile(
            secondary: const Icon(Icons.color_lens),
            title: const Text('Dynamic Color'),
            subtitle: const Text('Systemfarben verwenden (Material You)'),
            value: useDynamicColor,
            onChanged: (value) {
              ref.read(useDynamicColorNotifierProvider.notifier).setUseDynamicColor(value);
            },
          ),

          // Akzentfarbe
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Akzentfarbe'),
            subtitle: const Text('Benutzerdefinierte Farbe'),
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: seedColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
            enabled: !useDynamicColor,
            onTap: () => _showColorPicker(context, ref, seedColor),
          ),

          const Divider(),

          // Synchronisation
          const SyncSettingsSection(),

          const Divider(),

          // Über
          _buildSectionHeader(context, 'Über'),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: const Text('0.1.0'),
          ),

          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Quellcode'),
            subtitle: const Text('GitHub'),
            onTap: () {
              // TODO: URL öffnen
            },
          ),

          const Divider(),

          // Unterstützen
          _buildSectionHeader(context, 'Unterstützen'),

          ListTile(
            leading: const Icon(Icons.currency_bitcoin),
            title: const Text('Bitcoin'),
            subtitle: const Text('12QBn6eba71FtAUM4HFmSGgTY9iTPfRKLx'),
            onTap: () {
              // TODO: Kopieren
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bitcoin-Adresse kopiert')),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.coffee),
            title: const Text('Buy Me a Coffee'),
            subtitle: const Text('snuppedelua'),
            onTap: () {
              // TODO: URL öffnen
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Hell';
      case ThemeMode.dark:
        return 'Dunkel';
    }
  }

  void _showThemeModeDialog(
    BuildContext context,
    WidgetRef ref,
    ThemeMode currentMode,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Design'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            return RadioListTile<ThemeMode>(
              title: Text(_getThemeModeText(mode)),
              value: mode,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeNotifierProvider.notifier).setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showColorPicker(
    BuildContext context,
    WidgetRef ref,
    Color currentColor,
  ) {
    Color pickedColor = currentColor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Akzentfarbe wählen'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: currentColor,
            onColorChanged: (color) {
              pickedColor = color;
            },
            availableColors: const [
              Color(0xFF6750A4), // Primary
              Color(0xFFE91E63), // Pink
              Color(0xFF9C27B0), // Purple
              Color(0xFF673AB7), // Deep Purple
              Color(0xFF3F51B5), // Indigo
              Color(0xFF2196F3), // Blue
              Color(0xFF03A9F4), // Light Blue
              Color(0xFF00BCD4), // Cyan
              Color(0xFF009688), // Teal
              Color(0xFF4CAF50), // Green
              Color(0xFF8BC34A), // Light Green
              Color(0xFFCDDC39), // Lime
              Color(0xFFFFEB3B), // Yellow
              Color(0xFFFFC107), // Amber
              Color(0xFFFF9800), // Orange
              Color(0xFFFF5722), // Deep Orange
              Color(0xFF795548), // Brown
              Color(0xFF607D8B), // Blue Grey
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(seedColorNotifierProvider.notifier).setSeedColor(pickedColor);
              Navigator.pop(context);
            },
            child: const Text('Übernehmen'),
          ),
        ],
      ),
    );
  }
}
