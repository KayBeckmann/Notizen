import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/folders.dart';

part 'folders_dao.g.dart';

/// Data Access Object für Ordner
@DriftAccessor(tables: [Folders])
class FoldersDao extends DatabaseAccessor<AppDatabase> with _$FoldersDaoMixin {
  FoldersDao(super.db);

  /// Stream aller Ordner
  Stream<List<Folder>> watchAllFolders() {
    return (select(folders)..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .watch();
  }

  /// Stream der Root-Ordner (ohne Parent)
  Stream<List<Folder>> watchRootFolders() {
    return (select(folders)
          ..where((t) => t.parentId.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .watch();
  }

  /// Stream der Kind-Ordner eines Parent-Ordners
  Stream<List<Folder>> watchChildFolders(String parentId) {
    return (select(folders)
          ..where((t) => t.parentId.equals(parentId))
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .watch();
  }

  /// Einzelnen Ordner abrufen
  Future<Folder?> getFolderById(String id) {
    return (select(folders)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Pfad vom Root zum Ordner (Breadcrumb)
  Future<List<Folder>> getFolderPath(String id) async {
    final path = <Folder>[];
    String? currentId = id;

    while (currentId != null) {
      final folder = await getFolderById(currentId);
      if (folder != null) {
        path.insert(0, folder);
        currentId = folder.parentId;
      } else {
        break;
      }
    }

    return path;
  }

  /// Neuen Ordner erstellen
  Future<String> createFolder(FoldersCompanion folder) async {
    final id = folder.id.value as String;
    await into(folders).insert(folder);
    return id;
  }

  /// Ordner aktualisieren
  Future<bool> updateFolder(Folder folder) async {
    return await update(folders).replace(folder);
  }

  /// Ordner löschen (kaskadierend mit Unterordnern)
  Future<void> deleteFolder(String id) async {
    // Erst alle Unterordner rekursiv löschen
    final children =
        await (select(folders)..where((t) => t.parentId.equals(id))).get();
    for (final child in children) {
      await deleteFolder(child.id);
    }

    // Dann den Ordner selbst löschen
    await (delete(folders)..where((t) => t.id.equals(id))).go();
  }

  /// Ordner verschieben
  Future<void> moveFolder(String id, String? newParentId) async {
    final folder = await getFolderById(id);
    if (folder != null) {
      final now = DateTime.now();
      await (update(folders)..where((t) => t.id.equals(id))).write(
        FoldersCompanion(
          parentId: Value(newParentId),
          updatedAt: Value(now),
        ),
      );
    }
  }

  /// Ordner neu sortieren
  Future<void> reorderFolders(List<String> ids) async {
    final now = DateTime.now();
    for (var i = 0; i < ids.length; i++) {
      await (update(folders)..where((t) => t.id.equals(ids[i]))).write(
        FoldersCompanion(
          position: Value(i),
          updatedAt: Value(now),
        ),
      );
    }
  }

  /// Anzahl der Notizen in einem Ordner
  Future<int> getNoteCount(String folderId) async {
    final query = customSelect(
      'SELECT COUNT(*) as count FROM notes WHERE folder_id = ? AND is_trashed = 0',
      variables: [Variable.withString(folderId)],
      readsFrom: {},
    );
    final result = await query.getSingle();
    return result.read<int>('count');
  }
}
