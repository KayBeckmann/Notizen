import 'package:drift/drift.dart';

/// Tabelle für Notiz-Vorlagen
class Templates extends Table {
  /// Eindeutige ID (UUID)
  TextColumn get id => text()();

  /// Name der Vorlage
  TextColumn get name => text()();

  /// Titel-Vorlage
  TextColumn get titleTemplate => text().withDefault(const Constant(''))();

  /// Inhalt-Vorlage (Markdown)
  TextColumn get content => text().withDefault(const Constant(''))();

  /// Notiz-Typ (text, audio, image, drawing)
  TextColumn get contentType =>
      text().withDefault(const Constant('text'))();

  /// Icon für die Vorlage
  TextColumn get icon =>
      text().withDefault(const Constant('description'))();

  /// Farbe für die Vorlage
  IntColumn get color => integer().withDefault(const Constant(0xFF6750A4))();

  /// Erstellungsdatum
  DateTimeColumn get createdAt => dateTime()();

  /// Letztes Update
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
