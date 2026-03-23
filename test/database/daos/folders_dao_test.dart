import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notizen/database/database.dart';
import 'package:notizen/database/daos/folders_dao.dart';

void main() {
  late AppDatabase database;
  late FoldersDao foldersDao;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    foldersDao = FoldersDao(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('FoldersDao', () {
    test('creates default folder on database creation', () async {
      final folders = await foldersDao.watchAllFolders().first;
      expect(folders.length, 1);
      expect(folders.first.id, 'default');
      expect(folders.first.name, 'Notizen');
    });

    test('createFolder adds a new folder', () async {
      final now = DateTime.now();
      await foldersDao.createFolder(
        FoldersCompanion.insert(
          id: 'test-folder',
          name: 'Test',
          color: 0xFF000000,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final folders = await foldersDao.watchAllFolders().first;
      expect(folders.length, 2);
      expect(folders.any((f) => f.id == 'test-folder'), true);
    });

    test('getFolderById returns correct folder', () async {
      final folder = await foldersDao.getFolderById('default');
      expect(folder, isNotNull);
      expect(folder!.name, 'Notizen');
    });

    test('getFolderById returns null for non-existent folder', () async {
      final folder = await foldersDao.getFolderById('non-existent');
      expect(folder, isNull);
    });

    test('deleteFolder removes folder', () async {
      final now = DateTime.now();
      await foldersDao.createFolder(
        FoldersCompanion.insert(
          id: 'to-delete',
          name: 'Delete Me',
          color: 0xFF000000,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await foldersDao.deleteFolder('to-delete');
      final folder = await foldersDao.getFolderById('to-delete');
      expect(folder, isNull);
    });

    test('watchRootFolders returns only folders without parent', () async {
      final now = DateTime.now();

      await foldersDao.createFolder(
        FoldersCompanion.insert(
          id: 'child-folder',
          name: 'Child',
          color: 0xFF000000,
          parentId: const Value('default'),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final rootFolders = await foldersDao.watchRootFolders().first;
      expect(rootFolders.length, 1);
      expect(rootFolders.first.id, 'default');
    });

    test('watchChildFolders returns children of parent', () async {
      final now = DateTime.now();

      await foldersDao.createFolder(
        FoldersCompanion.insert(
          id: 'child-folder',
          name: 'Child',
          color: 0xFF000000,
          parentId: const Value('default'),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final children = await foldersDao.watchChildFolders('default').first;
      expect(children.length, 1);
      expect(children.first.id, 'child-folder');
    });

    test('moveFolder changes parent', () async {
      final now = DateTime.now();

      await foldersDao.createFolder(
        FoldersCompanion.insert(
          id: 'parent1',
          name: 'Parent 1',
          color: 0xFF000000,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await foldersDao.createFolder(
        FoldersCompanion.insert(
          id: 'parent2',
          name: 'Parent 2',
          color: 0xFF000000,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await foldersDao.createFolder(
        FoldersCompanion.insert(
          id: 'child',
          name: 'Child',
          color: 0xFF000000,
          parentId: const Value('parent1'),
          createdAt: now,
          updatedAt: now,
        ),
      );

      await foldersDao.moveFolder('child', 'parent2');

      final folder = await foldersDao.getFolderById('child');
      expect(folder!.parentId, 'parent2');
    });
  });
}
