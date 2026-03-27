import 'package:drift/drift.dart';
import 'connection/connection.dart';
import 'tables/folders.dart';
import 'tables/notes.dart';
import 'tables/tags.dart';
import 'tables/note_tags.dart';
import '../models/enums.dart';

import 'daos/folders_dao.dart';
import 'daos/notes_dao.dart';
import 'daos/tags_dao.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Folders, Notes, Tags, NoteTags], daos: [FoldersDao, NotesDao, TagsDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 1;
}
