import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/folders_provider.dart';
import '../providers/notes_provider.dart';
import 'folder_dialog.dart';

/// NavigationRail für Tablet-Ansicht
class FolderRail extends ConsumerWidget {
  const FolderRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(allFoldersProvider);
    final currentFolderId = ref.watch(currentFolderProvider);

    return foldersAsync.when(
      data: (folders) => _buildRail(context, ref, folders, currentFolderId),
      loading: () => const SizedBox(width: 80),
      error: (_, __) => const SizedBox(width: 80),
    );
  }

  Widget _buildRail(
    BuildContext context,
    WidgetRef ref,
    List<Folder> folders,
    String? currentFolderId,
  ) {
    final pinnedCount = ref.watch(pinnedCountProvider).valueOrNull ?? 0;
    final archivedCount = ref.watch(archivedCountProvider).valueOrNull ?? 0;
    final trashedCount = ref.watch(trashedCountProvider).valueOrNull ?? 0;
    final allNotesAsync = ref.watch(allNotesProvider);
    final allNotesCount = allNotesAsync.valueOrNull?.length ?? 0;
    final noteCounts = ref.watch(noteCountsByFolderProvider).valueOrNull ?? {};

    final destinations = <NavigationRailDestination>[
      NavigationRailDestination(
        icon: _buildBadgedIcon(Icons.notes_outlined, allNotesCount),
        selectedIcon: _buildBadgedIcon(Icons.notes, allNotesCount),
        label: const Text('Alle'),
      ),
      NavigationRailDestination(
        icon: _buildBadgedIcon(Icons.push_pin_outlined, pinnedCount),
        selectedIcon: _buildBadgedIcon(Icons.push_pin, pinnedCount),
        label: const Text('Angepinnt'),
      ),
      NavigationRailDestination(
        icon: _buildBadgedIcon(Icons.archive_outlined, archivedCount),
        selectedIcon: _buildBadgedIcon(Icons.archive, archivedCount),
        label: const Text('Archiv'),
      ),
      NavigationRailDestination(
        icon: _buildBadgedIcon(Icons.delete_outlined, trashedCount),
        selectedIcon: _buildBadgedIcon(Icons.delete, trashedCount),
        label: const Text('Papierkorb'),
      ),
      // User-Ordner
      ...folders.where((f) => f.parentId == null).map((folder) {
        final icon = getIconFromName(folder.icon);
        final count = noteCounts[folder.id] ?? 0;
        return NavigationRailDestination(
          icon: _buildBadgedIcon(
            icon == Icons.folder ? Icons.folder_outlined : icon,
            count,
            color: Color(folder.color),
          ),
          selectedIcon: _buildBadgedIcon(icon, count, color: Color(folder.color)),
          label: Text(
            folder.name,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }),
    ];

    final selectedIndex = _getSelectedIndex(folders, currentFolderId);

    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        _onDestinationSelected(ref, index, folders);
      },
      labelType: NavigationRailLabelType.all,
      leading: FloatingActionButton(
        heroTag: 'rail_fab',
        onPressed: () {
          // TODO: Create new note
        },
        child: const Icon(Icons.add),
      ),
      destinations: destinations,
    );
  }

  int _getSelectedIndex(List<Folder> folders, String? currentFolderId) {
    if (currentFolderId == null) return 0;
    if (currentFolderId == '_pinned') return 1;
    if (currentFolderId == '_archived') return 2;
    if (currentFolderId == '_trash') return 3;

    final rootFolders = folders.where((f) => f.parentId == null).toList();
    final index = rootFolders.indexWhere((f) => f.id == currentFolderId);
    return index >= 0 ? index + 4 : 0;
  }

  Widget _buildBadgedIcon(IconData icon, int count, {Color? color}) {
    if (count == 0) {
      return Icon(icon, color: color);
    }
    return Badge(
      label: Text(count.toString()),
      child: Icon(icon, color: color),
    );
  }

  void _onDestinationSelected(
    WidgetRef ref,
    int index,
    List<Folder> folders,
  ) {
    final notifier = ref.read(currentFolderProvider.notifier);
    final rootFolders = folders.where((f) => f.parentId == null).toList();

    switch (index) {
      case 0:
        notifier.select(null);
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
        final folderIndex = index - 4;
        if (folderIndex < rootFolders.length) {
          notifier.select(rootFolders[folderIndex].id);
        }
    }
  }
}
