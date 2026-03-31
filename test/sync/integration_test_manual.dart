import 'dart:convert';
import 'package:test/test.dart'; // Benutze das normale test Package statt flutter_test
import 'package:drift/native.dart';
import 'package:notizen/database/database.dart';
import 'package:notizen/services/sync/sync_service.dart';
import 'package:notizen/services/sync/sync_provider.dart';
import 'package:notizen/services/sync/rest_api_provider.dart';

void main() {
  // Dieser Test benötigt das laufende Docker-Backend
  // Ausführen mit: dart test test/sync/integration_test_manual.dart
  
  late AppDatabase db;
  late SyncService syncService;
  late RestApiSyncProvider provider;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    syncService = SyncService(db);
    provider = RestApiSyncProvider();
    
    await provider.configure(
      serverUrl: 'http://127.0.0.1:3000',
      apiKey: 'uvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
    );
    
    await syncService.setProvider(provider);
  });

  tearDown(() async {
    await db.close();
  });

  test('Integration: Connect and Sync with local backend', () async {
    final connected = await syncService.connect();
    expect(connected, isTrue, reason: 'Verbindung zum Backend fehlgeschlagen. Läuft Docker?');

    // 1. Lokale Notiz erstellen
    final now = DateTime.now();
    final noteId = 'int-test-${now.millisecondsSinceEpoch}';
    await db.into(db.notes).insert(NotesCompanion.insert(
      id: noteId,
      title: const Value('Integration Test Note'),
      folderId: 'default',
      createdAt: now,
      updatedAt: now,
    ));

    // 2. Sync
    final result = await syncService.sync();
    expect(result.status, SyncStatus.success, reason: syncService.errorMessage);

    // 3. Überprüfen ob es auf dem Server angekommen ist
    // Wir erstellen eine neue DB-Instanz um einen sauberen Download zu simulieren
    final db2 = AppDatabase.forTesting(NativeDatabase.memory());
    final sync2 = SyncService(db2);
    final provider2 = RestApiSyncProvider();
    await provider2.configure(
      serverUrl: 'http://127.0.0.1:3000',
      apiKey: 'uvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
    );
    await sync2.setProvider(provider2);
    await sync2.connect();
    
    await sync2.sync();
    
    final note = await db2.syncDao.getNoteById(noteId);
    expect(note, isNotNull, reason: 'Notiz wurde nicht vom Server heruntergeladen');
    expect(note!.title, 'Integration Test Note');
    
    await db2.close();
  });
}
