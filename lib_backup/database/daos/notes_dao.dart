import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/note_tags.dart';
import '../tables/notes.dart';

part 'notes_dao.g.dart';

/// Data Access Object für Notizen
@DriftAccessor(tables: [Notes, NoteTags])
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
  /// Archivierte und gelöschte Notizen werden ausgeschlossen
  Stream<List<Note>> watchSearchNotes(String query) {
    final searchPattern = '%$query%';
    return (select(notes)
          ..where((t) =>
              t.isTrashed.equals(false) &
              t.isArchived.equals(false) &
              (t.title.like(searchPattern) | t.content.like(searchPattern)))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  /// Volltextsuche in Notizen (Future)
  /// Archivierte und gelöschte Notizen werden ausgeschlossen
  Future<List<Note>> searchNotes(String query) {
    final searchPattern = '%$query%';
    return (select(notes)
          ..where((t) =>
              t.isTrashed.equals(false) &
              t.isArchived.equals(false) &
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
  Future<void> deleteNote(String id) async {
    // Manuell Tags löschen, um Foreign Key Constraints zu vermeiden
    await (delete(noteTags)..where((t) => t.noteId.equals(id))).go();
    // Notiz selbst löschen
    await (delete(notes)..where((t) => t.id.equals(id))).go();
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
  Future<void> emptyTrash() async {
    // Erst alle IDs der Notizen im Papierkorb holen
    final trashedNotes =
        await (select(notes)..where((t) => t.isTrashed.equals(true))).get();
    final trashedIds = trashedNotes.map((n) => n.id).toList();

    if (trashedIds.isNotEmpty) {
      // Tags für alle betroffenen Notizen löschen
      await (delete(noteTags)..where((t) => t.noteId.isIn(trashedIds))).go();
      // Notizen selbst löschen
      await (delete(notes)..where((t) => t.isTrashed.equals(true))).go();
    }
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

  /// Stream der Notizanzahl pro Ordner
  /// Gibt eine Map zurück: folderId -> Anzahl
  Stream<Map<String, int>> watchNoteCountsByFolder() {
    return (select(notes)..where((t) => t.isTrashed.equals(false)))
        .watch()
        .map((notesList) {
      final counts = <String, int>{};
      for (final note in notesList) {
        counts[note.folderId] = (counts[note.folderId] ?? 0) + 1;
      }
      return counts;
    });
  }

  /// Anzahl der angepinnten Notizen
  Stream<int> watchPinnedCount() {
    return (select(notes)
          ..where((t) => t.isPinned.equals(true) & t.isTrashed.equals(false)))
        .watch()
        .map((list) => list.length);
  }

  /// Anzahl der archivierten Notizen
  Stream<int> watchArchivedCount() {
    return (select(notes)
          ..where((t) => t.isArchived.equals(true) & t.isTrashed.equals(false)))
        .watch()
        .map((list) => list.length);
  }

  /// Anzahl der Notizen im Papierkorb
  Stream<int> watchTrashedCount() {
    return (select(notes)..where((t) => t.isTrashed.equals(true)))
        .watch()
        .map((list) => list.length);
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
