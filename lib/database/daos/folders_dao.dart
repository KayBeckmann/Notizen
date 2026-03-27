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

  Future<String> ensureDefaultFolder() async {
    final existing = await (select(folders)..limit(1)).get();
    if (existing.isNotEmpty) return existing.first.id;

    final id = 'default';
    await createFolder(FoldersCompanion.insert(
      id: id,
      name: 'Meine Notizen',
      color: 0xFF6750A4,
    ));
    return id;
  }
}
