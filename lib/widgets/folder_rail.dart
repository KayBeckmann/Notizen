import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/folders_provider.dart';

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
    final destinations = <NavigationRailDestination>[
      const NavigationRailDestination(
        icon: Icon(Icons.notes_outlined),
        selectedIcon: Icon(Icons.notes),
        label: Text('Alle'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.push_pin_outlined),
        selectedIcon: Icon(Icons.push_pin),
        label: Text('Angepinnt'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.archive_outlined),
        selectedIcon: Icon(Icons.archive),
        label: Text('Archiv'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.delete_outlined),
        selectedIcon: Icon(Icons.delete),
        label: Text('Papierkorb'),
      ),
      // User-Ordner
      ...folders.where((f) => f.parentId == null).map((folder) {
        return NavigationRailDestination(
          icon: Icon(Icons.folder_outlined, color: Color(folder.color)),
          selectedIcon: Icon(Icons.folder, color: Color(folder.color)),
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
