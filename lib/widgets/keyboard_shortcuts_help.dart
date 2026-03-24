import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dialog mit Keyboard-Shortcuts-Hilfe
class KeyboardShortcutsHelpDialog extends StatelessWidget {
  const KeyboardShortcutsHelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.keyboard, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Tastenkombinationen'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShortcutSection(
                title: 'Navigation',
                shortcuts: const [
                  _ShortcutItem('Ctrl + N', 'Neue Notiz'),
                  _ShortcutItem('Ctrl + F', 'Suche'),
                  _ShortcutItem('Ctrl + ,', 'Einstellungen'),
                  _ShortcutItem('Escape', 'Zurück / Schließen'),
                ],
              ),
              const Divider(),
              _ShortcutSection(
                title: 'Editor',
                shortcuts: const [
                  _ShortcutItem('Ctrl + S', 'Speichern'),
                  _ShortcutItem('Ctrl + B', 'Fett'),
                  _ShortcutItem('Ctrl + I', 'Kursiv'),
                  _ShortcutItem('Ctrl + Z', 'Rückgängig'),
                  _ShortcutItem('Ctrl + Y', 'Wiederholen'),
                  _ShortcutItem('Ctrl + 1/2/3', 'Überschrift 1/2/3'),
                ],
              ),
              const Divider(),
              _ShortcutSection(
                title: 'Notizliste',
                shortcuts: const [
                  _ShortcutItem('Delete', 'Notiz löschen'),
                  _ShortcutItem('F2', 'Umbenennen'),
                  _ShortcutItem('Enter', 'Notiz öffnen'),
                ],
              ),
              const Divider(),
              _ShortcutSection(
                title: 'Zeichnung',
                shortcuts: const [
                  _ShortcutItem('Ctrl + Z', 'Rückgängig'),
                  _ShortcutItem('Ctrl + Y', 'Wiederholen'),
                  _ShortcutItem('Ctrl + S', 'Speichern'),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Schließen'),
        ),
      ],
    );
  }
}

class _ShortcutSection extends StatelessWidget {
  final String title;
  final List<_ShortcutItem> shortcuts;

  const _ShortcutSection({
    required this.title,
    required this.shortcuts,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        ...shortcuts,
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ShortcutItem extends StatelessWidget {
  final String keys;
  final String description;

  const _ShortcutItem(this.keys, this.description);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Text(
              keys,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(description),
        ],
      ),
    );
  }
}

/// Zeigt den Shortcuts-Dialog an
void showKeyboardShortcutsHelp(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const KeyboardShortcutsHelpDialog(),
  );
}

/// Global Keyboard-Shortcuts Intent
class NewNoteIntent extends Intent {
  const NewNoteIntent();
}

class SearchIntent extends Intent {
  const SearchIntent();
}

class SettingsIntent extends Intent {
  const SettingsIntent();
}

class DeleteIntent extends Intent {
  const DeleteIntent();
}

class RenameIntent extends Intent {
  const RenameIntent();
}

class HelpIntent extends Intent {
  const HelpIntent();
}

/// Global Shortcuts für die App
class AppShortcuts extends StatelessWidget {
  final Widget child;
  final VoidCallback? onNewNote;
  final VoidCallback? onSearch;
  final VoidCallback? onSettings;
  final VoidCallback? onDelete;
  final VoidCallback? onRename;
  final VoidCallback? onHelp;

  const AppShortcuts({
    super.key,
    required this.child,
    this.onNewNote,
    this.onSearch,
    this.onSettings,
    this.onDelete,
    this.onRename,
    this.onHelp,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyN, control: true): NewNoteIntent(),
        SingleActivator(LogicalKeyboardKey.keyF, control: true): SearchIntent(),
        SingleActivator(LogicalKeyboardKey.comma, control: true): SettingsIntent(),
        SingleActivator(LogicalKeyboardKey.delete): DeleteIntent(),
        SingleActivator(LogicalKeyboardKey.f2): RenameIntent(),
        SingleActivator(LogicalKeyboardKey.f1): HelpIntent(),
      },
      child: Actions(
        actions: {
          NewNoteIntent: CallbackAction<NewNoteIntent>(
            onInvoke: (_) {
              onNewNote?.call();
              return null;
            },
          ),
          SearchIntent: CallbackAction<SearchIntent>(
            onInvoke: (_) {
              onSearch?.call();
              return null;
            },
          ),
          SettingsIntent: CallbackAction<SettingsIntent>(
            onInvoke: (_) {
              onSettings?.call();
              return null;
            },
          ),
          DeleteIntent: CallbackAction<DeleteIntent>(
            onInvoke: (_) {
              onDelete?.call();
              return null;
            },
          ),
          RenameIntent: CallbackAction<RenameIntent>(
            onInvoke: (_) {
              onRename?.call();
              return null;
            },
          ),
          HelpIntent: CallbackAction<HelpIntent>(
            onInvoke: (_) {
              onHelp?.call();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}
