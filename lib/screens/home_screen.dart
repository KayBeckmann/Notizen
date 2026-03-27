import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/folder_drawer.dart';
import '../widgets/note_card.dart';
import '../widgets/adaptive_scaffold.dart';
import '../providers/notes_provider.dart';
import '../providers/folders_provider.dart';

import 'note_editor_screen.dart';
import 'settings_screen.dart';
import '../database/daos/folders_dao.dart';
import '../providers/database_provider.dart';

import '../widgets/note_type_dialog.dart';
import 'audio_note_screen.dart';
import '../models/enums.dart';

import 'drawing_note_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

    return AdaptiveScaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Suchen...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {});
                },
              )
            : Text(title),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchController.clear();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      drawer: const FolderDrawerContent(),
      body: notesAsync.when(
        data: (notes) {
          final filteredNotes = _searchController.text.isEmpty
              ? notes
              : notes
                  .where((n) =>
                      n.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                      n.content.toLowerCase().contains(_searchController.text.toLowerCase()))
                  .toList();

          if (filteredNotes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_alt_outlined, size: 64, color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    _isSearching ? 'Keine Notizen gefunden' : 'In diesem Ordner sind keine Notizen',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.outline),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: MediaQuery.of(context).size.width >= 900 ? 400 : 600,
              mainAxisExtent: 180,
            ),
            itemCount: filteredNotes.length,
            itemBuilder: (context, index) {
              final note = filteredNotes[index];
              return NoteCard(
                note: note,
                onTap: () {
                  Widget screen;
                  switch (note.contentType) {
                    case ContentType.audio:
                      screen = AudioNoteScreen(note: note);
                      break;
                    case ContentType.drawing:
                      screen = DrawingNoteScreen(note: note);
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
      floatingActionButton: FloatingActionButton.extended(
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
            case ContentType.drawing:
              screen = DrawingNoteScreen(folderId: folderId);
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
        label: const Text('Neue Notiz'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
