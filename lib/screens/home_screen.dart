import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/folder_drawer.dart';
import '../widgets/note_card.dart';
import '../providers/notes_provider.dart';
import '../providers/folders_provider.dart';

import 'note_editor_screen.dart';
import '../database/daos/folders_dao.dart';
import '../providers/database_provider.dart';

import '../widgets/note_type_dialog.dart';
import 'audio_note_screen.dart';
import '../models/enums.dart';

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
                  Widget screen;
                  switch (note.contentType) {
                    case ContentType.audio:
                      screen = AudioNoteScreen(note: note);
                      break;
                    case ContentType.text:
                    default:
                      screen = NoteEditorScreen(note: note);
                      break;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => screen),
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
          if (!context.mounted) return;

          final type = await showDialog<ContentType>(
            context: context,
            builder: (context) => const NoteTypeDialog(),
          );

          if (type == null || !context.mounted) return;

          Widget screen;
          switch (type) {
            case ContentType.audio:
              screen = AudioNoteScreen(folderId: folderId);
              break;
            case ContentType.text:
            default:
              screen = NoteEditorScreen(folderId: folderId);
              break;
          }

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
