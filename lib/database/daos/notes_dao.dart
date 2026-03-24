import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/notes.dart';

part 'notes_dao.g.dart';

/// Data Access Object für Notizen
@DriftAccessor(tables: [Notes])
class NotesDao extends DatabaseAccessor<AppDatabase> with _$NotesDaoMixin {
  NotesDao(super.db);

  /// Stream aller Notizen (nicht im Papierkorb)
  Stream<List<Note>> watchAllNotes() {
    return (select(notes)
          ..where((t) => t.isTrashed.equals(false))
          ..orderBy([
            (t) => OrderingTerm.desc(t.isPinned),
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .watch();
  }

  /// Stream der Notizen in einem Ordner
  Stream<List<Note>> watchNotesByFolder(String folderId) {
    return (select(notes)
          ..where(
              (t) => t.folderId.equals(folderId) & t.isTrashed.equals(false))
          ..orderBy([
            (t) => OrderingTerm.desc(t.isPinned),
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .watch();
  }

  /// Stream der angepinnten Notizen
  Stream<List<Note>> watchPinnedNotes() {
    return (select(notes)
          ..where((t) => t.isPinned.equals(true) & t.isTrashed.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  /// Stream der archivierten Notizen
  Stream<List<Note>> watchArchivedNotes() {
    return (select(notes)
          ..where((t) => t.isArchived.equals(true) & t.isTrashed.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  /// Stream der Notizen im Papierkorb
  Stream<List<Note>> watchTrashedNotes() {
    return (select(notes)
          ..where((t) => t.isTrashed.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.trashedAt)]))
        .watch();
  }

  /// Einzelne Notiz abrufen
  Future<Note?> getNoteById(String id) {
    return (select(notes)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Volltextsuche in Notizen (Stream)
  Stream<List<Note>> watchSearchNotes(String query) {
    final searchPattern = '%$query%';
    return (select(notes)
          ..where((t) =>
              t.isTrashed.equals(false) &
              (t.title.like(searchPattern) | t.content.like(searchPattern)))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  /// Volltextsuche in Notizen (Future)
  Future<List<Note>> searchNotes(String query) {
    final searchPattern = '%$query%';
    return (select(notes)
          ..where((t) =>
              t.isTrashed.equals(false) &
              (t.title.like(searchPattern) | t.content.like(searchPattern)))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  /// Alle Notizen abrufen (nicht im Papierkorb)
  Future<List<Note>> getAllNotes() {
    return (select(notes)
          ..where((t) => t.isTrashed.equals(false))
          ..orderBy([
            (t) => OrderingTerm.desc(t.isPinned),
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .get();
  }

  /// Neue Notiz erstellen
  Future<void> createNote(NotesCompanion note) {
    return into(notes).insert(note);
  }

  /// Notiz aktualisieren
  Future<bool> updateNote(Note note) {
    return update(notes).replace(note);
  }

  /// Notiz endgültig löschen
  Future<void> deleteNote(String id) {
    return (delete(notes)..where((t) => t.id.equals(id))).go();
  }

  /// Notiz in den Papierkorb verschieben
  Future<void> moveToTrash(String id) async {
    await (update(notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        isTrashed: const Value(true),
        trashedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Notiz aus dem Papierkorb wiederherstellen
  Future<void> restoreFromTrash(String id) async {
    await (update(notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        isTrashed: const Value(false),
        trashedAt: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Papierkorb leeren
  Future<void> emptyTrash() {
    return (delete(notes)..where((t) => t.isTrashed.equals(true))).go();
  }

  /// Alte Einträge im Papierkorb löschen (älter als 30 Tage)
  Future<void> cleanupTrash() async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    await (delete(notes)
          ..where((t) =>
              t.isTrashed.equals(true) & t.trashedAt.isSmallerThanValue(thirtyDaysAgo)))
        .go();
  }

  /// Notiz in anderen Ordner verschieben
  Future<void> moveNote(String id, String folderId) async {
    await (update(notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        folderId: Value(folderId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Anpinnen umschalten
  Future<void> togglePin(String id) async {
    final note = await getNoteById(id);
    if (note != null) {
      await (update(notes)..where((t) => t.id.equals(id))).write(
        NotesCompanion(
          isPinned: Value(!note.isPinned),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  /// Archivieren umschalten
  Future<void> toggleArchive(String id) async {
    final note = await getNoteById(id);
    if (note != null) {
      await (update(notes)..where((t) => t.id.equals(id))).write(
        NotesCompanion(
          isArchived: Value(!note.isArchived),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  /// Notiz duplizieren
  Future<String> duplicateNote(String id, String newId) async {
    final note = await getNoteById(id);
    if (note == null) {
      throw Exception('Notiz nicht gefunden');
    }

    final now = DateTime.now();
    await into(notes).insert(
      NotesCompanion.insert(
        id: newId,
        folderId: note.folderId,
        title: Value('${note.title} (Kopie)'),
        content: Value(note.content),
        contentType: Value(note.contentType),
        mediaPath: Value(note.mediaPath),
        drawingData: Value(note.drawingData),
        isPinned: const Value(false),
        isArchived: const Value(false),
        isTrashed: const Value(false),
        createdAt: now,
        updatedAt: now,
      ),
    );

    return newId;
  }
}
