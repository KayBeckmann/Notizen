import 'package:drift/drift.dart';

/// Drift Table für Tags
class Tags extends Table {
  /// Eindeutige ID (UUID)
  TextColumn get id => text()();

  /// Name des Tags (unique)
  TextColumn get name => text().withLength(min: 1, max: 100).unique()();

  /// Farbe als Hex-Integer
  IntColumn get color => integer()();

  /// Erstellungsdatum
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
