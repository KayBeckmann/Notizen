import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notizen/database/database.dart';
import 'package:notizen/database/daos/notes_dao.dart';
import 'package:notizen/database/daos/tags_dao.dart';

void main() {
  late AppDatabase database;
  late TagsDao tagsDao;
  late NotesDao notesDao;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tagsDao = TagsDao(database);
    notesDao = NotesDao(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('TagsDao', () {
    test('createTag adds a new tag', () async {
      final now = DateTime.now();
      await tagsDao.createTag(
        TagsCompanion.insert(
          id: 'test-tag',
          name: 'Test Tag',
          color: 0xFF000000,
          createdAt: now,
        ),
      );

      final tags = await tagsDao.watchAllTags().first;
      expect(tags.length, 1);
      expect(tags.first.name, 'Test Tag');
    });

    test('getTagById returns correct tag', () async {
      final now = DateTime.now();
      await tagsDao.createTag(
        TagsCompanion.insert(
          id: 'test-tag',
          name: 'Test Tag',
          color: 0xFF000000,
          createdAt: now,
        ),
      );

      final tag = await tagsDao.getTagById('test-tag');
      expect(tag, isNotNull);
      expect(tag!.name, 'Test Tag');
    });

    test('getTagByName returns tag by name', () async {
      final now = DateTime.now();
      await tagsDao.createTag(
        TagsCompanion.insert(
          id: 'test-tag',
          name: 'Important',
          color: 0xFF000000,
          createdAt: now,
        ),
      );

      final tag = await tagsDao.getTagByName('Important');
      expect(tag, isNotNull);
      expect(tag!.id, 'test-tag');
    });

    test('deleteTag removes tag', () async {
      final now = DateTime.now();
      await tagsDao.createTag(
        TagsCompanion.insert(
          id: 'test-tag',
          name: 'Test Tag',
          color: 0xFF000000,
          createdAt: now,
        ),
      );

      await tagsDao.deleteTag('test-tag');
      final tag = await tagsDao.getTagById('test-tag');
      expect(tag, isNull);
    });

    test('addTagToNote links tag to note', () async {
      final now = DateTime.now();

      await notesDao.createNote(
        NotesCompanion.insert(
          id: 'test-note',
          folderId: 'default',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await tagsDao.createTag(
        TagsCompanion.insert(
          id: 'test-tag',
          name: 'Test Tag',
          color: 0xFF000000,
          createdAt: now,
        ),
      );

      await tagsDao.addTagToNote('test-note', 'test-tag');

      final tags = await tagsDao.watchTagsForNote('test-note').first;
      expect(tags.length, 1);
      expect(tags.first.id, 'test-tag');
    });

    test('removeTagFromNote unlinks tag from note', () async {
      final now = DateTime.now();

      await notesDao.createNote(
        NotesCompanion.insert(
          id: 'test-note',
          folderId: 'default',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await tagsDao.createTag(
        TagsCompanion.insert(
          id: 'test-tag',
          name: 'Test Tag',
          color: 0xFF000000,
          createdAt: now,
        ),
      );

      await tagsDao.addTagToNote('test-note', 'test-tag');
      await tagsDao.removeTagFromNote('test-note', 'test-tag');

      final tags = await tagsDao.watchTagsForNote('test-note').first;
      expect(tags.length, 0);
    });

    test('setTagsForNote replaces all tags', () async {
      final now = DateTime.now();

      await notesDao.createNote(
        NotesCompanion.insert(
          id: 'test-note',
          folderId: 'default',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await tagsDao.createTag(
        TagsCompanion.insert(
          id: 'tag1',
          name: 'Tag 1',
          color: 0xFF000000,
          createdAt: now,
        ),
      );

      await tagsDao.createTag(
        TagsCompanion.insert(
          id: 'tag2',
          name: 'Tag 2',
          color: 0xFF000000,
          createdAt: now,
        ),
      );

      await tagsDao.createTag(
        TagsCompanion.insert(
          id: 'tag3',
          name: 'Tag 3',
          color: 0xFF000000,
          createdAt: now,
        ),
      );

      // Add tag1 initially
      await tagsDao.addTagToNote('test-note', 'tag1');

      // Replace with tag2 and tag3
      await tagsDao.setTagsForNote('test-note', ['tag2', 'tag3']);

      final tags = await tagsDao.watchTagsForNote('test-note').first;
      expect(tags.length, 2);
      expect(tags.any((t) => t.id == 'tag1'), false);
      expect(tags.any((t) => t.id == 'tag2'), true);
      expect(tags.any((t) => t.id == 'tag3'), true);
    });

    test('deleteTag also removes note associations', () async {
      final now = DateTime.now();

      await notesDao.createNote(
        NotesCompanion.insert(
          id: 'test-note',
          folderId: 'default',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await tagsDao.createTag(
        TagsCompanion.insert(
          id: 'test-tag',
          name: 'Test Tag',
          color: 0xFF000000,
          createdAt: now,
        ),
      );

      await tagsDao.addTagToNote('test-note', 'test-tag');
      await tagsDao.deleteTag('test-tag');

      final tags = await tagsDao.watchTagsForNote('test-note').first;
      expect(tags.length, 0);
    });
  });
}
