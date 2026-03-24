import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/note_tags.dart';
import '../tables/tags.dart';

part 'tags_dao.g.dart';

/// Data Access Object für Tags
@DriftAccessor(tables: [Tags, NoteTags])
class TagsDao extends DatabaseAccessor<AppDatabase> with _$TagsDaoMixin {
  TagsDao(super.db);

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
  Future<void> createTag(TagsCompanion tag) {
    return into(tags).insert(tag);
  }

  /// Tag aktualisieren
  Future<bool> updateTag(Tag tag) {
    return update(tags).replace(tag);
  }

  /// Tag löschen (entfernt auch alle Verknüpfungen)
  Future<void> deleteTag(String id) async {
    await (delete(noteTags)..where((t) => t.tagId.equals(id))).go();
    await (delete(tags)..where((t) => t.id.equals(id))).go();
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
}
