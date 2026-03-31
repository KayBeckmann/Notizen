import 'dart:convert';
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/sync_queue.dart';
import '../tables/notes.dart';
import '../tables/folders.dart';
import '../tables/tags.dart';

part 'sync_dao.g.dart';

@DriftAccessor(tables: [SyncQueue, SyncConflicts, Notes, Folders, Tags])
class SyncDao extends DatabaseAccessor<AppDatabase> with _$SyncDaoMixin {
  SyncDao(AppDatabase db) : super(db);

  /// Fügt eine Änderung zur Queue hinzu
  Future<int> addToQueue({
    required String noteId,
    required String changeType,
    Map<String, dynamic>? noteData,
  }) async {
    return into(syncQueue).insert(
      SyncQueueCompanion.insert(
        noteId: noteId,
        changeType: changeType,
        timestamp: DateTime.now(),
        noteData: noteData != null ? Value(jsonEncode(noteData)) : const Value.absent(),
      ),
    );
  }

  /// Holt alle ausstehenden Änderungen
  Future<List<SyncQueueData>> getPendingChanges() {
    return (select(syncQueue)..orderBy([(t) => OrderingTerm(expression: t.id, mode: OrderingMode.asc)])).get();
  }

  /// Entfernt eine Änderung aus der Queue
  Future<int> removeFromQueue(int id) {
    return (delete(syncQueue)..where((t) => t.id.equals(id))).go();
  }

  /// Leert die Queue
  Future<int> clearQueue() {
    return delete(syncQueue).go();
  }

  /// Fehler für eine Änderung aktualisieren
  Future<void> updateError(int id, String error) {
    return (update(syncQueue)..where((t) => t.id.equals(id))).write(
      SyncQueueCompanion(
        lastError: Value(error),
        retryCount: Value((select(syncQueue)..where((t) => t.id.equals(id))).getSingle().then((v) => v.retryCount + 1) as int? ?? 0),
      ),
    );
  }

  /// Einen Konflikt speichern
  Future<int> addConflict({
    required String noteId,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> remoteData,
    required DateTime localModified,
    required DateTime remoteModified,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    return into(syncConflicts).insert(
      SyncConflictsCompanion.insert(
        id: id,
        noteId: noteId,
        localData: jsonEncode(localData),
        remoteData: jsonEncode(remoteData),
        localModified: localModified,
        remoteModified: remoteModified,
        detectedAt: DateTime.now(),
      ),
    );
  }

  /// Holt alle ungelösten Konflikte
  Future<List<SyncConflict>> getUnresolvedConflicts() {
    return (select(syncConflicts)..where((t) => t.resolved.equals(false))).get();
  }

  /// Markiert einen Konflikt als gelöst
  Future<void> resolveConflict(String conflictId) {
    return (update(syncConflicts)..where((t) => t.id.equals(conflictId))).write(
      const SyncConflictsCompanion(resolved: Value(true)),
    );
  }

  /// Alle Tabellen für den Sync abrufen (für Delta-Sync)
  /// Da die Sync-Logik generisch ist, brauchen wir Zugriff auf alle Entitäten
  
  Future<Note?> getNoteById(String id) {
    return (select(notes)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<Folder?> getFolderById(String id) {
    return (select(folders)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<Tag?> getTagById(String id) {
    return (select(tags)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Hilfsmethode: Alles was seit dem letzten Sync geändert wurde
  Future<List<Note>> getModifiedNotesSince(DateTime? lastSync) {
    if (lastSync == null) return select(notes).get();
    return (select(notes)..where((t) => t.updatedAt.isBiggerThanValue(lastSync))).get();
  }

  Future<List<Folder>> getModifiedFoldersSince(DateTime? lastSync) {
    if (lastSync == null) return select(folders).get();
    return (select(folders)..where((t) => t.updatedAt.isBiggerThanValue(lastSync))).get();
  }

  Future<List<Tag>> getModifiedTagsSince(DateTime? lastSync) {
    if (lastSync == null) return select(tags).get();
    return (select(tags)..where((t) => t.createdAt.isBiggerThanValue(lastSync))).get();
  }
}
