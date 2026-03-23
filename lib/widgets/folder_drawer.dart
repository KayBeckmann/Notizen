import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import '../providers/folders_provider.dart';

/// Seitenleiste mit Ordner-Navigation
class FolderDrawer extends ConsumerWidget {
  const FolderDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(allFoldersProvider);
    final currentFolderId = ref.watch(currentFolderProvider);

    return NavigationDrawer(
      selectedIndex: _getSelectedIndex(foldersAsync, currentFolderId),
      onDestinationSelected: (index) => _onDestinationSelected(
        context,
        ref,
        index,
        foldersAsync,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
          child: Text(
            'Notizen',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),

        // Spezielle Ordner
        const NavigationDrawerDestination(
          icon: Icon(Icons.notes_outlined),
          selectedIcon: Icon(Icons.notes),
          label: Text('Alle Notizen'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.push_pin_outlined),
          selectedIcon: Icon(Icons.push_pin),
          label: Text('Angepinnt'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.archive_outlined),
          selectedIcon: Icon(Icons.archive),
          label: Text('Archiv'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.delete_outlined),
          selectedIcon: Icon(Icons.delete),
          label: Text('Papierkorb'),
        ),

        const Divider(indent: 28, endIndent: 28),

        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ordner',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              IconButton(
                icon: const Icon(Icons.create_new_folder_outlined, size: 20),
                onPressed: () => _showCreateFolderDialog(context, ref),
                tooltip: 'Neuer Ordner',
              ),
            ],
          ),
        ),

        // Benutzer-Ordner
        foldersAsync.when(
          data: (folders) => _buildFolderList(context, ref, folders, currentFolderId),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Fehler: $e')),
        ),
      ],
    );
  }

  int _getSelectedIndex(
    AsyncValue<List<Folder>> foldersAsync,
    String? currentFolderId,
  ) {
    if (currentFolderId == null) return 0;
    if (currentFolderId == '_pinned') return 1;
    if (currentFolderId == '_archived') return 2;
    if (currentFolderId == '_trash') return 3;

    return foldersAsync.when(
      data: (folders) {
        final index = folders.indexWhere((f) => f.id == currentFolderId);
        return index >= 0 ? index + 4 : 0;
      },
      loading: () => 0,
      error: (_, __) => 0,
    );
  }

  void _onDestinationSelected(
    BuildContext context,
    WidgetRef ref,
    int index,
    AsyncValue<List<Folder>> foldersAsync,
  ) {
    final notifier = ref.read(currentFolderProvider.notifier);

    switch (index) {
      case 0:
        notifier.select(null); // Alle Notizen
        break;
      case 1:
        notifier.select('_pinned');
        break;
      case 2:
        notifier.select('_archived');
        break;
      case 3:
        notifier.select('_trash');
        break;
      default:
        foldersAsync.whenData((folders) {
          final folderIndex = index - 4;
          if (folderIndex < folders.length) {
            notifier.select(folders[folderIndex].id);
          }
        });
    }

    Navigator.of(context).pop();
  }

  Widget _buildFolderList(
    BuildContext context,
    WidgetRef ref,
    List<Folder> folders,
    String? currentFolderId,
  ) {
    // Nur Root-Ordner anzeigen
    final rootFolders = folders.where((f) => f.parentId == null).toList();

    return Column(
      children: rootFolders.map((folder) {
        return _FolderTile(
          folder: folder,
          allFolders: folders,
          isSelected: currentFolderId == folder.id,
          onTap: () {
            ref.read(currentFolderProvider.notifier).select(folder.id);
            Navigator.of(context).pop();
          },
          onLongPress: () => _showFolderOptions(context, ref, folder),
        );
      }).toList(),
    );
  }

  void _showCreateFolderDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Neuer Ordner'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Ordnername',
            hintText: 'z.B. Arbeit',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                _createFolder(ref, name);
                Navigator.pop(context);
              }
            },
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );
  }

  void _createFolder(WidgetRef ref, String name) {
    final now = DateTime.now();
    ref.read(foldersDaoProvider).createFolder(
          FoldersCompanion.insert(
            id: const Uuid().v4(),
            name: name,
            color: 0xFF6750A4,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  void _showFolderOptions(BuildContext context, WidgetRef ref, Folder folder) {
    if (folder.id == 'default') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Standard-Ordner kann nicht geändert werden')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Umbenennen'),
              onTap: () {
                Navigator.pop(context);
                _showRenameFolderDialog(context, ref, folder);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Löschen'),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteFolder(context, ref, folder);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameFolderDialog(
    BuildContext context,
    WidgetRef ref,
    Folder folder,
  ) {
    final controller = TextEditingController(text: folder.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ordner umbenennen'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Ordnername',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(foldersDaoProvider).updateFolder(
                      folder.copyWith(
                        name: name,
                        updatedAt: DateTime.now(),
                      ),
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFolder(BuildContext context, WidgetRef ref, Folder folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ordner löschen?'),
        content: const Text(
          'Der Ordner und alle enthaltenen Notizen werden gelöscht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(foldersDaoProvider).deleteFolder(folder.id);
              ref.read(currentFolderProvider.notifier).select('default');
              Navigator.pop(context);
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}

/// Einzelner Ordner-Eintrag mit optionaler Verschachtelung
class _FolderTile extends StatelessWidget {
  final Folder folder;
  final List<Folder> allFolders;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final int depth;

  const _FolderTile({
    required this.folder,
    required this.allFolders,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    this.depth = 0,
  });

  @override
  Widget build(BuildContext context) {
    final children = allFolders.where((f) => f.parentId == folder.id).toList();
    final hasChildren = children.isNotEmpty;

    return Column(
      children: [
        NavigationDrawerDestination(
          icon: Icon(
            hasChildren ? Icons.folder_outlined : Icons.folder_outlined,
            color: Color(folder.color),
          ),
          selectedIcon: Icon(
            Icons.folder,
            color: Color(folder.color),
          ),
          label: Text(folder.name),
        ),
        // Kinder-Ordner (eingerückt)
        if (hasChildren)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              children: children.map((child) {
                return _FolderTile(
                  folder: child,
                  allFolders: allFolders,
                  isSelected: false,
                  onTap: onTap,
                  onLongPress: onLongPress,
                  depth: depth + 1,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
