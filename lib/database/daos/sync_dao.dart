import 'dart:convert';

import 'package:drift/drift.dart';

import '../database.dart';

part 'sync_dao.g.dart';

/// DAO für Sync-bezogene Datenbankoperationen
@DriftAccessor(tables: [Notes, SyncQueue, SyncConflicts])
class SyncDao extends DatabaseAccessor<AppDatabase> with _$SyncDaoMixin {
  SyncDao(super.db);

  // ==================== Sync Queue ====================

  /// Alle ausstehenden Sync-Einträge abrufen
  Future<List<SyncQueueData>> getPendingChanges() {
    return (select(syncQueue)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
  }

  /// Stream aller ausstehenden Sync-Einträge
  Stream<List<SyncQueueData>> watchPendingChanges() {
    return (select(syncQueue)..orderBy([(t) => OrderingTerm.asc(t.id)])).watch();
  }

  /// Anzahl der ausstehenden Änderungen
  Future<int> getPendingChangesCount() async {
    final count = countAll();
    final query = selectOnly(syncQueue)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Änderung zur Queue hinzufügen
  Future<int> queueChange({
    required String noteId,
    required String changeType,
    Note? note,
  }) {
    return into(syncQueue).insert(
      SyncQueueCompanion.insert(
        noteId: noteId,
        changeType: changeType,
        timestamp: DateTime.now(),
        noteData: note != null ? Value(_noteToJson(note)) : const Value.absent(),
      ),
    );
  }

  /// Änderung aus Queue entfernen
  Future<int> removeFromQueue(int id) {
    return (delete(syncQueue)..where((t) => t.id.equals(id))).go();
  }

  /// Alle Änderungen für eine Notiz aus Queue entfernen
  Future<int> removeNoteFromQueue(String noteId) {
    return (delete(syncQueue)..where((t) => t.noteId.equals(noteId))).go();
  }

  /// Queue leeren
  Future<int> clearQueue() {
    return delete(syncQueue).go();
  }

  /// Retry-Count erhöhen
  Future<bool> incrementRetryCount(int id, String? error) async {
    final updated = await (update(syncQueue)..where((t) => t.id.equals(id))).write(
      SyncQueueCompanion(
        retryCount: syncQueue.retryCount + const Constant(1),
        lastError: Value(error),
      ),
    );
    return updated > 0;
  }

  // ==================== Sync Status ====================

  /// Notizen mit Sync-Status "pending" abrufen
  Future<List<Note>> getUnsyncedNotes() {
    return (select(notes)
          ..where((t) => t.syncStatus.equals('pending'))
          ..orderBy([(t) => OrderingTerm.asc(t.updatedAt)]))
        .get();
  }

  /// Notizen die seit einem bestimmten Zeitpunkt geändert wurden
  Future<List<Note>> getNotesModifiedSince(DateTime since) {
    return (select(notes)..where((t) => t.updatedAt.isBiggerThanValue(since))).get();
  }

  /// Sync-Status einer Notiz aktualisieren
  Future<bool> updateSyncStatus(
    String noteId, {
    required String status,
    DateTime? syncedAt,
    String? remoteId,
  }) async {
    final updated = await (update(notes)..where((t) => t.id.equals(noteId))).write(
      NotesCompanion(
        syncStatus: Value(status),
        syncedAt: syncedAt != null ? Value(syncedAt) : const Value.absent(),
        remoteId: remoteId != null ? Value(remoteId) : const Value.absent(),
      ),
    );
    return updated > 0;
  }

  /// Mehrere Notizen als synchronisiert markieren
  Future<void> markAsSynced(List<String> noteIds, DateTime syncedAt) async {
    await batch((batch) {
      for (final noteId in noteIds) {
        batch.update(
          notes,
          NotesCompanion(
            syncStatus: const Value('synced'),
            syncedAt: Value(syncedAt),
          ),
          where: (t) => t.id.equals(noteId),
        );
      }
    });
  }

  /// Alle Notizen auf "pending" setzen (z.B. nach Reconnect)
  Future<int> resetAllSyncStatus() {
    return (update(notes)).write(
      const NotesCompanion(
        syncStatus: Value('pending'),
      ),
    );
  }

  // ==================== Konflikte ====================

  /// Alle ungelösten Konflikte abrufen
  Future<List<SyncConflict>> getUnresolvedConflicts() {
    return (select(syncConflicts)
          ..where((t) => t.resolved.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.detectedAt)]))
        .get();
  }

  /// Stream der ungelösten Konflikte
  Stream<List<SyncConflict>> watchUnresolvedConflicts() {
    return (select(syncConflicts)
          ..where((t) => t.resolved.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.detectedAt)]))
        .watch();
  }

  /// Anzahl der ungelösten Konflikte
  Future<int> getConflictCount() async {
    final count = countAll();
    final query = selectOnly(syncConflicts)
      ..where(syncConflicts.resolved.equals(false))
      ..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Konflikt speichern
  Future<int> saveConflict({
    required String id,
    required String noteId,
    required Note localNote,
    required Note remoteNote,
    required DateTime localModified,
    required DateTime remoteModified,
  }) {
    return into(syncConflicts).insert(
      SyncConflictsCompanion.insert(
        id: id,
        noteId: noteId,
        localData: _noteToJson(localNote),
        remoteData: _noteToJson(remoteNote),
        localModified: localModified,
        remoteModified: remoteModified,
        detectedAt: DateTime.now(),
      ),
    );
  }

  /// Konflikt als gelöst markieren
  Future<bool> resolveConflict(String id) async {
    final updated = await (update(syncConflicts)..where((t) => t.id.equals(id))).write(
      const SyncConflictsCompanion(
        resolved: Value(true),
      ),
    );
    return updated > 0;
  }

  /// Gelöste Konflikte löschen
  Future<int> deleteResolvedConflicts() {
    return (delete(syncConflicts)..where((t) => t.resolved.equals(true))).go();
  }

  /// Alle Konflikte für eine Notiz löschen
  Future<int> deleteConflictsForNote(String noteId) {
    return (delete(syncConflicts)..where((t) => t.noteId.equals(noteId))).go();
  }

  // ==================== Hilfsmethoden ====================

  /// Notiz zu JSON konvertieren
  String _noteToJson(Note note) {
    return jsonEncode({
      'id': note.id,
      'title': note.title,
      'content': note.content,
      'contentType': note.contentType,
      'folderId': note.folderId,
      'isPinned': note.isPinned,
      'isArchived': note.isArchived,
      'isTrashed': note.isTrashed,
      'trashedAt': note.trashedAt?.toIso8601String(),
      'mediaPath': note.mediaPath,
      'drawingData': note.drawingData,
      'createdAt': note.createdAt.toIso8601String(),
      'updatedAt': note.updatedAt.toIso8601String(),
    });
  }

  /// JSON zu Notiz-Map konvertieren (für Provider-Nutzung)
  static Map<String, dynamic> jsonToNoteMap(String json) {
    return jsonDecode(json) as Map<String, dynamic>;
  }
}
