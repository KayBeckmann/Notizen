import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../database/database.dart';
import 'database_provider.dart';

part 'notes_provider.g.dart';

@riverpod
class CurrentFolder extends _$CurrentFolder {
  @override
  String? build() => null;

  void select(String? folderId) => state = folderId;
}

@riverpod
Stream<List<Note>> notesInFolder(NotesInFolderRef ref, String? folderId) {
  if (folderId == null) {
    return ref.watch(notesDaoProvider).watchAllNotes();
  }
  return ref.watch(notesDaoProvider).watchNotesByFolder(folderId);
}
