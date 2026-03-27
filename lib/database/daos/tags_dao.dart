import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/tags.dart';
import '../tables/note_tags.dart';

part 'tags_dao.g.dart';

@DriftAccessor(tables: [Tags, NoteTags])
class TagsDao extends DatabaseAccessor<AppDatabase> with _$TagsDaoMixin {
  TagsDao(super.db);

  Stream<List<Tag>> watchAllTags() => select(tags).watch();
  
  Stream<List<Tag>> watchTagsForNote(String noteId) {
    final query = select(tags).join([
      innerJoin(noteTags, noteTags.tagId.equalsExp(tags.id)),
    ])
      ..where(noteTags.noteId.equals(noteId));
    
    return query.watch().map((rows) => rows.map((row) => row.readTable(tags)).toList());
  }

  Future<Tag?> getTagById(String id) => (select(tags)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<int> createTag(TagsCompanion entry) => into(tags).insert(entry);
  Future<bool> updateTag(TagsCompanion entry) => update(tags).replace(entry);
  Future<int> deleteTag(String id) => (delete(tags)..where((tbl) => tbl.id.equals(id))).go();

  Future<void> addTagToNote(String noteId, String tagId) => into(noteTags).insert(NoteTagsCompanion(noteId: Value(noteId), tagId: Value(tagId)));
  Future<void> removeTagFromNote(String noteId, String tagId) => (delete(noteTags)..where((tbl) => tbl.noteId.equals(noteId) & tbl.tagId.equals(tagId))).go();
}
