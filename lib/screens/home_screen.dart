import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import '../providers/folders_provider.dart';
import '../providers/notes_provider.dart';
import '../widgets/folder_drawer.dart';
import '../widgets/note_card.dart';
import 'note_editor_screen.dart';
import 'settings_screen.dart';

/// Hauptbildschirm der App
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final currentFolderId = ref.watch(currentFolderProvider);
    final notesAsync = ref.watch(notesInCurrentFolderProvider);
    final foldersAsync = ref.watch(allFoldersProvider);

    // Aktuellen Ordnernamen ermitteln
    final currentFolderName = foldersAsync.when(
      data: (folders) {
        if (currentFolderId == null) return 'Alle Notizen';
        final folder = folders.where((f) => f.id == currentFolderId).firstOrNull;
        return folder?.name ?? 'Notizen';
      },
      loading: () => 'Notizen',
      error: (_, __) => 'Notizen',
    );

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(currentFolderName),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _openSearch,
            tooltip: 'Suchen',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sort',
                child: ListTile(
                  leading: Icon(Icons.sort),
                  title: Text('Sortieren'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Einstellungen'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: const FolderDrawer(),
      body: notesAsync.when(
        data: (notes) => _buildNotesList(notes),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Fehler: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewNote,
        icon: const Icon(Icons.add),
        label: const Text('Neue Notiz'),
      ),
    );
  }

  Widget _buildNotesList(List<Note> notes) {
    if (notes.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: NoteCard(
            note: note,
            onTap: () => _openNote(note),
            onLongPress: () => _showNoteOptions(note),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Notizen',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tippe auf + um eine neue Notiz zu erstellen',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  void _openSearch() {
    // TODO: Implement search
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Suche wird implementiert...')),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'sort':
        _showSortOptions();
        break;
      case 'settings':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
        break;
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Nach Änderungsdatum'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement sorting
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Nach Erstellungsdatum'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('Nach Name'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createNewNote() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(
          folderId: ref.read(currentFolderProvider) ?? 'default',
        ),
      ),
    );
  }

  void _openNote(Note note) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(
          noteId: note.id,
          folderId: note.folderId,
        ),
      ),
    );
  }

  void _showNoteOptions(Note note) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              ),
              title: Text(note.isPinned ? 'Nicht mehr anpinnen' : 'Anpinnen'),
              onTap: () {
                Navigator.pop(context);
                ref.read(notesDaoProvider).togglePin(note.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_move_outlined),
              title: const Text('Verschieben'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show folder picker
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Löschen'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(note);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notiz löschen?'),
        content: const Text(
          'Die Notiz wird in den Papierkorb verschoben.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(notesDaoProvider).moveToTrash(note.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notiz in den Papierkorb verschoben')),
              );
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}
