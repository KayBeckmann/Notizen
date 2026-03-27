import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/folders.dart';

part 'folders_dao.g.dart';

@DriftAccessor(tables: [Folders])
class FoldersDao extends DatabaseAccessor<AppDatabase> with _$FoldersDaoMixin {
  FoldersDao(super.db);

  Stream<List<Folder>> watchAllFolders() => select(folders).watch();
  Stream<List<Folder>> watchRootFolders() => (select(folders)..where((tbl) => tbl.parentId.isNull())).watch();
  Stream<List<Folder>> watchChildFolders(String parentId) => (select(folders)..where((tbl) => tbl.parentId.equals(parentId))).watch();
  Future<Folder?> getFolderById(String id) => (select(folders)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<int> createFolder(FoldersCompanion entry) => into(folders).insert(entry);
  Future<bool> updateFolder(FoldersCompanion entry) => update(folders).replace(entry);
  Future<int> deleteFolder(String id) => (delete(folders)..where((tbl) => tbl.id.equals(id))).go();

  Future<void> reorderFolders(List<String> ids) async {
    await batch((batch) {
      for (var i = 0; i < ids.length; i++) {
        batch.update(folders, FoldersCompanion(position: Value(i)), where: (tbl) => tbl.id.equals(ids[i]));
      }
    });
  }
}
