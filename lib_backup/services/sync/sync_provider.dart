import '../../database/database.dart';

/// Status einer Sync-Operation
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  conflict,
}

/// Ergebnis einer Sync-Operation
class SyncResult {
  final SyncStatus status;
  final int uploadedCount;
  final int downloadedCount;
  final int conflictCount;
  final String? errorMessage;
  final List<SyncConflictInfo> conflicts;
  final DateTime timestamp;

  SyncResult({
    required this.status,
    this.uploadedCount = 0,
    this.downloadedCount = 0,
    this.conflictCount = 0,
    this.errorMessage,
    this.conflicts = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory SyncResult.success({
    int uploadedCount = 0,
    int downloadedCount = 0,
  }) {
    return SyncResult(
      status: SyncStatus.success,
      uploadedCount: uploadedCount,
      downloadedCount: downloadedCount,
    );
  }

  factory SyncResult.error(String message) {
    return SyncResult(
      status: SyncStatus.error,
      errorMessage: message,
    );
  }

  factory SyncResult.conflict(List<SyncConflictInfo> conflicts) {
    return SyncResult(
      status: SyncStatus.conflict,
      conflictCount: conflicts.length,
      conflicts: conflicts,
    );
  }
}

/// Ein Sync-Konflikt zwischen lokaler und remote Version
class SyncConflictInfo {
  final String noteId;
  final Note localNote;
  final Note remoteNote;
  final DateTime localModified;
  final DateTime remoteModified;

  SyncConflictInfo({
    required this.noteId,
    required this.localNote,
    required this.remoteNote,
    required this.localModified,
    required this.remoteModified,
  });
}

/// Auflösung eines Konflikts
enum ConflictResolution {
  keepLocal,
  keepRemote,
  keepBoth,
}

/// Änderung die synchronisiert werden muss
class SyncChange {
  final String noteId;
  final SyncChangeType type;
  final DateTime timestamp;
  final Note? note;

  SyncChange({
    required this.noteId,
    required this.type,
    required this.timestamp,
    this.note,
  });
}

enum SyncChangeType {
  created,
  updated,
  deleted,
}

/// Abstraktes Interface für Sync-Provider
abstract class SyncProvider {
  /// Name des Providers (z.B. "Google Drive", "Nextcloud")
  String get name;

  /// Ob der Provider aktuell verbunden ist
  bool get isConnected;

  /// Letzter erfolgreicher Sync-Zeitpunkt
  DateTime? get lastSyncTime;

  /// Verbindung zum Cloud-Dienst herstellen
  Future<bool> connect();

  /// Verbindung trennen
  Future<void> disconnect();

  /// Verbindung testen
  Future<bool> testConnection();

  /// Vollständige Synchronisation durchführen
  Future<SyncResult> sync();

  /// Einzelne Notiz hochladen
  Future<bool> uploadNote(Note note);

  /// Einzelne Notiz herunterladen
  Future<Note?> downloadNote(String noteId);

  /// Notiz auf dem Server löschen
  Future<bool> deleteNote(String noteId);

  /// Alle Änderungen seit letztem Sync abrufen
  Future<List<SyncChange>> getRemoteChanges(DateTime since);

  /// Mediendatei hochladen (Audio, Bild)
  Future<String?> uploadMedia(String localPath, String mediaType);

  /// Mediendatei herunterladen
  Future<String?> downloadMedia(String remoteId, String localPath);

  /// Konflikt auflösen
  Future<bool> resolveConflict(SyncConflictInfo conflict, ConflictResolution resolution);
}
