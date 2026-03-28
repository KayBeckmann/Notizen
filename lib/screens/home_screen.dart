import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../constants/breakpoints.dart';
import '../models/enums.dart';
import '../database/database.dart';
import '../services/browser_title_service.dart';
import '../providers/database_provider.dart';
import '../providers/folders_provider.dart';
import '../providers/notes_provider.dart' show notesInCurrentFolderProvider, sortOrderProvider, sortDirectionProvider, viewModeProvider, selectionModeProvider, selectedNotesProvider;
import '../widgets/adaptive_scaffold.dart';
import '../widgets/drag_and_drop.dart';
import '../widgets/folder_drawer.dart';
import '../widgets/folder_rail.dart';
import '../widgets/keyboard_shortcuts_help.dart';
import '../widgets/note_card.dart';
import '../widgets/note_type_dialog.dart';
import 'audio_note_screen.dart';
import 'drawing_note_screen.dart';
import 'image_note_screen.dart';
import 'note_editor_screen.dart';
import 'search_screen.dart';
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
    final layoutType = Breakpoints.getLayoutType(context);
    final isSelectionMode = ref.watch(selectionModeProvider);
    final selectedNotes = ref.watch(selectedNotesProvider);

    // Aktuellen Ordnernamen ermitteln
    final currentFolderName = _getFolderName(currentFolderId, foldersAsync);

    // Browser-Tab-Titel aktualisieren (nur Web)
    BrowserTitleService.setFolderTitle(currentFolderName);

    // Nur auf compact (Phone) zeigen wir das Menü-Icon
    final showMenuButton = layoutType == LayoutType.compact;

    // FAB auf allen Layouts zeigen, außer im Selection Mode
    final showFab = !isSelectionMode;

    return AppShortcuts(
      onNewNote: _createNewNote,
      onSearch: _openSearch,
      onSettings: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const SettingsScreen()),
      ),
      onHelp: () => showKeyboardShortcutsHelp(context),
      child: AdaptiveScaffold(
        scaffoldKey: _scaffoldKey,
        appBar: isSelectionMode
            ? _buildSelectionAppBar(selectedNotes.length)
            : AppBar(
                title: Text(currentFolderName),
                leading: showMenuButton
                    ? IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                      )
                    : null,
                automaticallyImplyLeading: false,
                actions: [
                  // View Mode Toggle
                  Consumer(
                    builder: (context, ref, _) {
                      final viewMode = ref.watch(viewModeProvider);
                      return IconButton(
                        icon: Icon(
                          viewMode == ViewMode.list ? Icons.grid_view : Icons.view_list,
                        ),
                        onPressed: () => ref.read(viewModeProvider.notifier).toggle(),
                        tooltip: viewMode == ViewMode.list ? 'Rasteransicht' : 'Listenansicht',
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _openSearch,
                    tooltip: 'Suchen (Ctrl+F)',
                  ),
                  PopupMenuButton<String>(
                    onSelected: _handleMenuAction,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'select',
                        child: ListTile(
                          leading: Icon(Icons.checklist),
                          title: Text('Auswählen'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
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
                      const PopupMenuItem(
                        value: 'shortcuts',
                        child: ListTile(
                          leading: Icon(Icons.keyboard),
                          title: Text('Tastenkürzel'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
        drawer: const FolderDrawer(),
        navigationRail: const FolderRail(),
        permanentDrawer: const FolderDrawer(),
        body: notesAsync.when(
          skipLoadingOnReload: true,
          data: (notes) => _buildNotesList(notes),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Fehler: $error'),
          ),
        ),
        floatingActionButton: showFab
            ? FloatingActionButton.extended(
                onPressed: _createNewNote,
                icon: const Icon(Icons.add),
                label: const Text('Neue Notiz'),
              )
            : null,
      ),
    );
  }

  String _getFolderName(String? folderId, AsyncValue<List<Folder>> foldersAsync) {
    if (folderId == null) return 'Alle Notizen';
    if (folderId == '_pinned') return 'Angepinnt';
    if (folderId == '_archived') return 'Archiv';
    if (folderId == '_trash') return 'Papierkorb';

    return foldersAsync.when(
      data: (folders) {
        final folder = folders.where((f) => f.id == folderId).firstOrNull;
        return folder?.name ?? 'Notizen';
      },
      loading: () => 'Notizen',
      error: (_, __) => 'Notizen',
    );
  }

  Widget _buildNotesList(List<Note> notes) {
    if (notes.isEmpty) {
      return _buildEmptyState();
    }

    // Drag & Drop nur auf Desktop aktivieren, nicht im Selection Mode
    final layoutType = Breakpoints.getLayoutType(context);
    final isSelectionMode = ref.watch(selectionModeProvider);
    final enableDrag = layoutType != LayoutType.compact && !isSelectionMode;
    final viewMode = ref.watch(viewModeProvider);

    if (viewMode == ViewMode.grid) {
      return _buildNotesGrid(notes, enableDrag);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: DraggableNoteCard(
            note: note,
            enabled: enableDrag,
            child: _buildSelectableNoteCard(note, isSelectionMode),
          ),
        );
      },
    );
  }

  Widget _buildSelectableNoteCard(Note note, bool isSelectionMode) {
    if (!isSelectionMode) {
      return GestureDetector(
        onSecondaryTapUp: (_) => _showNoteOptions(note),
        child: NoteCard(
          note: note,
          onTap: () => _openNote(note),
          onLongPress: () {
            ref.read(selectionModeProvider.notifier).enable();
            ref.read(selectedNotesProvider.notifier).select(note.id);
          },
        ),
      );
    }

    final isSelected = ref.watch(selectedNotesProvider).contains(note.id);
    return Stack(
      children: [
        NoteCard(
          note: note,
          onTap: () => ref.read(selectedNotesProvider.notifier).toggle(note.id),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.check,
                size: 16,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Colors.transparent,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesGrid(List<Note> notes, bool enableDrag) {
    // Bestimme Anzahl der Spalten basierend auf Bildschirmbreite
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width < 600 ? 2 : (width < 900 ? 3 : 4);
    final isSelectionMode = ref.watch(selectionModeProvider);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return DraggableNoteCard(
          note: note,
          enabled: enableDrag,
          child: _buildSelectableGridCard(note, isSelectionMode),
        );
      },
    );
  }

  Widget _buildSelectableGridCard(Note note, bool isSelectionMode) {
    if (!isSelectionMode) {
      return GestureDetector(
        onSecondaryTapUp: (_) => _showNoteOptions(note),
        child: _NoteGridCard(
          note: note,
          onTap: () => _openNote(note),
          onLongPress: () {
            ref.read(selectionModeProvider.notifier).enable();
            ref.read(selectedNotesProvider.notifier).select(note.id);
          },
        ),
      );
    }

    final isSelected = ref.watch(selectedNotesProvider).contains(note.id);
    return Stack(
      children: [
        _NoteGridCard(
          note: note,
          onTap: () => ref.read(selectedNotesProvider.notifier).toggle(note.id),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.check,
                size: 16,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Colors.transparent,
              ),
            ),
          ),
        ),
      ],
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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SearchScreen()),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'select':
        ref.read(selectionModeProvider.notifier).enable();
        break;
      case 'sort':
        _showSortOptions();
        break;
      case 'settings':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
        break;
      case 'shortcuts':
        showKeyboardShortcutsHelp(context);
        break;
    }
  }

  PreferredSizeWidget _buildSelectionAppBar(int selectedCount) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _exitSelectionMode,
        tooltip: 'Auswahl beenden',
      ),
      title: Text('$selectedCount ausgewählt'),
      actions: [
        // Alle auswählen
        IconButton(
          icon: const Icon(Icons.select_all),
          onPressed: _selectAll,
          tooltip: 'Alle auswählen',
        ),
        // Bulk-Aktionen nur wenn mindestens eine Notiz ausgewählt
        if (selectedCount > 0) ...[
          IconButton(
            icon: const Icon(Icons.drive_file_move_outlined),
            onPressed: _bulkMove,
            tooltip: 'Verschieben',
          ),
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            onPressed: _bulkArchive,
            tooltip: 'Archivieren',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _bulkDelete,
            tooltip: 'Löschen',
          ),
          PopupMenuButton<String>(
            onSelected: _handleBulkAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pin',
                child: ListTile(
                  leading: Icon(Icons.push_pin_outlined),
                  title: Text('Anpinnen'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'unpin',
                child: ListTile(
                  leading: Icon(Icons.push_pin),
                  title: Text('Nicht mehr anpinnen'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'tags',
                child: ListTile(
                  leading: Icon(Icons.label_outline),
                  title: Text('Tags bearbeiten'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _exitSelectionMode() {
    ref.read(selectionModeProvider.notifier).disable();
    ref.read(selectedNotesProvider.notifier).clear();
  }

  void _selectAll() {
    final notes = ref.read(notesInCurrentFolderProvider).valueOrNull ?? [];
    ref.read(selectedNotesProvider.notifier).selectAll(notes.map((n) => n.id).toList());
  }

  void _handleBulkAction(String action) {
    switch (action) {
      case 'pin':
        _bulkPin(true);
        break;
      case 'unpin':
        _bulkPin(false);
        break;
      case 'tags':
        _bulkEditTags();
        break;
    }
  }

  Future<void> _bulkMove() async {
    final selectedIds = ref.read(selectedNotesProvider);
    if (selectedIds.isEmpty) return;

    final folders = await ref.read(allFoldersProvider.future);
    if (!mounted) return;

    final folderId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('In Ordner verschieben'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return ListTile(
                leading: Icon(Icons.folder, color: Color(folder.color)),
                title: Text(folder.name),
                onTap: () => Navigator.pop(context, folder.id),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
        ],
      ),
    );

    if (folderId != null) {
      final notesDao = ref.read(notesDaoProvider);
      for (final noteId in selectedIds) {
        await notesDao.moveNote(noteId, folderId);
      }
      _exitSelectionMode();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selectedIds.length} Notizen verschoben')),
        );
      }
    }
  }

  Future<void> _bulkArchive() async {
    final selectedIds = ref.read(selectedNotesProvider);
    if (selectedIds.isEmpty) return;

    final notesDao = ref.read(notesDaoProvider);
    for (final noteId in selectedIds) {
      await notesDao.toggleArchive(noteId);
    }
    _exitSelectionMode();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selectedIds.length} Notizen archiviert')),
      );
    }
  }

  Future<void> _bulkDelete() async {
    final selectedIds = ref.read(selectedNotesProvider);
    if (selectedIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notizen löschen?'),
        content: Text('${selectedIds.length} Notizen werden in den Papierkorb verschoben.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final notesDao = ref.read(notesDaoProvider);
      for (final noteId in selectedIds) {
        await notesDao.moveToTrash(noteId);
      }
      _exitSelectionMode();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selectedIds.length} Notizen gelöscht')),
        );
      }
    }
  }

  Future<void> _bulkPin(bool pin) async {
    final selectedIds = ref.read(selectedNotesProvider);
    if (selectedIds.isEmpty) return;

    final notesDao = ref.read(notesDaoProvider);
    for (final noteId in selectedIds) {
      final note = await notesDao.getNoteById(noteId);
      if (note != null && note.isPinned != pin) {
        await notesDao.togglePin(noteId);
      }
    }
    _exitSelectionMode();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selectedIds.length} Notizen ${pin ? 'angepinnt' : 'nicht mehr angepinnt'}')),
      );
    }
  }

  Future<void> _bulkEditTags() async {
    // TODO: Implement bulk tag editing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tags-Bearbeitung wird implementiert...')),
    );
  }

  void _showSortOptions() {
    final currentOrder = ref.read(sortOrderProvider);
    final currentDirection = ref.read(sortDirectionProvider);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Sortieren nach',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Änderungsdatum'),
              trailing: currentOrder == SortOrder.modified
                  ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                ref.read(sortOrderProvider.notifier).setOrder(SortOrder.modified);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Erstellungsdatum'),
              trailing: currentOrder == SortOrder.created
                  ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                ref.read(sortOrderProvider.notifier).setOrder(SortOrder.created);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('Name'),
              trailing: currentOrder == SortOrder.name
                  ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                ref.read(sortOrderProvider.notifier).setOrder(SortOrder.name);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                currentDirection == SortDirection.ascending
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
              ),
              title: Text(
                currentDirection == SortDirection.ascending
                    ? 'Aufsteigend'
                    : 'Absteigend',
              ),
              onTap: () {
                ref.read(sortDirectionProvider.notifier).setDirection(
                    currentDirection == SortDirection.ascending
                        ? SortDirection.descending
                        : SortDirection.ascending);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createNewNote() async {
    final folderId = ref.read(currentFolderProvider) ?? 'default';

    // Zeige Notiz-Typ-Dialog auf Desktop, gehe direkt zu Text auf Mobile
    final layoutType = Breakpoints.getLayoutType(context);

    if (layoutType == LayoutType.compact) {
      // Auf Mobile: Direkt Textnotiz erstellen
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NoteEditorScreen(folderId: folderId),
          ),
        );
      }
    } else {
      // Auf Tablet/Desktop: Notiz-Typ-Dialog zeigen
      final result = await showNoteTypeDialog(context);
      if (result == null || !mounted) return;

      Widget screen;
      switch (result.type) {
        case ContentType.text:
          screen = NoteEditorScreen(
            folderId: folderId,
            initialTitle: result.template?.titleTemplate,
            initialContent: result.template?.content,
          );
          break;
        case ContentType.audio:
          screen = AudioNoteScreen(folderId: folderId);
          break;
        case ContentType.image:
          screen = ImageNoteScreen(folderId: folderId);
          break;
        case ContentType.drawing:
          screen = DrawingNoteScreen(folderId: folderId);
          break;
      }

      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => screen),
      );
    }
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
              leading: Icon(
                note.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
              ),
              title: Text(note.isArchived ? 'Aus Archiv wiederherstellen' : 'Archivieren'),
              onTap: () {
                Navigator.pop(context);
                ref.read(notesDaoProvider).toggleArchive(note.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(note.isArchived
                        ? 'Aus Archiv wiederhergestellt'
                        : 'In Archiv verschoben'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Duplizieren'),
              onTap: () {
                Navigator.pop(context);
                _duplicateNote(note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_move_outlined),
              title: const Text('Verschieben'),
              onTap: () {
                Navigator.pop(context);
                _moveNote(note);
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

  Future<void> _moveNote(Note note) async {
    final folders = await ref.read(allFoldersProvider.future);
    if (!mounted) return;

    final folderId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('In Ordner verschieben'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              final isCurrent = folder.id == note.folderId;
              return ListTile(
                leading: Icon(Icons.folder, color: Color(folder.color)),
                title: Text(folder.name),
                trailing: isCurrent ? const Icon(Icons.check) : null,
                onTap: isCurrent ? null : () => Navigator.pop(context, folder.id),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
        ],
      ),
    );

    if (folderId != null && mounted) {
      await ref.read(notesDaoProvider).moveNote(note.id, folderId);
      final folder = folders.firstWhere((f) => f.id == folderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nach "${folder.name}" verschoben')),
        );
      }
    }
  }

  void _duplicateNote(Note note) async {
    final newId = const Uuid().v4();
    try {
      await ref.read(notesDaoProvider).duplicateNote(note.id, newId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notiz dupliziert')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Duplizieren: $e')),
        );
      }
    }
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

/// Notiz-Karte für die Rasteransicht
class _NoteGridCard extends StatelessWidget {
  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _NoteGridCard({
    required this.note,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header mit Icon und Pin
              Row(
                children: [
                  _buildContentTypeIcon(context),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note.title.isEmpty ? 'Unbenannt' : note.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (note.isPinned)
                    Icon(
                      Icons.push_pin,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Vorschau des Inhalts
              Expanded(
                child: Text(
                  _getPreviewText(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.fade,
                ),
              ),

              const SizedBox(height: 8),

              // Datum
              Text(
                _formatDate(note.updatedAt),
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentTypeIcon(BuildContext context) {
    final theme = Theme.of(context);
    IconData icon;

    switch (note.contentType) {
      case 'audio':
        icon = Icons.mic;
        break;
      case 'image':
        icon = Icons.image;
        break;
      case 'drawing':
        icon = Icons.brush;
        break;
      default:
        icon = Icons.article;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        icon,
        size: 16,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }

  String _getPreviewText() {
    final preview = note.content
        .replaceAll(RegExp(r'#{1,6}\s'), '')
        .replaceAll(RegExp(r'\*{1,2}'), '')
        .replaceAll(RegExp(r'_{1,2}'), '')
        .replaceAll(RegExp(r'`{1,3}'), '')
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1')
        .replaceAll(RegExp(r'\n+'), ' ')
        .trim();

    return preview;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final noteDate = DateTime(date.year, date.month, date.day);

    if (noteDate == today) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (noteDate == today.subtract(const Duration(days: 1))) {
      return 'Gestern';
    } else if (now.difference(date).inDays < 7) {
      final weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
      return weekdays[date.weekday - 1];
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}
