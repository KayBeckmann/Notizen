import 'package:drift/drift.dart';
import 'notes.dart';
import 'tags.dart';

class NoteTags extends Table {
  TextColumn get noteId => text().references(Notes, #id, onDelete: OperationIterable.cascade)();
  TextColumn get tagId => text().references(Tags, #id, onDelete: OperationIterable.cascade)();

  @override
  Set<Column> get primaryKey => {noteId, tagId};
}
