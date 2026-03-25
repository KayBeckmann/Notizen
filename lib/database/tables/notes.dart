import 'package:drift/drift.dart';

import 'folders.dart';

/// Drift Table für Notizen
class Notes extends Table {
  /// Eindeutige ID (UUID)
  TextColumn get id => text()();

  /// Titel der Notiz
  TextColumn get title => text().withDefault(const Constant(''))();

  /// Markdown-Inhalt
  TextColumn get content => text().withDefault(const Constant(''))();

  /// Inhaltstyp (text, audio, image, drawing)
  TextColumn get contentType => text().withDefault(const Constant('text'))();

  /// Ordner-Referenz (Foreign Key)
  TextColumn get folderId => text().references(Folders, #id)();

  /// Ist angepinnt
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();

  /// Ist archiviert
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  /// Ist im Papierkorb
  BoolColumn get isTrashed => boolean().withDefault(const Constant(false))();

  /// Zeitpunkt des Löschens (für automatische Bereinigung)
  DateTimeColumn get trashedAt => dateTime().nullable()();

  /// Pfad zur Mediendatei (für Audio/Bild)
  TextColumn get mediaPath => text().nullable()();

  /// JSON-Daten für Zeichnung
  TextColumn get drawingData => text().nullable()();

  /// Erstellungsdatum
  DateTimeColumn get createdAt => dateTime()();

  /// Änderungsdatum
  DateTimeColumn get updatedAt => dateTime()();

  /// Letzter Sync-Zeitpunkt
  DateTimeColumn get syncedAt => dateTime().nullable()();

  /// Sync-Status: synced, pending, conflict
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  /// Remote-ID auf dem Server (kann von lokaler ID abweichen)
  TextColumn get remoteId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
