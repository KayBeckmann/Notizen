import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database.dart';
import '../tables/notes.dart';

import '../tables/note_tags.dart';
import '../tables/tags.dart';

import '../../services/sync/sync.dart';

part 'notes_dao.g.dart';

/// Data Access Object für Notizen
@DriftAccessor(tables: [Notes, Tags, NoteTags])
class NotesDao extends DatabaseAccessor<AppDatabase> with _$NotesDaoMixin {
  final SyncService? syncService;

  NotesDao(super.db, {this.syncService});

  /// Stream aller Notizen (archivierte und gelöschte Notizen ausschließen)
  Stream<List<Note>> watchAllNotes() {
    return (select(notes)
          ..where((t) => t.isTrashed.equals(false) & t.isArchived.equals(false))
          ..orderBy([
            (t) => OrderingTerm.desc(t.isPinned),
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .watch();
  }

  /// Stream der Notizen in einem Ordner (archivierte und gelöschte Notizen ausschließen)
  Stream<List<Note>> watchNotesByFolder(String folderId) {
    return (select(notes)
          ..where((t) =>
              t.folderId.equals(folderId) &
              t.isTrashed.equals(false) &
              t.isArchived.equals(false))
          ..orderBy([
            (t) => OrderingTerm.desc(t.isPinned),
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .watch();
  }

  /// Stream der Notizen mit einem bestimmten Tag
  Stream<List<Note>> watchNotesByTag(String tagId) {
    final query = select(notes).join([
      innerJoin(noteTags, noteTags.noteId.equalsExp(notes.id)),
    ])
      ..where(noteTags.tagId.equals(tagId) & notes.isTrashed.equals(false))
      ..orderBy([
        OrderingTerm.desc(notes.isPinned),
        OrderingTerm.desc(notes.updatedAt),
      ]);

    return query.watch().map((rows) {
      return rows.map((row) => row.readTable(notes)).toList();
    });
  }

  /// Stream der Notizanzahl pro Tag
  Stream<Map<String, int>> watchNoteCountsByTag() {
    final query = select(noteTags).join([
      innerJoin(notes, notes.id.equalsExp(noteTags.noteId)),
    ])
      ..where(notes.isTrashed.equals(false));

    return query.watch().map((rows) {
      final counts = <String, int>{};
      for (final row in rows) {
        final tagId = row.readTable(noteTags).tagId;
        counts[tagId] = (counts[tagId] ?? 0) + 1;
      }
      return counts;
    });
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
  Future<String> createNote(NotesCompanion note) async {
    debugPrint('DB: Creating note with folderId: ${note.folderId.value}');
    try {
      final id = await into(notes).insert(note);
      final createdNote = await getNoteById(id);
      if (createdNote != null) {
        syncService?.queueNoteChange(createdNote, SyncChangeType.created);
      }
      debugPrint('DB: Note created successfully');
      return id;
    } catch (e) {
      debugPrint('DB ERROR creating note: $e');
      rethrow;
    }
  }

  /// Notiz aktualisieren
  Future<bool> updateNote(Note note) async {
    final success = await update(notes).replace(note);
    if (success) {
      syncService?.queueNoteChange(note, SyncChangeType.updated);
    }
    return success;
  }

  /// Notiz endgültig löschen
  Future<void> deleteNote(String id) async {
    await (delete(notes)..where((t) => t.id.equals(id))).go();
    syncService?.queueNoteDeletion(id);
  }

  /// Notiz in den Papierkorb verschieben
  Future<void> moveToTrash(String id) async {
    final now = DateTime.now();
    await (update(notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        isTrashed: const Value(true),
        trashedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    final note = await getNoteById(id);
    if (note != null) {
      syncService?.queueNoteChange(note, SyncChangeType.updated);
    }
  }

  /// Notiz aus dem Papierkorb wiederherstellen
  Future<void> restoreFromTrash(String id) async {
    final now = DateTime.now();
    await (update(notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        isTrashed: const Value(false),
        trashedAt: const Value(null),
        updatedAt: Value(now),
      ),
    );
    final note = await getNoteById(id);
    if (note != null) {
      syncService?.queueNoteChange(note, SyncChangeType.updated);
    }
  }

  /// Papierkorb leeren
  Future<void> emptyTrash() async {
    final trashedNotes = await (select(notes)..where((t) => t.isTrashed.equals(true))).get();
    await (delete(notes)..where((t) => t.isTrashed.equals(true))).go();
    for (final note in trashedNotes) {
      syncService?.queueNoteDeletion(note.id);
    }
  }

  /// Alte Einträge im Papierkorb löschen (älter als 30 Tage)
  Future<void> cleanupTrash() async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final oldNotes = await (select(notes)
          ..where((t) =>
              t.isTrashed.equals(true) & t.trashedAt.isSmallerThanValue(thirtyDaysAgo)))
        .get();
    
    await (delete(notes)
          ..where((t) =>
              t.isTrashed.equals(true) & t.trashedAt.isSmallerThanValue(thirtyDaysAgo)))
        .go();

    for (final note in oldNotes) {
      syncService?.queueNoteDeletion(note.id);
    }
  }

  /// Notiz in anderen Ordner verschieben
  Future<void> moveNote(String id, String folderId) async {
    final now = DateTime.now();
    await (update(notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        folderId: Value(folderId),
        updatedAt: Value(now),
      ),
    );
    final note = await getNoteById(id);
    if (note != null) {
      syncService?.queueNoteChange(note, SyncChangeType.updated);
    }
  }

  /// Anpinnen umschalten
  Future<void> togglePin(String id) async {
    final note = await getNoteById(id);
    if (note != null) {
      final now = DateTime.now();
      await (update(notes)..where((t) => t.id.equals(id))).write(
        NotesCompanion(
          isPinned: Value(!note.isPinned),
          updatedAt: Value(now),
        ),
      );
      final updatedNote = await getNoteById(id);
      if (updatedNote != null) {
        syncService?.queueNoteChange(updatedNote, SyncChangeType.updated);
      }
    }
  }

  /// Archivieren umschalten
  Future<void> toggleArchive(String id) async {
    final note = await getNoteById(id);
    if (note != null) {
      final now = DateTime.now();
      await (update(notes)..where((t) => t.id.equals(id))).write(
        NotesCompanion(
          isArchived: Value(!note.isArchived),
          updatedAt: Value(now),
        ),
      );
      final updatedNote = await getNoteById(id);
      if (updatedNote != null) {
        syncService?.queueNoteChange(updatedNote, SyncChangeType.updated);
      }
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
