import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/folder_drawer.dart';
import '../widgets/note_card.dart';
import '../providers/notes_provider.dart';
import '../providers/folders_provider.dart';

import 'note_editor_screen.dart';
import '../database/daos/folders_dao.dart';
import '../providers/database_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFolderId = ref.watch(currentFolderProvider);
    final allFoldersAsync = ref.watch(allFoldersProvider);
    final notesAsync = ref.watch(notesInFolderProvider(selectedFolderId));

    String title = 'Alle Notizen';
    if (selectedFolderId != null) {
      allFoldersAsync.whenData((folders) {
        try {
          final folder = folders.firstWhere((f) => f.id == selectedFolderId);
          title = folder.name;
        } catch (_) {}
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Suche
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Einstellungen
            },
          ),
        ],
      ),
      drawer: const FolderDrawer(),
      body: notesAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(
              child: Text('Keine Notizen gefunden'),
            );
          }
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return NoteCard(
                note: note,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NoteEditorScreen(note: note),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Fehler: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final folderId = selectedFolderId ?? await ref.read(foldersDaoProvider).ensureDefaultFolder();
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NoteEditorScreen(folderId: folderId),
              ),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
