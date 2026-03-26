import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/database.dart';
import '../models/enums.dart';
import '../services/settings_service.dart';
import 'database_provider.dart';
import 'folders_provider.dart';

part 'notes_provider.g.dart';

/// Sortiereinstellungen (persistiert)
final sortOrderProvider = StateNotifierProvider<SortOrderNotifier, SortOrder>((ref) {
  return SortOrderNotifier();
});

class SortOrderNotifier extends StateNotifier<SortOrder> {
  SortOrderNotifier() : super(SettingsService.instance.sortOrder);

  void setOrder(SortOrder order) {
    state = order;
    SettingsService.instance.setSortOrder(order);
  }
}

final sortDirectionProvider = StateNotifierProvider<SortDirectionNotifier, SortDirection>((ref) {
  return SortDirectionNotifier();
});

class SortDirectionNotifier extends StateNotifier<SortDirection> {
  SortDirectionNotifier() : super(SettingsService.instance.sortDirection);

  void setDirection(SortDirection direction) {
    state = direction;
    SettingsService.instance.setSortDirection(direction);
  }
}

/// Stream aller Notizen (nicht im Papierkorb)
@riverpod
Stream<List<Note>> allNotes(Ref ref) {
  return ref.watch(notesDaoProvider).watchAllNotes();
}

/// Stream der Notizen im aktuellen Ordner (unsortiert)
@riverpod
Stream<List<Note>> notesInCurrentFolderRaw(Ref ref) {
  final folderId = ref.watch(currentFolderProvider);
  final notesDao = ref.watch(notesDaoProvider);

  if (folderId == null) {
    return notesDao.watchAllNotes();
  } else if (folderId == '_pinned') {
    return notesDao.watchPinnedNotes();
  } else if (folderId == '_archived') {
    return notesDao.watchArchivedNotes();
  } else if (folderId == '_trash') {
    return notesDao.watchTrashedNotes();
  }
  return notesDao.watchNotesByFolder(folderId);
}

/// Stream der Notizen im aktuellen Ordner (sortiert)
@riverpod
Stream<List<Note>> notesInCurrentFolder(Ref ref) async* {
  final notes = await ref.watch(notesInCurrentFolderRawProvider.future);
  final sortOrder = ref.watch(sortOrderProvider);
  final sortDirection = ref.watch(sortDirectionProvider);

  yield _sortNotes(notes, sortOrder, sortDirection);
}

/// Hilfsfunktion zum Sortieren von Notizen
List<Note> _sortNotes(List<Note> notes, SortOrder order, SortDirection direction) {
  final sortedNotes = List<Note>.from(notes);

  // Zuerst angepinnte Notizen nach oben (immer)
  sortedNotes.sort((a, b) {
    // Angepinnte Notizen zuerst
    if (a.isPinned && !b.isPinned) return -1;
    if (!a.isPinned && b.isPinned) return 1;

    // Dann nach gewählter Sortierung
    int comparison;
    switch (order) {
      case SortOrder.name:
        comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        break;
      case SortOrder.created:
        comparison = a.createdAt.compareTo(b.createdAt);
        break;
      case SortOrder.modified:
        comparison = a.updatedAt.compareTo(b.updatedAt);
        break;
    }

    // Richtung berücksichtigen
    return direction == SortDirection.ascending ? comparison : -comparison;
  });

  return sortedNotes;
}

/// Stream der angepinnten Notizen
@riverpod
Stream<List<Note>> pinnedNotes(Ref ref) {
  return ref.watch(notesDaoProvider).watchPinnedNotes();
}

/// Stream der archivierten Notizen
@riverpod
Stream<List<Note>> archivedNotes(Ref ref) {
  return ref.watch(notesDaoProvider).watchArchivedNotes();
}

/// Stream der Notizen im Papierkorb
@riverpod
Stream<List<Note>> trashedNotes(Ref ref) {
  return ref.watch(notesDaoProvider).watchTrashedNotes();
}

/// Aktuell ausgewählte Notiz
@riverpod
class SelectedNote extends _$SelectedNote {
  @override
  String? build() => null;

  void select(String? noteId) {
    state = noteId;
  }
}

/// Mehrfachauswahl-Modus für Notizen
final selectionModeProvider = StateNotifierProvider<SelectionModeNotifier, bool>((ref) {
  return SelectionModeNotifier();
});

class SelectionModeNotifier extends StateNotifier<bool> {
  SelectionModeNotifier() : super(false);

  void enable() => state = true;
  void disable() => state = false;
  void toggle() => state = !state;
}

/// Ausgewählte Notizen für Bulk-Aktionen
final selectedNotesProvider = StateNotifierProvider<SelectedNotesNotifier, Set<String>>((ref) {
  return SelectedNotesNotifier();
});

class SelectedNotesNotifier extends StateNotifier<Set<String>> {
  SelectedNotesNotifier() : super({});

  void select(String noteId) {
    state = {...state, noteId};
  }

  void deselect(String noteId) {
    state = {...state}..remove(noteId);
  }

  void toggle(String noteId) {
    if (state.contains(noteId)) {
      deselect(noteId);
    } else {
      select(noteId);
    }
  }

  void selectAll(List<String> noteIds) {
    state = {...noteIds};
  }

  void clear() {
    state = {};
  }

  bool isSelected(String noteId) => state.contains(noteId);
}

/// Suchbegriff
@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void update(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

/// Suchergebnisse
@riverpod
Stream<List<Note>> searchResults(Ref ref) {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) {
    return Stream.value([]);
  }
  return ref.watch(notesDaoProvider).watchSearchNotes(query);
}

/// Editor-Modus (edit, preview, split) - persistiert
final editorModeIndexProvider = StateNotifierProvider<EditorModeIndexNotifier, int>((ref) {
  return EditorModeIndexNotifier();
});

class EditorModeIndexNotifier extends StateNotifier<int> {
  EditorModeIndexNotifier() : super(SettingsService.instance.editorModeIndex);

  void setMode(int index) {
    state = index;
    SettingsService.instance.setEditorModeIndex(index);
  }
}

/// Ob auf Desktop automatisch Split-Mode verwendet werden soll
final useSplitOnDesktopProvider = StateNotifierProvider<UseSplitOnDesktopNotifier, bool>((ref) {
  return UseSplitOnDesktopNotifier();
});

class UseSplitOnDesktopNotifier extends StateNotifier<bool> {
  UseSplitOnDesktopNotifier() : super(SettingsService.instance.useSplitOnDesktop);

  void setEnabled(bool enabled) {
    state = enabled;
    SettingsService.instance.setUseSplitOnDesktop(enabled);
  }
}

/// Ansichtsmodus (Liste oder Raster)
final viewModeProvider = StateNotifierProvider<ViewModeNotifier, ViewMode>((ref) {
  return ViewModeNotifier();
});

class ViewModeNotifier extends StateNotifier<ViewMode> {
  ViewModeNotifier() : super(SettingsService.instance.viewMode);

  void setMode(ViewMode mode) {
    state = mode;
    SettingsService.instance.setViewMode(mode);
  }

  void toggle() {
    final newMode = state == ViewMode.list ? ViewMode.grid : ViewMode.list;
    setMode(newMode);
  }
}

/// Notizanzahl pro Ordner
@riverpod
Stream<Map<String, int>> noteCountsByFolder(Ref ref) {
  return ref.watch(notesDaoProvider).watchNoteCountsByFolder();
}

/// Anzahl angepinnter Notizen
@riverpod
Stream<int> pinnedCount(Ref ref) {
  return ref.watch(notesDaoProvider).watchPinnedCount();
}

/// Anzahl archivierter Notizen
@riverpod
Stream<int> archivedCount(Ref ref) {
  return ref.watch(notesDaoProvider).watchArchivedCount();
}

/// Anzahl Notizen im Papierkorb
@riverpod
Stream<int> trashedCount(Ref ref) {
  return ref.watch(notesDaoProvider).watchTrashedCount();
}
