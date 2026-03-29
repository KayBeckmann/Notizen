import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/note_tags.dart';
import '../tables/tags.dart';

import '../../services/sync/sync.dart';

part 'tags_dao.g.dart';

/// Data Access Object für Tags
@DriftAccessor(tables: [Tags, NoteTags])
class TagsDao extends DatabaseAccessor<AppDatabase> with _$TagsDaoMixin {
  final SyncService? syncService;

  TagsDao(super.db, {this.syncService});

  /// Stream aller Tags
  Stream<List<Tag>> watchAllTags() {
    return (select(tags)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  }

  /// Stream der Tags einer Notiz
  Stream<List<Tag>> watchTagsForNote(String noteId) {
    final query = select(tags).join([
      innerJoin(noteTags, noteTags.tagId.equalsExp(tags.id)),
    ])
      ..where(noteTags.noteId.equals(noteId))
      ..orderBy([OrderingTerm.asc(tags.name)]);

    return query.map((row) => row.readTable(tags)).watch();
  }

  /// Tags einer Notiz abrufen (einmalig)
  Future<List<Tag>> getTagsForNote(String noteId) {
    final query = select(tags).join([
      innerJoin(noteTags, noteTags.tagId.equalsExp(tags.id)),
    ])
      ..where(noteTags.noteId.equals(noteId))
      ..orderBy([OrderingTerm.asc(tags.name)]);

    return query.map((row) => row.readTable(tags)).get();
  }

  /// Einzelnen Tag abrufen
  Future<Tag?> getTagById(String id) {
    return (select(tags)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Tag anhand des Namens abrufen
  Future<Tag?> getTagByName(String name) {
    return (select(tags)..where((t) => t.name.equals(name))).getSingleOrNull();
  }

  /// Neuen Tag erstellen
  Future<String> createTag(TagsCompanion tag) async {
    final id = tag.id.value;
    await into(tags).insert(tag);
    final createdTag = await getTagById(id);
    if (createdTag != null) {
      syncService?.queueTagChange(createdTag, SyncChangeType.created);
    }
    return id;
  }

  /// Tag aktualisieren
  Future<bool> updateTag(Tag tag) async {
    final success = await update(tags).replace(tag);
    if (success) {
      syncService?.queueTagChange(tag, SyncChangeType.updated);
    }
    return success;
  }

  /// Tag löschen (entfernt auch alle Verknüpfungen)
  Future<void> deleteTag(String id) async {
    await (delete(noteTags)..where((t) => t.tagId.equals(id))).go();
    await (delete(tags)..where((t) => t.id.equals(id))).go();
    syncService?.queueDeletion(id, 'tag');
  }

  /// Tag einer Notiz zuweisen
  Future<void> addTagToNote(String noteId, String tagId) {
    return into(noteTags).insert(
      NoteTagsCompanion.insert(noteId: noteId, tagId: tagId),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// Tag von einer Notiz entfernen
  Future<void> removeTagFromNote(String noteId, String tagId) {
    return (delete(noteTags)
          ..where((t) => t.noteId.equals(noteId) & t.tagId.equals(tagId)))
        .go();
  }

  /// Tags einer Notiz setzen (ersetzt alle bestehenden)
  Future<void> setTagsForNote(String noteId, List<String> tagIds) async {
    // Alle bestehenden Verknüpfungen löschen
    await (delete(noteTags)..where((t) => t.noteId.equals(noteId))).go();

    // Neue Verknüpfungen erstellen
    for (final tagId in tagIds) {
      await addTagToNote(noteId, tagId);
    }

    // Die Notiz selbst als geändert markieren für Sync
    // Wir holen uns die Notiz über das AppDatabase Objekt
    final note = await (select(db.notes)..where((t) => t.id.equals(noteId))).getSingleOrNull();
    if (note != null) {
      syncService?.queueNoteChange(note, SyncChangeType.updated);
    }
  }

  /// Anzahl der Notizen mit einem Tag
  Future<int> getNoteCountForTag(String tagId) async {
    final query = customSelect(
      'SELECT COUNT(*) as count FROM note_tags WHERE tag_id = ?',
      variables: [Variable.withString(tagId)],
      readsFrom: {},
    );
    final result = await query.getSingle();
    return result.read<int>('count');
  }

  /// Notizen mit einem bestimmten Tag
  Stream<List<String>> watchNoteIdsForTag(String tagId) {
    return (select(noteTags)..where((t) => t.tagId.equals(tagId)))
        .map((row) => row.noteId)
        .watch();
  }

  /// Stream der Notizanzahl pro Tag
  /// Gibt eine Map zurück: tagId -> Anzahl
  Stream<Map<String, int>> watchNoteCountsByTag() {
    return select(noteTags).watch().map((noteTagsList) {
      final counts = <String, int>{};
      for (final noteTag in noteTagsList) {
        counts[noteTag.tagId] = (counts[noteTag.tagId] ?? 0) + 1;
      }
      return counts;
    });
  }
}
