import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notizen/database/database.dart';
import 'package:notizen/database/daos/notes_dao.dart';

void main() {
  late AppDatabase database;
  late NotesDao notesDao;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    notesDao = NotesDao(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('NotesDao', () {
    test('createNote adds a new note', () async {
      final now = DateTime.now();
      await notesDao.createNote(
        NotesCompanion.insert(
          id: 'test-note',
          folderId: 'default',
          title: const Value('Test Note'),
          content: const Value('Test content'),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final notes = await notesDao.watchAllNotes().first;
      expect(notes.length, 1);
      expect(notes.first.title, 'Test Note');
    });

    test('getNoteById returns correct note', () async {
      final now = DateTime.now();
      await notesDao.createNote(
        NotesCompanion.insert(
          id: 'test-note',
          folderId: 'default',
          title: const Value('Test Note'),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final note = await notesDao.getNoteById('test-note');
      expect(note, isNotNull);
      expect(note!.title, 'Test Note');
    });

    test('moveToTrash sets isTrashed to true', () async {
      final now = DateTime.now();
      await notesDao.createNote(
        NotesCompanion.insert(
          id: 'test-note',
          folderId: 'default',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await notesDao.moveToTrash('test-note');

      final note = await notesDao.getNoteById('test-note');
      expect(note!.isTrashed, true);
      expect(note.trashedAt, isNotNull);
    });

    test('restoreFromTrash sets isTrashed to false', () async {
      final now = DateTime.now();
      await notesDao.createNote(
        NotesCompanion.insert(
          id: 'test-note',
          folderId: 'default',
          isTrashed: const Value(true),
          trashedAt: Value(now),
          createdAt: now,
          updatedAt: now,
        ),
      );

      await notesDao.restoreFromTrash('test-note');

      final note = await notesDao.getNoteById('test-note');
      expect(note!.isTrashed, false);
      expect(note.trashedAt, isNull);
    });

    test('togglePin toggles isPinned', () async {
      final now = DateTime.now();
      await notesDao.createNote(
        NotesCompanion.insert(
          id: 'test-note',
          folderId: 'default',
          createdAt: now,
          updatedAt: now,
        ),
      );

      // First toggle - should set to true
      await notesDao.togglePin('test-note');
      var note = await notesDao.getNoteById('test-note');
      expect(note!.isPinned, true);

      // Second toggle - should set to false
      await notesDao.togglePin('test-note');
      note = await notesDao.getNoteById('test-note');
      expect(note!.isPinned, false);
    });

    test('searchNotes finds notes by title', () async {
      final now = DateTime.now();
      await notesDao.createNote(
        NotesCompanion.insert(
          id: 'note1',
          folderId: 'default',
          title: const Value('Shopping List'),
          createdAt: now,
          updatedAt: now,
        ),
      );

      await notesDao.createNote(
        NotesCompanion.insert(
          id: 'note2',
          folderId: 'default',
          title: const Value('Meeting Notes'),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final results = await notesDao.searchNotes('Shopping').first;
      expect(results.length, 1);
      expect(results.first.title, 'Shopping List');
    });

    test('searchNotes finds notes by content', () async {
      final now = DateTime.now();
      await notesDao.createNote(
        NotesCompanion.insert(
          id: 'note1',
          folderId: 'default',
          title: const Value('Note 1'),
          content: const Value('Buy milk and eggs'),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final results = await notesDao.searchNotes('milk').first;
      expect(results.length, 1);
      expect(results.first.content, contains('milk'));
    });

    test('watchNotesByFolder returns only notes in folder', () async {
      final now = DateTime.now();

      await notesDao.createNote(
        NotesCompanion.insert(
          id: 'note1',
          folderId: 'default',
          title: const Value('Note in Default'),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final notes = await notesDao.watchNotesByFolder('default').first;
      expect(notes.length, 1);
      expect(notes.first.folderId, 'default');
    });

    test('emptyTrash deletes all trashed notes', () async {
      final now = DateTime.now();

      await notesDao.createNote(
        NotesCompanion.insert(
          id: 'note1',
          folderId: 'default',
          isTrashed: const Value(true),
          trashedAt: Value(now),
          createdAt: now,
          updatedAt: now,
        ),
      );

      await notesDao.createNote(
        NotesCompanion.insert(
          id: 'note2',
          folderId: 'default',
          isTrashed: const Value(true),
          trashedAt: Value(now),
          createdAt: now,
          updatedAt: now,
        ),
      );

      await notesDao.emptyTrash();

      final trashed = await notesDao.watchTrashedNotes().first;
      expect(trashed.length, 0);
    });
  });
}
