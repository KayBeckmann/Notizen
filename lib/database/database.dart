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

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        // Da dies ein kompletter Rebuild ist, löschen wir bei Schema-Änderungen 
        // in der Entwicklungsphase die alten Tabellen und erstellen sie neu.
        // In einer Produktiv-App sollten hier gezielte Migrationen stehen.
        for (final table in allTables) {
          await m.deleteTable(table.actualTableName);
        }
        await m.createAll();
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}
