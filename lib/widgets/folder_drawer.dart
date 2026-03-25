import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import '../providers/folders_provider.dart';
import '../providers/notes_provider.dart';
import 'folder_dialog.dart';
import 'tag_list.dart';

/// Seitenleiste mit Ordner-Navigation
class FolderDrawer extends ConsumerWidget {
  const FolderDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(allFoldersProvider);
    final currentFolderId = ref.watch(currentFolderProvider);

    // Sichere Abfrage der Zähler mit Fallback auf 0
    int pinnedCount = 0;
    int archivedCount = 0;
    int trashedCount = 0;
    int allNotesCount = 0;

    try {
      pinnedCount = ref.watch(pinnedCountProvider).valueOrNull ?? 0;
      archivedCount = ref.watch(archivedCountProvider).valueOrNull ?? 0;
      trashedCount = ref.watch(trashedCountProvider).valueOrNull ?? 0;
      final allNotesAsync = ref.watch(allNotesProvider);
      allNotesCount = allNotesAsync.valueOrNull?.length ?? 0;
    } catch (_) {
      // Ignoriere Fehler beim Laden der Zähler
    }

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
        NavigationDrawerDestination(
          icon: const Icon(Icons.notes_outlined),
          selectedIcon: const Icon(Icons.notes),
          label: _buildLabelWithCount('Alle Notizen', allNotesCount),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.push_pin_outlined),
          selectedIcon: const Icon(Icons.push_pin),
          label: _buildLabelWithCount('Angepinnt', pinnedCount),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.archive_outlined),
          selectedIcon: const Icon(Icons.archive),
          label: _buildLabelWithCount('Archiv', archivedCount),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.delete_outlined),
          selectedIcon: const Icon(Icons.delete),
          label: _buildLabelWithCount('Papierkorb', trashedCount),
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

        // Benutzer-Ordner als ListTiles
        ...foldersAsync.when(
          data: (folders) {
            Map<String, int> noteCounts = {};
            try {
              noteCounts = ref.watch(noteCountsByFolderProvider).valueOrNull ?? {};
            } catch (_) {}

            final rootFolders = folders.where((f) => f.parentId == null).toList();
            if (rootFolders.isEmpty) {
              return [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                  child: Text(
                    'Keine Ordner vorhanden',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ];
            }

            return rootFolders.map<Widget>((folder) {
              final icon = getIconFromName(folder.icon);
              final count = noteCounts[folder.id] ?? 0;
              final isSelected = currentFolderId == folder.id;

              return ListTile(
                leading: Icon(
                  icon == Icons.folder ? Icons.folder_outlined : icon,
                  color: Color(folder.color),
                ),
                title: Text(folder.name),
                trailing: count > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count.toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      )
                    : null,
                selected: isSelected,
                onTap: () {
                  ref.read(currentFolderProvider.notifier).select(folder.id);
                  Navigator.of(context).pop();
                },
                onLongPress: () => _showFolderOptions(context, ref, folder),
              );
            }).toList();
          },
          loading: () => [const Center(child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ))],
          error: (e, _) => [Center(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Fehler: $e'),
          ))],
        ),

        const Divider(indent: 28, endIndent: 28),

        // Tags
        const TagDrawerSection(),
      ],
    );
  }

  Widget _buildLabelWithCount(String label, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (count > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }

  int? _getSelectedIndex(
    AsyncValue<List<Folder>> foldersAsync,
    String? currentFolderId,
  ) {
    // Nur die 4 speziellen Ordner sind NavigationDrawerDestinations
    if (currentFolderId == null) return 0;
    if (currentFolderId == '_pinned') return 1;
    if (currentFolderId == '_archived') return 2;
    if (currentFolderId == '_trash') return 3;

    // Wenn ein User-Ordner ausgewählt ist, kein Index
    return null;
  }

  void _onDestinationSelected(
    BuildContext context,
    WidgetRef ref,
    int index,
    AsyncValue<List<Folder>> foldersAsync,
  ) {
    final notifier = ref.read(currentFolderProvider.notifier);

    // Nur 4 spezielle Ordner als NavigationDrawerDestinations
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
    }

    Navigator.of(context).pop();
  }

  void _showCreateFolderDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const CreateFolderDialog(),
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
              title: const Text('Bearbeiten'),
              onTap: () {
                Navigator.pop(context);
                _showEditFolderDialog(context, folder);
              },
            ),
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: const Text('Unterordner erstellen'),
              onTap: () {
                Navigator.pop(context);
                _showCreateSubfolderDialog(context, folder.id);
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

  void _showEditFolderDialog(BuildContext context, Folder folder) {
    showDialog(
      context: context,
      builder: (context) => EditFolderDialog(folder: folder),
    );
  }

  void _showCreateSubfolderDialog(BuildContext context, String parentId) {
    showDialog(
      context: context,
      builder: (context) => CreateFolderDialog(parentId: parentId),
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
