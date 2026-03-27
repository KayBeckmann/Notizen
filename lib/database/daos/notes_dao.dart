import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/notes.dart';
import '../tables/note_tags.dart';

part 'notes_dao.g.dart';

@DriftAccessor(tables: [Notes, NoteTags])
class NotesDao extends DatabaseAccessor<AppDatabase> with _$NotesDaoMixin {
  NotesDao(super.db);

  Stream<List<Note>> watchAllNotes() => (select(notes)..where((tbl) => tbl.isTrashed.not())).watch();
  Stream<List<Note>> watchNotesByFolder(String folderId) => (select(notes)..where((tbl) => tbl.folderId.equals(folderId) & tbl.isTrashed.not())).watch();
  Stream<List<Note>> watchPinnedNotes() => (select(notes)..where((tbl) => tbl.isPinned & tbl.isTrashed.not())).watch();
  Stream<List<Note>> watchArchivedNotes() => (select(notes)..where((tbl) => tbl.isArchived & tbl.isTrashed.not())).watch();
  Stream<List<Note>> watchTrashedNotes() => (select(notes)..where((tbl) => tbl.isTrashed)).watch();
  Future<Note?> getNoteById(String id) => (select(notes)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<int> createNote(NotesCompanion entry) => into(notes).insert(entry);
  Future<bool> updateNote(NotesCompanion entry) => update(notes).replace(entry);
  Future<int> deleteNote(String id) => (delete(notes)..where((tbl) => tbl.id.equals(id))).go();

  Future<int> moveToTrash(String id) => (update(notes)..where((tbl) => tbl.id.equals(id))).write(NotesCompanion(isTrashed: const Value(true), trashedAt: Value(DateTime.now())));
  Future<int> restoreFromTrash(String id) => (update(notes)..where((tbl) => tbl.id.equals(id))).write(const NotesCompanion(isTrashed: Value(false), trashedAt: Value(null)));
  Future<int> emptyTrash() => (delete(notes)..where((tbl) => tbl.isTrashed)).go();

  Future<int> togglePin(String id) async {
    final note = await getNoteById(id);
    if (note == null) return 0;
    return (update(notes)..where((tbl) => tbl.id.equals(id))).write(NotesCompanion(isPinned: Value(!note.isPinned)));
  }

  Future<int> toggleArchive(String id) async {
    final note = await getNoteById(id);
    if (note == null) return 0;
    return (update(notes)..where((tbl) => tbl.id.equals(id))).write(NotesCompanion(isArchived: Value(!note.isArchived)));
  }
}
