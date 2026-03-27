import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../constants/app_constants.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeNotifierProvider);
    final seedColor = ref.watch(seedColorNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Erscheinungsbild', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
          ),
          ListTile(
            title: const Text('Theme-Modus'),
            subtitle: Text(_themeModeName(themeMode)),
            leading: const Icon(Icons.brightness_medium),
            onTap: () async {
              final mode = await showDialog<ThemeMode>(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text('Theme-Modus wählen'),
                  children: [
                    RadioListTile<ThemeMode>(
                      title: const Text('System'),
                      value: ThemeMode.system,
                      groupValue: themeMode,
                      onChanged: (v) => Navigator.pop(context, v),
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Hell'),
                      value: ThemeMode.light,
                      groupValue: themeMode,
                      onChanged: (v) => Navigator.pop(context, v),
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Dunkel'),
                      value: ThemeMode.dark,
                      groupValue: themeMode,
                      onChanged: (v) => Navigator.pop(context, v),
                    ),
                  ],
                ),
              );
              if (mode != null) {
                ref.read(themeModeNotifierProvider.notifier).setThemeMode(mode);
              }
            },
          ),
          ListTile(
            title: const Text('Akzentfarbe'),
            subtitle: const Text('Wähle eine Farbe für die App'),
            leading: Icon(Icons.color_lens, color: seedColor),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Farbe wählen'),
                  content: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.folderColors.map((color) {
                      return InkWell(
                        onTap: () {
                          ref.read(seedColorNotifierProvider.notifier).setSeedColor(color);
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: seedColor == color ? Colors.black : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: seedColor == color ? const Icon(Icons.check, color: Colors.white) : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Über', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
          ),
          const ListTile(
            title: Text('Version'),
            subtitle: Text('1.0.0 (Rebuild)'),
            leading: Icon(Icons.info_outline),
          ),
          ListTile(
            title: const Text('Lizenzen'),
            leading: const Icon(Icons.description_outlined),
            onTap: () => showLicensePage(context: context),
          ),
        ],
      ),
    );
  }

  String _themeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System-Standard';
      case ThemeMode.light:
        return 'Hell';
      case ThemeMode.dark:
        return 'Dunkel';
    }
  }
}
