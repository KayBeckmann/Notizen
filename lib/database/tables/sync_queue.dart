import 'package:drift/drift.dart';

/// Drift Table für die Sync-Queue
/// Speichert ausstehende Änderungen für die Offline-Synchronisation
class SyncQueue extends Table {
  /// Auto-increment ID für Reihenfolge
  IntColumn get id => integer().autoIncrement()();

  /// ID der betroffenen Notiz
  TextColumn get noteId => text()();

  /// Art der Änderung: created, updated, deleted
  TextColumn get changeType => text()();

  /// Zeitpunkt der Änderung
  DateTimeColumn get timestamp => dateTime()();

  /// Snapshot der Notiz-Daten als JSON (für create/update)
  TextColumn get noteData => text().nullable()();

  /// Anzahl der Sync-Versuche
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// Letzter Fehler
  TextColumn get lastError => text().nullable()();
}

/// Drift Table für Sync-Konflikte
class SyncConflicts extends Table {
  /// ID des Konflikts
  TextColumn get id => text()();

  /// ID der betroffenen Notiz
  TextColumn get noteId => text()();

  /// Lokale Version als JSON
  TextColumn get localData => text()();

  /// Remote Version als JSON
  TextColumn get remoteData => text()();

  /// Lokaler Änderungszeitpunkt
  DateTimeColumn get localModified => dateTime()();

  /// Remote Änderungszeitpunkt
  DateTimeColumn get remoteModified => dateTime()();

  /// Zeitpunkt der Konflikt-Erkennung
  DateTimeColumn get detectedAt => dateTime()();

  /// Ob der Konflikt bereits gelöst wurde
  BoolColumn get resolved => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
