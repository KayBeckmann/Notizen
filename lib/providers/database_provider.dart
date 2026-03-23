import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/database.dart';
import '../database/daos/folders_dao.dart';
import '../database/daos/notes_dao.dart';
import '../database/daos/tags_dao.dart';

part 'database_provider.g.dart';

/// Singleton-Instanz der Datenbank
@Riverpod(keepAlive: true)
AppDatabase database(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
}

/// FoldersDao Provider
@riverpod
FoldersDao foldersDao(Ref ref) {
  return FoldersDao(ref.watch(databaseProvider));
}

/// NotesDao Provider
@riverpod
NotesDao notesDao(Ref ref) {
  return NotesDao(ref.watch(databaseProvider));
}

/// TagsDao Provider
@riverpod
TagsDao tagsDao(Ref ref) {
  return TagsDao(ref.watch(databaseProvider));
}
