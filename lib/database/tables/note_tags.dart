import 'package:drift/drift.dart';

import 'notes.dart';
import 'tags.dart';

/// Drift Table für Notiz-Tag Verknüpfungen (Many-to-Many)
class NoteTags extends Table {
  /// Notiz-ID (Foreign Key)
  TextColumn get noteId => text().references(Notes, #id)();

  /// Tag-ID (Foreign Key)
  TextColumn get tagId => text().references(Tags, #id)();

  @override
  Set<Column> get primaryKey => {noteId, tagId};
}
