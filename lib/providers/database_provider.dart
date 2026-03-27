import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../database/database.dart';
import '../database/daos/folders_dao.dart';
import '../database/daos/notes_dao.dart';
import '../database/daos/tags_dao.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
AppDatabase database(DatabaseRef ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

@riverpod
FoldersDao foldersDao(FoldersDaoRef ref) {
  return ref.watch(databaseProvider).foldersDao;
}

@riverpod
NotesDao notesDao(NotesDaoRef ref) {
  return ref.watch(databaseProvider).notesDao;
}

@riverpod
TagsDao tagsDao(TagsDaoRef ref) {
  return ref.watch(databaseProvider).tagsDao;
}
