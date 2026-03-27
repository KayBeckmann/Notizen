import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/folders_provider.dart';
import '../providers/tags_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/database_provider.dart';
import '../database/database.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

class FolderDrawerContent extends ConsumerWidget {
  const FolderDrawerContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rootFoldersAsync = ref.watch(rootFoldersProvider);
    final allTagsAsync = ref.watch(allTagsProvider);
    final currentFolderId = ref.watch(currentFolderProvider);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notizen',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'Deine Gedanken, überall.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.notes),
          title: const Text('Alle Notizen'),
          selected: currentFolderId == null,
          onTap: () {
            ref.read(currentFolderProvider.notifier).select(null);
            if (Scaffold.of(context).hasDrawer) Navigator.pop(context);
          },
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('Ordner', style: Theme.of(context).textTheme.labelLarge),
        ),
        rootFoldersAsync.when(
          data: (folders) => Column(
            children: folders
                .map((folder) => ListTile(
                      leading: Icon(
                        Icons.folder,
                        color: Color(folder.color),
                      ),
                      title: Text(folder.name),
                      selected: currentFolderId == folder.id,
                      onTap: () {
                        ref.read(currentFolderProvider.notifier).select(folder.id);
                        if (Scaffold.of(context).hasDrawer) Navigator.pop(context);
                      },
                    ))
                .toList(),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => ListTile(title: Text('Fehler: $err')),
        ),
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('Neuer Ordner'),
          onTap: () async {
            final nameController = TextEditingController();
            final name = await showDialog<String>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Neuer Ordner'),
                content: TextField(
                  controller: nameController,
                  decoration: const InputDecoration(hintText: 'Name'),
                  autofocus: true,
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
                  TextButton(onPressed: () => Navigator.pop(context, nameController.text), child: const Text('Erstellen')),
                ],
              ),
            );

            if (name != null && name.isNotEmpty) {
              await ref.read(foldersDaoProvider).createFolder(FoldersCompanion.insert(
                    id: const Uuid().v4(),
                    name: name,
                    color: Colors.blue.value,
                  ));
            }
          },
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('Tags', style: Theme.of(context).textTheme.labelLarge),
        ),
        allTagsAsync.when(
          data: (tags) => Column(
            children: tags
                .map((tag) => ListTile(
                      leading: Icon(Icons.label, color: Color(tag.color)),
                      title: Text(tag.name),
                      onTap: () {
                        // TODO: Filter nach Tag
                        if (Scaffold.of(context).hasDrawer) Navigator.pop(context);
                      },
                    ))
                .toList(),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => ListTile(title: Text('Fehler: $err')),
        ),
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('Neuer Tag'),
          onTap: () async {
            // TODO: Tag Dialog
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.archive_outlined),
          title: const Text('Archiv'),
          onTap: () {
            // TODO: Archiv öffnen
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: const Text('Papierkorb'),
          onTap: () {
            // TODO: Papierkorb öffnen
          },
        ),
      ],
    );
  }
}
