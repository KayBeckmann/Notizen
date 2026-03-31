import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notizen/database/database.dart';
import 'package:notizen/services/sync/sync_service.dart';
import 'package:notizen/services/sync/sync_provider.dart';

class MockSyncProvider extends Mock implements SyncProvider {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  late AppDatabase db;
  late SyncService syncService;
  late MockSyncProvider mockProvider;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    syncService = SyncService(db);
    mockProvider = MockSyncProvider();
    
    when(() => mockProvider.isConnected).thenReturn(true);
    when(() => mockProvider.connect()).thenAnswer((_) async => true);
    when(() => mockProvider.disconnect()).thenAnswer((_) async => {});
    when(() => mockProvider.supportsSyncAll).thenReturn(true);
    
    await syncService.setProvider(mockProvider);
  });

  tearDown(() async {
    await db.close();
  });

  test('Sync upload local changes', () async {
    final now = DateTime.now();
    await db.into(db.folders).insert(FoldersCompanion.insert(
      id: 'f1',
      name: 'Folder 1',
      color: 0xFF000000,
      createdAt: now,
      updatedAt: now,
    ));
    
    await db.into(db.notes).insert(NotesCompanion.insert(
      id: 'n1',
      title: const Value('Note 1'),
      folderId: 'f1',
      createdAt: now,
      updatedAt: now,
    ));

    when(() => mockProvider.syncAll(
      lastSyncTimestamp: any(named: 'lastSyncTimestamp'),
      localChanges: any(named: 'localChanges'),
    )).thenAnswer((invocation) async {
      return {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'changes': [],
      };
    });

    final result = await syncService.sync();
    
    expect(result.status, SyncStatus.success, reason: syncService.errorMessage);
  });

  test('Sync applies remote changes', () async {
    final remoteNoteId = 'remote-n1';
    final now = DateTime.now();
    
    when(() => mockProvider.syncAll(
      lastSyncTimestamp: any(named: 'lastSyncTimestamp'),
      localChanges: any(named: 'localChanges'),
    )).thenAnswer((_) async {
      return {
        'timestamp': now.millisecondsSinceEpoch,
        'changes': [
          {
            'id': remoteNoteId,
            'type': 'note',
            'deleted': false,
            'data': jsonEncode({
              'id': remoteNoteId,
              'title': 'Remote Note',
              'content': 'Hello from server',
              'contentType': 'text',
              'folderId': 'default',
              'isPinned': false,
              'isArchived': false,
              'isTrashed': false,
              'createdAt': now.millisecondsSinceEpoch,
              'updatedAt': now.millisecondsSinceEpoch,
              // 'syncedAt' und 'remoteId' könnten auch erwartet werden
              'syncedAt': null,
              'syncStatus': 'synced',
              'remoteId': remoteNoteId,
            }),
          }
        ],
      };
    });

    final result = await syncService.sync();
    expect(result.status, SyncStatus.success, reason: syncService.errorMessage);
    
    final note = await db.syncDao.getNoteById(remoteNoteId);
    expect(note, isNotNull);
    expect(note!.title, 'Remote Note');
  });

  test('triggerSync debounces multiple calls', () async {
    when(() => mockProvider.syncAll(
      lastSyncTimestamp: any(named: 'lastSyncTimestamp'),
      localChanges: any(named: 'localChanges'),
    )).thenAnswer((_) async {
      return {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'changes': [],
      };
    });

    // Mehrmals triggern
    syncService.triggerSync();
    syncService.triggerSync();
    syncService.triggerSync();

    // Kurz warten (weniger als Debounce-Zeit von 3s)
    await Future.delayed(const Duration(milliseconds: 500));
    verifyNever(() => mockProvider.syncAll(
      lastSyncTimestamp: any(named: 'lastSyncTimestamp'),
      localChanges: any(named: 'localChanges'),
    ));

    // Länger warten (mehr als 3s)
    await Future.delayed(const Duration(milliseconds: 3000));
    verify(() => mockProvider.syncAll(
      lastSyncTimestamp: any(named: 'lastSyncTimestamp'),
      localChanges: any(named: 'localChanges'),
    )).called(1);
  });
}
