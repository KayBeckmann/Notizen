import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/database.dart';
import 'database_provider.dart';
import 'folders_provider.dart';

part 'notes_provider.g.dart';

/// Stream aller Notizen (nicht im Papierkorb)
@riverpod
Stream<List<Note>> allNotes(Ref ref) {
  return ref.watch(notesDaoProvider).watchAllNotes();
}

/// Stream der Notizen im aktuellen Ordner
@riverpod
Stream<List<Note>> notesInCurrentFolder(Ref ref) {
  final folderId = ref.watch(currentFolderProvider);
  if (folderId == null) {
    return ref.watch(notesDaoProvider).watchAllNotes();
  }
  return ref.watch(notesDaoProvider).watchNotesByFolder(folderId);
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
  return ref.watch(notesDaoProvider).searchNotes(query);
}
