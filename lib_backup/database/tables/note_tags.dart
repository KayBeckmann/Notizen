import 'package:drift/drift.dart';

import 'notes.dart';
import 'tags.dart';

/// Drift Table für Notiz-Tag Verknüpfungen (Many-to-Many)
class NoteTags extends Table {
  /// Notiz-ID (Foreign Key)
  TextColumn get noteId =>
      text().references(Notes, #id, onDelete: KeyAction.cascade)();

  /// Tag-ID (Foreign Key)
  TextColumn get tagId =>
      text().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {noteId, tagId};
}
