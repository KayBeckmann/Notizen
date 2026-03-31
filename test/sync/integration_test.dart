import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notizen/database/database.dart';
import 'package:notizen/services/sync/sync_service.dart';
import 'package:notizen/services/sync/sync_provider.dart';
import 'package:notizen/services/sync/rest_api_provider.dart';

void main() {
  // Dieser Test benötigt das laufende Docker-Backend
  // Ausführen mit: flutter test test/sync/integration_test.dart
  
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  
  late AppDatabase db;
  late SyncService syncService;
  late RestApiSyncProvider provider;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    syncService = SyncService(db);
    provider = RestApiSyncProvider();
    
    // Konfiguration für das lokale Docker-Backend
    // Im Docker-Netzwerk ist das Backend unter 'notizen-backend' erreichbar,
    // aber vom Host aus unter 'localhost' oder '127.0.0.1'.
    await provider.configure(
      serverUrl: 'http://127.0.0.1:3000',
      apiKey: 'uvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', // Der vorhin erstellte Key
    );
    
    await syncService.setProvider(provider);
  });

  tearDown(() async {
    await db.close();
  });

  test('Integration: Connect and Sync with local backend', () async {
    try {
      final response = await provider.testConnection();
      expect(response, isTrue, reason: 'testConnection failed. Backend might be down at 127.0.0.1:3000');
    } catch (e) {
      fail('testConnection threw exception: $e');
    }

    final connected = await syncService.connect();
    if (!connected) {
      print('Integrationstest übersprungen: Backend nicht erreichbar. Error: ${syncService.errorMessage}');
      return;
    }

    // 1. Lokale Notiz erstellen
    final now = DateTime.now();
    final noteId = 'int-test-1';
    await db.into(db.notes).insert(NotesCompanion.insert(
      id: noteId,
      title: const Value('Integration Test Note'),
      folderId: 'default',
      createdAt: now,
      updatedAt: now,
    ));

    // 2. Sync
    final result = await syncService.sync();
    expect(result.status, SyncStatus.success);

    // 3. Datenbank leeren und erneut syncen (um Download zu testen)
    await db.delete(db.notes).go();
    final notesBefore = await db.syncDao.getNoteById(noteId);
    expect(notesBefore, isNull);

    // Letzten Sync-Zeitpunkt zurücksetzen um alles zu laden
    // (In der Realität würde man das über ein neues Gerät simulieren)
    // Wir löschen einfach den lokalen Zeitstempel im Service
    // syncService.resetLastSyncTime(); // Müsste implementiert werden
    
    // Für den Test löschen wir einfach SharedPreferences und erstellen den Service neu
    SharedPreferences.setMockInitialValues({});
    syncService = SyncService(db);
    await syncService.setProvider(provider);
    await syncService.connect();
    
    await syncService.sync();
    
    final notesAfter = await db.syncDao.getNoteById(noteId);
    expect(notesAfter, isNotNull);
    expect(notesAfter!.title, 'Integration Test Note');
  }, tags: 'integration');
}
