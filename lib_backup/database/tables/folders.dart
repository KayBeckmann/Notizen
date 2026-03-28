import 'package:drift/drift.dart';

/// Drift Table für Ordner
class Folders extends Table {
  /// Eindeutige ID (UUID)
  TextColumn get id => text()();

  /// Name des Ordners
  TextColumn get name => text().withLength(min: 1, max: 255)();

  /// Farbe als Hex-Integer
  IntColumn get color => integer()();

  /// Icon-Name (Material Icon)
  TextColumn get icon => text().withDefault(const Constant('folder'))();

  /// Parent-ID für Verschachtelung (nullable, selbstreferenzierend)
  TextColumn get parentId =>
      text().nullable().references(Folders, #id, onDelete: KeyAction.cascade)();

  /// Position für Sortierung innerhalb des Parent-Ordners
  IntColumn get position => integer().withDefault(const Constant(0))();

  /// Erstellungsdatum
  DateTimeColumn get createdAt => dateTime()();

  /// Änderungsdatum
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>>? get uniqueKeys => [
        {parentId, name},
      ];
}
