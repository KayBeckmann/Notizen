import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/database.dart';
import '../models/enums.dart';
import 'database_provider.dart';
import 'folders_provider.dart';

part 'notes_provider.g.dart';

/// Sortiereinstellungen
final sortOrderProvider = StateProvider<SortOrder>((ref) => SortOrder.modified);
final sortDirectionProvider = StateProvider<SortDirection>((ref) => SortDirection.descending);

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
Stream<List<Note>> notesInCurrentFolder(Ref ref) {
  final notesAsync = ref.watch(notesInCurrentFolderRawProvider);
  final sortOrder = ref.watch(sortOrderProvider);
  final sortDirection = ref.watch(sortDirectionProvider);

  return notesAsync.when(
    data: (notes) {
      final sortedNotes = _sortNotes(notes, sortOrder, sortDirection);
      return Stream.value(sortedNotes);
    },
    loading: () => const Stream.empty(),
    error: (e, st) => Stream.error(e, st),
  );
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
